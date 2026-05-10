import 'package:dio/dio.dart';

import '../../../constants/api_constants.dart';
import '../../../shared/network/api_client.dart';
import 'collab_folder_models.dart';

class CollabFolderRepository {
  CollabFolderRepository._();
  static final instance = CollabFolderRepository._();

  Dio get _dio => ApiClient.instance.dio;

  Future<List<CollabFolderSummary>> list() async {
    final res = await _dio.get(ApiConstants.collabFolders);
    final data = (res.data['data'] as List).cast<Map>();
    return data
        .map((m) => CollabFolderSummary.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<CollabFolderSummary> create({
    required String name,
    String? iconKey,
  }) async {
    final res = await _dio.post(
      ApiConstants.collabFolders,
      data: {
        'name': name,
        if (iconKey != null) 'iconKey': iconKey,
      },
    );
    return CollabFolderSummary.fromJson(
      Map<String, dynamic>.from(res.data['data'] as Map),
    );
  }

  Future<CollabFolderDetail> detail(String id) async {
    final res = await _dio.get(ApiConstants.collabFolder(id));
    return CollabFolderDetail.fromJson(
      Map<String, dynamic>.from(res.data['data'] as Map),
    );
  }

  Future<CollabFolderSummary> update(
    String id, {
    String? name,
    String? iconKey,
    bool clearIcon = false,
  }) async {
    final res = await _dio.patch(
      ApiConstants.collabFolder(id),
      data: {
        if (name != null) 'name': name,
        if (clearIcon) 'iconKey': null else if (iconKey != null) 'iconKey': iconKey,
      },
    );
    return CollabFolderSummary.fromJson(
      Map<String, dynamic>.from(res.data['data'] as Map),
    );
  }

  Future<void> delete(String id) =>
      _dio.delete(ApiConstants.collabFolder(id));

  Future<CollabRecipientLookup> lookupRecipient(String email) async {
    final res = await _dio.get(
      ApiConstants.collabFolderRecipientLookup,
      queryParameters: {'email': email},
    );
    return CollabRecipientLookup.fromJson(
      Map<String, dynamic>.from(res.data['data'] as Map),
    );
  }

  /// itemKeys: list of {itemId, wrappedKey base64} — caller has rewrapped
  /// each existing item's DEK to the invitee's public key.
  Future<CollabMember> invite({
    required String folderId,
    required String email,
    required List<Map<String, String>> itemKeys,
  }) async {
    final res = await _dio.post(
      ApiConstants.collabFolderMembers(folderId),
      data: {'email': email, 'itemKeys': itemKeys},
    );
    return CollabMember.fromJson(
      Map<String, dynamic>.from(res.data['data'] as Map),
    );
  }

  Future<void> removeMember(String folderId, String userId) =>
      _dio.delete(ApiConstants.collabFolderMember(folderId, userId));

  /// memberKeys: list of {userId, wrappedKey base64} — must include every
  /// current member, including the caller.
  Future<CollabItem> postItem({
    required String folderId,
    required String type,
    required String title,
    required String cipherBlob,
    required String cipherIv,
    required List<Map<String, String>> memberKeys,
  }) async {
    final res = await _dio.post(
      ApiConstants.collabFolderItems(folderId),
      data: {
        'type': type,
        'title': title,
        'cipherBlob': cipherBlob,
        'cipherIv': cipherIv,
        'memberKeys': memberKeys,
      },
    );
    return CollabItem.fromJson(
      Map<String, dynamic>.from(res.data['data'] as Map),
    );
  }

  Future<CollabItem> editItem({
    required String folderId,
    required String itemId,
    String? title,
    String? cipherBlob,
    String? cipherIv,
    List<Map<String, String>>? memberKeys,
  }) async {
    final res = await _dio.patch(
      ApiConstants.collabFolderItem(folderId, itemId),
      data: {
        if (title != null) 'title': title,
        if (cipherBlob != null) 'cipherBlob': cipherBlob,
        if (cipherIv != null) 'cipherIv': cipherIv,
        if (memberKeys != null) 'memberKeys': memberKeys,
      },
    );
    return CollabItem.fromJson(
      Map<String, dynamic>.from(res.data['data'] as Map),
    );
  }

  Future<void> deleteItem(String folderId, String itemId) =>
      _dio.delete(ApiConstants.collabFolderItem(folderId, itemId));

  Future<void> markViewed(String folderId, String itemId) =>
      _dio.post(ApiConstants.collabFolderItemViewed(folderId, itemId));
}
