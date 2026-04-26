import 'package:dio/dio.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../../constants/api_constants.dart';
import '../../../shared/crypto/vault_crypto.dart';
import '../../../shared/network/api_client.dart';
import 'auth_models.dart';

class AuthRepository {
  AuthRepository._();
  static final instance = AuthRepository._();

  Dio get _dio => ApiClient.instance.dio;

  Future<String> _getGoogleIdToken() async {
    final google = GoogleSignIn.instance;
    await google.initialize(serverClientId: ApiConstants.googleServerClientId);
    final account = await google.authenticate();
    final idToken = account.authentication.idToken;
    if (idToken == null) {
      throw Exception('Google did not return an ID token');
    }
    return idToken;
  }

  Future<SignInResult> signInWithGoogle() async {
    final idToken = await _getGoogleIdToken();
    final res = await _dio.post(
      ApiConstants.googleSignIn,
      data: {'idToken': idToken},
    );
    final result = SignInResult.fromJson(
      Map<String, dynamic>.from(res.data['data'] as Map),
    );
    ApiClient.instance.setSessionToken(result.token);
    return result;
  }

  Future<UserProfile> me() async {
    final res = await _dio.get(ApiConstants.me);
    return UserProfile.fromJson(
      Map<String, dynamic>.from(res.data['data'] as Map),
    );
  }

  Future<void> initMaster({
    required String saltBase64,
    required String verifierBase64,
    required KdfParams params,
  }) async {
    await _dio.post(
      ApiConstants.masterInit,
      data: {
        'salt': saltBase64,
        'verifier': verifierBase64,
        'params': params.toJson(),
      },
    );
  }

  Future<void> verifyMaster({required String verifierBase64}) async {
    await _dio.post(
      ApiConstants.masterVerify,
      data: {'verifier': verifierBase64},
    );
  }

  Future<void> logout() async {
    try {
      await _dio.post(ApiConstants.logout);
    } catch (_) {}
    try {
      await GoogleSignIn.instance.signOut();
    } catch (_) {}
    ApiClient.instance.setSessionToken(null);
  }
}
