import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/crypto/share_crypto.dart';
import '../../../shared/crypto/vault_crypto.dart';
import '../../../shared/network/api_error.dart';
import '../../auth/presentation/auth_notifier.dart';
import '../../vault/data/vault_models.dart';
import '../data/share_models.dart';
import '../data/share_repository.dart';

class ShareState {
  const ShareState({
    this.received = const [],
    this.sent = const [],
    this.isLoading = false,
    this.errorMessage,
  });
  final List<SharedItem> received;
  final List<SharedItem> sent;
  final bool isLoading;
  final String? errorMessage;

  ShareState copyWith({
    List<SharedItem>? received,
    List<SharedItem>? sent,
    bool? isLoading,
    Object? errorMessage = _sentinel,
  }) =>
      ShareState(
        received: received ?? this.received,
        sent: sent ?? this.sent,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: identical(errorMessage, _sentinel)
            ? this.errorMessage
            : errorMessage as String?,
      );
  static const _sentinel = Object();
}

class ShareNotifier extends StateNotifier<ShareState> {
  ShareNotifier(this._ref) : super(const ShareState());

  final Ref _ref;
  final _repo = ShareRepository.instance;

  /// Bootstraps the user's sharing keypair if one doesn't already exist on
  /// the server. Idempotent and safe to call after every unlock.
  Future<void> ensureKeypair() async {
    final masterKey = _ref.read(authProvider.notifier).masterKey;
    if (masterKey == null) return;
    try {
      final stored = await _repo.getKeypair();
      if (stored.isComplete) return;
    } catch (_) {
      // fall through to publish
    }
    final pair = await ShareCrypto.generateKeypair();
    final wrapped = await ShareCrypto.wrapPrivateKey(
      masterKey: masterKey,
      privateRawBase64: pair.privateRaw,
    );
    await _repo.publishKeypair(
      publicKey: pair.publicKey,
      privateCipher: wrapped.cipher,
      privateIv: wrapped.iv,
    );
  }

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final results = await Future.wait([_repo.received(), _repo.sent()]);
      state = state.copyWith(
        received: results[0],
        sent: results[1],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: friendlyApiError(e),
      );
    }
  }

  Future<void> shareWithEmail({
    required String email,
    required VaultItemType type,
    required String title,
    required Map<String, dynamic> payload,
    String permission = 'view',
    int? expiresInDays,
    // For file/image shares: the owner's source vault item id. The recipient
    // will pull the encrypted body via the share download endpoint and
    // decrypt with the per-file DEK that's inside `payload`.
    String? sourceItemId,
  }) async {
    final recipient = await _repo.lookup(email);
    final sealed = await ShareCrypto.sealForRecipient(
      recipientPublicKeyBase64: recipient.publicKey,
      payload: payload,
    );
    final created = await _repo.create(
      recipientEmail: recipient.email,
      type: type,
      title: title,
      cipherBlob: sealed.cipherBlob,
      cipherIv: sealed.cipherIv,
      wrappedKey: sealed.wrappedKey,
      permission: permission,
      expiresInDays: expiresInDays,
      sourceItemId: sourceItemId,
    );
    state = state.copyWith(sent: [created, ...state.sent]);
  }

  /// Recipient-only: fetches and decrypts the body of a shared file/image.
  /// `payload` is the already-decrypted share payload (so we have the
  /// per-file DEK). Falls back to legacy inlined `fileBase64` if present.
  Future<Uint8List> openSharedFileBytes({
    required SharedItem item,
    required Map<String, dynamic> payload,
  }) async {
    final inlineB64 = payload['fileBase64'] as String?;
    if (inlineB64 != null) {
      // Legacy share: body was inlined in the encrypted payload.
      return Uint8List.fromList(base64Decode(inlineB64));
    }
    final fileKeyB64 = payload['fileKey'] as String?;
    final fileIvB64 = payload['fileIv'] as String?;
    if (fileKeyB64 == null || fileIvB64 == null) {
      throw const FormatException(
        'Share payload missing fileKey/fileIv — cannot decrypt body.',
      );
    }
    final ciphertext = await _repo.downloadCiphertext(item.id);
    return VaultCrypto.decrypt(
      masterKey: Uint8List.fromList(base64Decode(fileKeyB64)),
      ciphertext: ciphertext,
      iv: Uint8List.fromList(base64Decode(fileIvB64)),
    );
  }

  Future<Map<String, dynamic>> openReceived(SharedItem item) async {
    final masterKey = _ref.read(authProvider.notifier).masterKey;
    if (masterKey == null) {
      throw StateError('Vault is locked.');
    }
    final stored = await _repo.getKeypair();
    if (!stored.isComplete) {
      throw StateError('Sharing is not yet set up on this account.');
    }
    final priv = await ShareCrypto.unwrapPrivateKey(
      masterKey: masterKey,
      cipherBase64: stored.privateCipher!,
      ivBase64: stored.privateIv!,
    );
    return ShareCrypto.openShare(
      recipientPrivateKey: Uint8List.fromList(priv),
      cipherBlobBase64: item.cipherBlob,
      cipherIvBase64: item.cipherIv,
      wrappedKeyBase64: item.wrappedKey,
    );
  }

  Future<void> revoke(SharedItem item) async {
    await _repo.revoke(item.id);
    state = state.copyWith(
      received: state.received.where((s) => s.id != item.id).toList(),
      sent: state.sent.where((s) => s.id != item.id).toList(),
    );
  }
}

final shareProvider =
    StateNotifierProvider<ShareNotifier, ShareState>(ShareNotifier.new);
