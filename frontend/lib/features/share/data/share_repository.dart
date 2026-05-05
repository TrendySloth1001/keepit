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
      },
    );
    return SharedItem.fromJson(
      Map<String, dynamic>.from(res.data['data'] as Map),
    );
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
}
