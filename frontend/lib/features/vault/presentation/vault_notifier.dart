import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/crypto/vault_crypto.dart';
import '../../auth/presentation/auth_notifier.dart';
import '../data/vault_models.dart';
import '../data/vault_repository.dart';

class VaultListState {
  const VaultListState({
    this.items = const [],
    this.isLoading = false,
    this.isPaging = false,
    this.errorMessage,
    this.cursor,
    this.hasMore = true,
    this.typeFilter,
    this.search = '',
  });

  final List<VaultItem> items;
  final bool isLoading;
  final bool isPaging;
  final String? errorMessage;
  final String? cursor;
  final bool hasMore;
  final VaultItemType? typeFilter;
  final String search;

  /// Title-only search (titles are plaintext metadata; payloads stay encrypted).
  List<VaultItem> get visibleItems {
    if (search.isEmpty) return items;
    final q = search.toLowerCase();
    return items.where((i) => i.title.toLowerCase().contains(q)).toList();
  }

  VaultListState copyWith({
    List<VaultItem>? items,
    bool? isLoading,
    bool? isPaging,
    Object? errorMessage = _sentinel,
    Object? cursor = _sentinel,
    bool? hasMore,
    Object? typeFilter = _sentinel,
    String? search,
  }) {
    return VaultListState(
      items: items ?? this.items,
      isLoading: isLoading ?? this.isLoading,
      isPaging: isPaging ?? this.isPaging,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
      cursor: identical(cursor, _sentinel) ? this.cursor : cursor as String?,
      hasMore: hasMore ?? this.hasMore,
      typeFilter: identical(typeFilter, _sentinel)
          ? this.typeFilter
          : typeFilter as VaultItemType?,
      search: search ?? this.search,
    );
  }

  static const _sentinel = Object();
}

class VaultNotifier extends StateNotifier<VaultListState> {
  VaultNotifier(this._ref) : super(const VaultListState());

  final Ref _ref;

  Uint8List get _key {
    final key = _ref.read(authProvider.notifier).masterKey;
    if (key == null) {
      throw StateError('Vault is locked');
    }
    return key;
  }

  Future<void> setTypeFilter(VaultItemType? type) async {
    if (state.typeFilter == type) return;
    state = state.copyWith(typeFilter: type);
    await refresh();
  }

  void setSearch(String q) {
    state = state.copyWith(search: q);
  }

  Future<void> refresh() async {
    state = state.copyWith(
      isLoading: true,
      errorMessage: null,
      cursor: null,
      hasMore: true,
      items: const [],
    );
    try {
      final page = await VaultRepository.instance.list(type: state.typeFilter);
      state = state.copyWith(
        items: page.items,
        cursor: page.nextCursor,
        hasMore: page.nextCursor != null,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: _err(e));
    }
  }

  Future<void> loadMore() async {
    if (state.isPaging || !state.hasMore || state.cursor == null) return;
    state = state.copyWith(isPaging: true);
    try {
      final page = await VaultRepository.instance.list(
        type: state.typeFilter,
        cursor: state.cursor,
      );
      state = state.copyWith(
        items: [...state.items, ...page.items],
        cursor: page.nextCursor,
        hasMore: page.nextCursor != null,
        isPaging: false,
      );
    } catch (e) {
      state = state.copyWith(isPaging: false, errorMessage: _err(e));
    }
  }

  Future<VaultItem> savePassword({
    String? id,
    required String title,
    required PasswordPayload payload,
  }) => _saveStructured(
    id: id,
    type: VaultItemType.password,
    title: title,
    payload: payload.toJson(),
  );

  Future<VaultItem> saveNote({
    String? id,
    required String title,
    required NotePayload payload,
  }) => _saveStructured(
    id: id,
    type: VaultItemType.note,
    title: title,
    payload: payload.toJson(),
  );

  Future<VaultItem> saveKey({
    String? id,
    required String title,
    required KeyPayload payload,
  }) => _saveStructured(
    id: id,
    type: VaultItemType.key,
    title: title,
    payload: payload.toJson(),
  );

