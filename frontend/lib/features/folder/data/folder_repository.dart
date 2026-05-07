import 'package:dio/dio.dart';

import '../../../constants/api_constants.dart';
import '../../../shared/network/api_client.dart';
import 'folder_models.dart';

class FolderRepository {
  FolderRepository._();
  static final instance = FolderRepository._();

  Dio get _dio => ApiClient.instance.dio;

  Future<List<VaultFolder>> list() async {
    final res = await _dio.get(ApiConstants.folders);
    final list = (res.data['data'] as List).cast<Map>();
    return list
        .map((m) => VaultFolder.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<VaultFolder> create({required String name, String? iconKey}) async {
    final res = await _dio.post(
      ApiConstants.folders,
      data: {
        'name': name,
        if (iconKey != null) 'iconKey': iconKey,
      },
    );
    return VaultFolder.fromJson(
      Map<String, dynamic>.from(res.data['data'] as Map),
    );
  }

  Future<VaultFolder> update(
    String id, {
    String? name,
    String? iconKey,
    bool clearIcon = false,
  }) async {
    final res = await _dio.patch(
      ApiConstants.folder(id),
      data: {
        if (name != null) 'name': name,
        if (clearIcon) 'iconKey': null else if (iconKey != null) 'iconKey': iconKey,
      },
    );
    return VaultFolder.fromJson(
      Map<String, dynamic>.from(res.data['data'] as Map),
    );
  }

  Future<void> delete(String id) =>
      _dio.delete(ApiConstants.folder(id));
}
