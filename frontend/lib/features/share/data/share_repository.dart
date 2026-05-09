import 'dart:typed_data';

import 'package:dio/dio.dart';

import '../../../constants/api_constants.dart';
import '../../../shared/network/api_client.dart';
import '../../vault/data/vault_models.dart';
import 'share_models.dart';

class ShareRepository {
  ShareRepository._();
  static final instance = ShareRepository._();

  Dio get _dio => ApiClient.instance.dio;

  Future<StoredKeypair> getKeypair() async {
    final res = await _dio.get(ApiConstants.shareKeypair);
    return StoredKeypair.fromJson(
      Map<String, dynamic>.from(res.data['data'] as Map),
    );
  }

  Future<void> publishKeypair({
    required String publicKey,
    required String privateCipher,
    required String privateIv,
  }) async {
    await _dio.post(
      ApiConstants.shareKeypair,
      data: {
        'publicKey': publicKey,
        'privateCipher': privateCipher,
        'privateIv': privateIv,
      },
    );
  }

  Future<RecipientInfo> lookup(String email) async {
    final res = await _dio.get(
      ApiConstants.shareRecipientLookup,
      queryParameters: {'email': email},
    );
    return RecipientInfo.fromJson(
      Map<String, dynamic>.from(res.data['data'] as Map),
    );
  }

  Future<SharedItem> create({
    required String recipientEmail,
    required VaultItemType type,
    required String title,
    required String cipherBlob,
    required String cipherIv,
    required String wrappedKey,
    String permission = 'view',
    int? expiresInDays,
    String? sourceItemId,
  }) async {
    final res = await _dio.post(
      ApiConstants.shares,
      data: {
        'recipientEmail': recipientEmail,
        'type': type.name,
        'title': title,
        'cipherBlob': cipherBlob,
        'cipherIv': cipherIv,
        'wrappedKey': wrappedKey,
        'permission': permission,
        if (expiresInDays != null) 'expiresInDays': expiresInDays,
        if (sourceItemId != null) 'sourceItemId': sourceItemId,
      },
    );
    return SharedItem.fromJson(
      Map<String, dynamic>.from(res.data['data'] as Map),
    );
  }

  /// Recipient-only: streams the encrypted body for a file/image share. The
  /// per-file DEK that decrypts these bytes lives inside the (separately
  /// encrypted) share payload — the server never sees plaintext.
  Future<Uint8List> downloadCiphertext(String shareId) async {
    final res = await _dio.get<List<int>>(
      ApiConstants.shareCiphertext(shareId),
      options: Options(responseType: ResponseType.bytes),
    );
    return Uint8List.fromList(res.data!);
  }

  Future<List<SharedItem>> received() async {
    final res = await _dio.get(ApiConstants.sharesReceived);
    final list = (res.data['data'] as List).cast<Map>();
    return list
        .map((m) => SharedItem.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<List<SharedItem>> sent() async {
    final res = await _dio.get(ApiConstants.sharesSent);
    final list = (res.data['data'] as List).cast<Map>();
    return list
        .map((m) => SharedItem.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<void> revoke(String id) =>
      _dio.delete(ApiConstants.share(id));

  /// Marks a non-file share as opened by the recipient. File shares are
  /// auto-marked server-side when their content endpoint is hit.
  Future<void> markOpened(String id) =>
      _dio.post(ApiConstants.shareOpened(id));

  /// Posts a folder-share bundle: one transaction creates a bundle row and
  /// N pre-sealed VaultShare children. Returns the freshly-listed children.
  Future<List<SharedItem>> createBundle({
    required String recipientEmail,
    required String name,
    required List<BundleEntry> items,
    String permission = 'view',
    int? expiresInDays,
    String? sourceFolderId,
  }) async {
    final res = await _dio.post(
      ApiConstants.shareBundles,
      data: {
        'recipientEmail': recipientEmail,
        'name': name,
        'permission': permission,
        if (expiresInDays != null) 'expiresInDays': expiresInDays,
        if (sourceFolderId != null) 'sourceFolderId': sourceFolderId,
        'items': items.map((e) => e.toJson()).toList(),
      },
    );
    final data = Map<String, dynamic>.from(res.data['data'] as Map);
    final shares = (data['shares'] as List).cast<Map>();
    return shares
        .map((m) => SharedItem.fromJson(Map<String, dynamic>.from(m)))
        .toList();
  }

  Future<void> revokeBundle(String id) =>
      _dio.delete(ApiConstants.shareBundle(id));
}
