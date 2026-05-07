import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/crypto/vault_crypto.dart';
import '../../../shared/network/api_error.dart';
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
    this.folderFilter,
    this.search = '',
  });

  final List<VaultItem> items;
  final bool isLoading;
  final bool isPaging;
  final String? errorMessage;
  final String? cursor;
  final bool hasMore;
  final VaultItemType? typeFilter;
  // null → all folders. The literal `'none'` filters to uncategorized; any
  // other string is a specific folder id.
  final String? folderFilter;
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
    Object? folderFilter = _sentinel,
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
      folderFilter: identical(folderFilter, _sentinel)
          ? this.folderFilter
          : folderFilter as String?,
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

  /// `null` clears the folder filter (all items). `'none'` shows uncategorized.
  /// Any other string filters to a specific folder id.
  Future<void> setFolderFilter(String? folderId) async {
    if (state.folderFilter == folderId) return;
    state = state.copyWith(folderFilter: folderId);
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
      final page = await VaultRepository.instance.list(
        type: state.typeFilter,
        folderId: state.folderFilter,
      );
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
        folderId: state.folderFilter,
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
  /// The body is encrypted with a fresh random per-file DEK so master-password
  /// rotation only has to re-wrap metadata — bodies stay decryptable. The DEK
  /// itself sits inside the master-encrypted metadata blob.
  Future<VaultItem> uploadFile({
    required VaultItemType type,
    required String title,
    required Uint8List bytes,
    required String mime,
    required String originalFilename,
    String? iconKey,
    void Function(double progress)? onProgress,
  }) async {
    final fileKey = VaultCrypto.randomBytes(32);
    final fileEncrypted = await VaultCrypto.encrypt(fileKey, bytes);
    final ciphertext = fileEncrypted.ciphertext;

    final encryptedMeta = await VaultCrypto.encryptJson(_key, {
      'filename': originalFilename,
      'mime': mime,
      'fileIv': base64Encode(fileEncrypted.iv),
      'fileKey': base64Encode(fileKey),
      'iconKey': ?iconKey,
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

    try {
      await repo.uploadCiphertext(
        itemId: initiate.itemId,
        chunkSize: initiate.chunkSize,
        ciphertext: ciphertext,
        onProgress: (sent, total) {
          if (onProgress != null && total > 0) onProgress(sent / total);
        },
      );

      final finalized = await repo.finalizeUpload(initiate.itemId);
      _upsertLocal(finalized);
      return finalized;
    } catch (e) {
      await repo.abortUpload(initiate.itemId).catchError((_) {});
      rethrow;
    }
  }

  /// Re-encrypts the file's metadata blob (filename + iconKey) and updates the
  /// title — without re-uploading any of the (large) ciphertext bytes. The
  /// fileIv is preserved so existing ciphertext remains decryptable.
  Future<VaultItem> updateFileMeta({
    required VaultItem item,
    required String title,
    String? iconKey,
  }) async {
    final repo = VaultRepository.instance;
    // Re-decrypt only the meta blob to recover filename/mime/fileIv, then
    // re-seal with the same per-asset IV intact.
    final meta = await VaultCrypto.decryptJson(
      masterKey: _key,
      cipherBlob: item.cipherBlob,
      cipherIv: item.cipherIv,
    );
    final encryptedMeta = await VaultCrypto.encryptJson(_key, {
      'filename': meta['filename'] ?? title,
      'mime': meta['mime'] ?? 'application/octet-stream',
      'fileIv': meta['fileIv'],
      // Preserve per-file DEK across metadata edits. Legacy items (uploaded
      // before per-file DEKs) won't have one — the body is master-encrypted.
      if (meta['fileKey'] != null) 'fileKey': meta['fileKey'],
      'iconKey': ?iconKey,
    });
    final updated = await repo.update(
      item.id,
      title: title,
      cipherBlob: encryptedMeta.cipherBlob,
      cipherIv: encryptedMeta.cipherIv,
    );
    _upsertLocal(updated);
    return updated;
  }

  Future<
    ({
      Uint8List bytes,
      String filename,
      String mime,
      String? iconKey,
      String fileIvBase64,
      // null for legacy items whose bodies are encrypted with the master key.
      String? fileKeyBase64,
    })
  >
  downloadFile(VaultItem item) async {
    final repo = VaultRepository.instance;
    final meta = await VaultCrypto.decryptJson(
      masterKey: _key,
      cipherBlob: item.cipherBlob,
      cipherIv: item.cipherIv,
    );
    final fileIv = base64Decode(meta['fileIv'] as String);
    final fileKeyB64 = meta['fileKey'] as String?;
    final bodyKey = fileKeyB64 != null ? base64Decode(fileKeyB64) : _key;
    final ciphertext = await repo.downloadCiphertext(item.id);
    final plain = await VaultCrypto.decrypt(
      masterKey: bodyKey,
      ciphertext: ciphertext,
      iv: fileIv,
    );
    return (
      bytes: plain,
      filename: meta['filename'] as String? ?? 'file',
      mime: meta['mime'] as String? ?? 'application/octet-stream',
      iconKey: meta['iconKey'] as String?,
      fileIvBase64: meta['fileIv'] as String,
      fileKeyBase64: fileKeyB64,
    );
  }

  /// Reads the metadata blob of an existing file/image item (no body fetch).
  /// Used when sharing — we need fileKey/fileIv but not the plaintext body.
  Future<Map<String, dynamic>> readFileMeta(VaultItem item) {
    return VaultCrypto.decryptJson(
      masterKey: _key,
      cipherBlob: item.cipherBlob,
      cipherIv: item.cipherIv,
    );
  }


  Future<void> delete(VaultItem item) async {
    await VaultRepository.instance.delete(item.id);
    state = state.copyWith(
      items: state.items.where((i) => i.id != item.id).toList(),
    );
  }

  /// Moves an item to [folderId] (or pass null to uncategorize). The PATCH
  /// preserves cipherBlob/cipherIv — folders are pure organization, no re-seal.
  Future<VaultItem> moveToFolder(VaultItem item, String? folderId) async {
    final updated = await VaultRepository.instance.update(
      item.id,
      folderId: folderId,
    );
    _upsertLocal(updated);
    return updated;
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
  return friendlyApiError(e);
}

final vaultProvider = StateNotifierProvider<VaultNotifier, VaultListState>(
  (ref) => VaultNotifier(ref),
);
