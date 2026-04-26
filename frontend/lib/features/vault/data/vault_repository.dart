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
  const InitiateUploadResult({
    required this.itemId,
    required this.uploadUrl,
    required this.expiresInSeconds,
  });
  final String itemId;
  final String uploadUrl;
  final int expiresInSeconds;
}

class VaultRepository {
  VaultRepository._();
  static final instance = VaultRepository._();

  Dio get _dio => ApiClient.instance.dio;

  Future<ListPage> list({
    VaultItemType? type,
    String? cursor,
    int limit = 50,
  }) async {
    final res = await _dio.get(
      ApiConstants.vaultItems,
      queryParameters: {
        if (type != null) 'type': type.name,
        if (cursor != null) 'cursor': cursor,
        'limit': limit,
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
  }) async {
    final res = await _dio.patch(
      ApiConstants.vaultItem(id),
      data: {
        if (title != null) 'title': title,
        if (cipherBlob != null) 'cipherBlob': cipherBlob,
        if (cipherIv != null) 'cipherIv': cipherIv,
      },
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
      uploadUrl: data['uploadUrl'] as String,
      expiresInSeconds: data['expiresInSeconds'] as int,
    );
  }

  Future<void> uploadCiphertext({
    required String uploadUrl,
    required Uint8List ciphertext,
    required void Function(int sent, int total) onProgress,
  }) async {
    final raw = Dio();
    await raw.put(
      uploadUrl,
      data: Stream.fromIterable([ciphertext]),
      options: Options(
        headers: {
          Headers.contentLengthHeader: ciphertext.length,
          'content-type': 'application/octet-stream',
        },
      ),
      onSendProgress: onProgress,
    );
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

  Future<Uint8List> downloadCiphertext(String url) async {
    final raw = Dio();
    final res = await raw.get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(res.data!);
  }
}
