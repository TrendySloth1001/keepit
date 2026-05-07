import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../constants/api_constants.dart';
import '../../../shared/network/api_client.dart';
import 'vault_models.dart';

class ListPage {
  const ListPage({required this.items, required this.nextCursor});
  final List<VaultItem> items;
  final String? nextCursor;
}

class InitiateUploadResult {
  const InitiateUploadResult({required this.itemId, required this.chunkSize});
  final String itemId;
  final int chunkSize;
}

// Sentinel for the three-state folder-move param on `update`. `_kKeep` means
// "do not touch", null means "clear", a string means "link to this folder."
const Object _kKeep = Object();

class VaultRepository {
  VaultRepository._();
  static final instance = VaultRepository._();

  Dio get _dio => ApiClient.instance.dio;

  Future<ListPage> list({
    VaultItemType? type,
    String? cursor,
    int limit = 50,
    // null → no folder filter (show all). The literal `'none'` filters to
    // uncategorized (folderId IS NULL); any other string filters to that
    // folder id.
    String? folderId,
  }) async {
    final res = await _dio.get(
      ApiConstants.vaultItems,
      queryParameters: {
        if (type != null) 'type': type.name,
        if (cursor != null) 'cursor': cursor,
        'limit': limit,
        if (folderId != null) 'folderId': folderId,
      },
    );
    final data = Map<String, dynamic>.from(res.data['data'] as Map);
    final items = (data['items'] as List)
        .cast<Map>()
        .map((m) => VaultItem.fromJson(Map<String, dynamic>.from(m)))
        .toList();
    return ListPage(items: items, nextCursor: data['nextCursor'] as String?);
  }

  Future<VaultItem> create({
    required VaultItemType type,
    required String title,
    required String cipherBlob,
    required String cipherIv,
  }) async {
    final res = await _dio.post(
      ApiConstants.vaultItems,
      data: {
        'type': type.name,
        'title': title,
        'cipherBlob': cipherBlob,
        'cipherIv': cipherIv,
      },
    );
    return VaultItem.fromJson(
      Map<String, dynamic>.from(res.data['data'] as Map),
    );
  }

  Future<VaultItem> update(
    String id, {
    String? title,
    String? cipherBlob,
    String? cipherIv,
    // Sentinel-based three-state move: omit to leave folder unchanged; pass
    // null to clear (uncategorize); pass an id to link.
    Object? folderId = _kKeep,
  }) async {
    final body = <String, dynamic>{
      if (title != null) 'title': title,
      if (cipherBlob != null) 'cipherBlob': cipherBlob,
      if (cipherIv != null) 'cipherIv': cipherIv,
    };
    if (!identical(folderId, _kKeep)) {
      body['folderId'] = folderId; // string id or null
    }
    final res = await _dio.patch(
      ApiConstants.vaultItem(id),
      data: body,
    );
    return VaultItem.fromJson(
      Map<String, dynamic>.from(res.data['data'] as Map),
    );
  }

  Future<void> delete(String id) async {
    await _dio.delete(ApiConstants.vaultItem(id));
  }

  Future<StorageStats> storage() async {
    final res = await _dio.get(ApiConstants.vaultStorage);
    return StorageStats.fromJson(
      Map<String, dynamic>.from(res.data['data'] as Map),
    );
  }

  Future<InitiateUploadResult> initiateUpload({
    required VaultItemType type,
    required String title,
    required String cipherBlob,
    required String cipherIv,
    required int fileSize,
    required String fileMime,
  }) async {
    final res = await _dio.post(
      ApiConstants.vaultUploadInitiate,
      data: {
        'type': type.name,
        'title': title,
        'cipherBlob': cipherBlob,
        'cipherIv': cipherIv,
        'fileSize': fileSize,
        'fileMime': fileMime,
      },
    );
    final data = Map<String, dynamic>.from(res.data['data'] as Map);
    return InitiateUploadResult(
      itemId: data['itemId'] as String,
      chunkSize: (data['chunkSize'] as num?)?.toInt() ?? 5 * 1024 * 1024,
    );
  }

  Future<void> uploadCiphertext({
    required String itemId,
    required int chunkSize,
    required Uint8List ciphertext,
    required void Function(int sent, int total) onProgress,
  }) async {
    var sentTotal = 0;
    final total = ciphertext.length;
    final chunk = chunkSize <= 0 ? 5 * 1024 * 1024 : chunkSize;

    for (var offset = 0, part = 1; offset < total; part++) {
      final end = (offset + chunk > total) ? total : offset + chunk;
      final partBytes = ciphertext.sublist(offset, end);
      await _dio.post(
        ApiConstants.vaultUploadChunk(itemId, part),
        data: partBytes,
        options: Options(
          headers: {
            Headers.contentLengthHeader: partBytes.length,
            'content-type': 'application/octet-stream',
          },
        ),
      );
      sentTotal += partBytes.length;
      onProgress(sentTotal, total);
      offset = end;
    }
  }

  Future<void> abortUpload(String itemId) async {
    await _dio.delete(ApiConstants.vaultAbortUpload(itemId));
  }

  Future<VaultItem> finalizeUpload(String itemId) async {
    final res = await _dio.post(
      ApiConstants.vaultUploadFinalize,
      data: {'itemId': itemId},
    );
    return VaultItem.fromJson(
      Map<String, dynamic>.from(res.data['data'] as Map),
    );
  }

  Future<String> downloadUrl(String id) async {
    final res = await _dio.get(ApiConstants.vaultDownload(id));
    final data = Map<String, dynamic>.from(res.data['data'] as Map);
    return data['url'] as String;
  }

  /// Overwrites the encrypted body of an existing file/image item without
  /// changing its id, fileSize, or metadata blob. Used by the master-password
  /// rotation flow to migrate legacy items (master-encrypted body) to the
  /// per-file-DEK format. Caller is responsible for separately PATCHing the
  /// metadata blob to embed the new DEK + IV.
  Future<void> rekeyBody({
    required String itemId,
    required Uint8List ciphertext,
  }) async {
    await _dio.post(
      ApiConstants.vaultRekeyBody(itemId),
      data: ciphertext,
      options: Options(
        headers: {
          Headers.contentLengthHeader: ciphertext.length,
          'content-type': 'application/octet-stream',
        },
      ),
    );
  }

  Future<Uint8List> downloadCiphertext(String id) async {
    final res = await _dio.get<List<int>>(
      ApiConstants.vaultDownloadContent(id),
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(res.data!);
  }
}
