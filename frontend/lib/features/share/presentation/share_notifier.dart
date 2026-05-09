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
    final payload = ShareCrypto.openShare(
      recipientPrivateKey: Uint8List.fromList(priv),
      cipherBlobBase64: item.cipherBlob,
      cipherIvBase64: item.cipherIv,
      wrappedKeyBase64: item.wrappedKey,
    );
    // Best-effort read receipt for non-file shares (file shares are auto-bumped
    // by the server when the recipient hits /:id/content). Failures here must
    // not turn a successful decrypt into an error for the recipient.
    if (item.type != VaultItemType.file && item.type != VaultItemType.image) {
      _repo.markOpened(item.id).catchError((_) {});
    }
    return payload;
  }

  Future<void> revoke(SharedItem item) async {
    await _repo.revoke(item.id);
    state = state.copyWith(
      received: state.received.where((s) => s.id != item.id).toList(),
      sent: state.sent.where((s) => s.id != item.id).toList(),
    );
  }

  /// Bundles N pre-decrypted item payloads into a folder-share. Each payload
  /// is sealed independently with a fresh per-share DEK + recipient-wrap, so
  /// any single child can be revoked without touching the others.
  ///
  /// `items` is the list of entries to seal — each tuple carries its plaintext
  /// payload (already extracted on the calling side, since only the caller can
  /// decrypt) plus optional file/image source pointers.
  Future<List<SharedItem>> shareFolder({
    required String email,
    required String folderName,
    required List<FolderShareEntry> items,
    String? sourceFolderId,
    String permission = 'view',
    int? expiresInDays,
  }) async {
    if (items.isEmpty) {
      throw ArgumentError('Cannot share an empty folder.');
    }
    final recipient = await _repo.lookup(email);
    final entries = <BundleEntry>[];
    for (final e in items) {
      final sealed = await ShareCrypto.sealForRecipient(
        recipientPublicKeyBase64: recipient.publicKey,
        payload: e.payload,
      );
      entries.add(BundleEntry(
        type: e.type,
        title: e.title,
        cipherBlob: sealed.cipherBlob,
        cipherIv: sealed.cipherIv,
        wrappedKey: sealed.wrappedKey,
        sourceItemId: e.sourceItemId,
      ));
    }
    final created = await _repo.createBundle(
      recipientEmail: recipient.email,
      name: folderName,
      items: entries,
      permission: permission,
      expiresInDays: expiresInDays,
      sourceFolderId: sourceFolderId,
    );
    state = state.copyWith(sent: [...created, ...state.sent]);
    return created;
  }

  Future<void> revokeBundle(String bundleId) async {
    await _repo.revokeBundle(bundleId);
    bool sameBundle(SharedItem s) => s.bundleId == bundleId;
    state = state.copyWith(
      received: state.received.where((s) => !sameBundle(s)).toList(),
      sent: state.sent.where((s) => !sameBundle(s)).toList(),
    );
  }
}

/// One entry the caller has already extracted from a vault item, ready to be
/// sealed by [ShareNotifier.shareFolder]. Sealing happens inside the notifier
/// so the recipient's public key never needs to leak to UI code.
class FolderShareEntry {
  const FolderShareEntry({
    required this.type,
    required this.title,
    required this.payload,
    this.sourceItemId,
  });
  final VaultItemType type;
  final String title;
  final Map<String, dynamic> payload;
  // Required for file/image entries: server uses this to authorize the
  // recipient's body fetch via /shares/:id/content.
  final String? sourceItemId;
}

final shareProvider =
    StateNotifierProvider<ShareNotifier, ShareState>(ShareNotifier.new);