  Future<VaultItem> _saveStructured({
    String? id,
    required VaultItemType type,
    required String title,
    required Map<String, dynamic> payload,
  }) async {
    final encrypted = await VaultCrypto.encryptJson(_key, payload);
    final repo = VaultRepository.instance;
    final saved = id == null
        ? await repo.create(
            type: type,
            title: title,
            cipherBlob: encrypted.cipherBlob,
            cipherIv: encrypted.cipherIv,
          )
        : await repo.update(
            id,
            title: title,
            cipherBlob: encrypted.cipherBlob,
            cipherIv: encrypted.cipherIv,
          );
    _upsertLocal(saved);
    return saved;
  }

  Future<Map<String, dynamic>> decrypt(VaultItem item) {
    return VaultCrypto.decryptJson(
      masterKey: _key,
      cipherBlob: item.cipherBlob,
      cipherIv: item.cipherIv,
    );
  }

  /// Encrypts file bytes locally, reserves quota, uploads ciphertext, finalizes.
  /// Metadata blob carries the file IV so we don't need a separate column.
  Future<VaultItem> uploadFile({
    required VaultItemType type,
    required String title,
    required Uint8List bytes,
    required String mime,
    required String originalFilename,
    void Function(double progress)? onProgress,
  }) async {
    final fileEncrypted = await VaultCrypto.encrypt(_key, bytes);
    final ciphertext = fileEncrypted.ciphertext;

    final encryptedMeta = await VaultCrypto.encryptJson(_key, {
      'filename': originalFilename,
      'mime': mime,
      'fileIv': base64Encode(fileEncrypted.iv),
    });

    final repo = VaultRepository.instance;
    final initiate = await repo.initiateUpload(
      type: type,
      title: title,
      cipherBlob: encryptedMeta.cipherBlob,
      cipherIv: encryptedMeta.cipherIv,
      fileSize: ciphertext.length,
      fileMime: mime,
    );

    await repo.uploadCiphertext(
      uploadUrl: initiate.uploadUrl,
      ciphertext: ciphertext,
      onProgress: (sent, total) {
        if (onProgress != null && total > 0) onProgress(sent / total);
      },
    );

    final finalized = await repo.finalizeUpload(initiate.itemId);
    _upsertLocal(finalized);
    return finalized;
  }

  Future<({Uint8List bytes, String filename, String mime})> downloadFile(
    VaultItem item,
  ) async {
    final repo = VaultRepository.instance;
    final meta = await VaultCrypto.decryptJson(
      masterKey: _key,
      cipherBlob: item.cipherBlob,
      cipherIv: item.cipherIv,
    );
    final fileIv = base64Decode(meta['fileIv'] as String);
    final url = await repo.downloadUrl(item.id);
    final ciphertext = await repo.downloadCiphertext(url);
    final plain = await VaultCrypto.decrypt(
      masterKey: _key,
      ciphertext: ciphertext,
      iv: fileIv,
    );
    return (
      bytes: plain,
      filename: meta['filename'] as String? ?? 'file',
      mime: meta['mime'] as String? ?? 'application/octet-stream',
    );
  }

  Future<void> delete(VaultItem item) async {
    await VaultRepository.instance.delete(item.id);
    state = state.copyWith(
      items: state.items.where((i) => i.id != item.id).toList(),
    );
  }

  void _upsertLocal(VaultItem item) {
    final idx = state.items.indexWhere((i) => i.id == item.id);
    final list = [...state.items];
    if (idx == -1) {
      list.insert(0, item);
    } else {
      list[idx] = item;
      // Move to top (latest updated).
      final updated = list.removeAt(idx);
      list.insert(0, updated);
    }
    state = state.copyWith(items: list);
  }
}

String _err(Object e) {
  final raw = e.toString();
  return raw.length > 240 ? raw.substring(0, 240) : raw;
}

final vaultProvider =
    StateNotifierProvider<VaultNotifier, VaultListState>((ref) => VaultNotifier(ref));
