class ApiConstants {
  static const String baseUrl = 'https://qjhcp0ph-3009.inc1.devtunnels.ms';

  static const String googleSignIn = '/api/v1/auth/google';
  static const String me = '/api/v1/auth/me';
  static const String logout = '/api/v1/auth/logout';
  static const String masterInit = '/api/v1/auth/master/init';
  static const String masterVerify = '/api/v1/auth/master/verify';

  static const String vaultItems = '/api/v1/vault/items';
  static const String vaultStorage = '/api/v1/vault/storage';
  static const String vaultUploadInitiate = '/api/v1/vault/uploads/initiate';
  static const String vaultUploadFinalize = '/api/v1/vault/uploads/finalize';
  static String vaultUploadContent(String itemId) =>
      '/api/v1/vault/uploads/$itemId/content';
  static String vaultUploadChunk(String itemId, int partNumber) =>
      '/api/v1/vault/uploads/$itemId/chunks/$partNumber';
  static String vaultAbortUpload(String itemId) =>
      '/api/v1/vault/uploads/$itemId';

  static String vaultItem(String id) => '$vaultItems/$id';
  static String vaultDownload(String id) => '$vaultItems/$id/download';
  static String vaultDownloadContent(String id) => '$vaultItems/$id/content';

  /// Web/server-side Google OAuth client ID. google_sign_in needs this as
  /// `serverClientId` so it returns an idToken our backend can verify.
  static const String googleServerClientId =
      '1079351951981-71qeiqapgjnofkkk481uni5tg14rakq6.apps.googleusercontent.com';
}
