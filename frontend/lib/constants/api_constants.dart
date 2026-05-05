class ApiConstants {
  static const String baseUrl = 'https://qjhcp0ph-3009.inc1.devtunnels.ms';

  static const String googleSignIn = '/api/v1/auth/google';
  static const String me = '/api/v1/auth/me';
  static const String logout = '/api/v1/auth/logout';
  static const String masterInit = '/api/v1/auth/master/init';
  static const String masterVerify = '/api/v1/auth/master/verify';
  static const String masterRotate = '/api/v1/auth/master/rotate';
  static const String privacyPolicyCurrent = '/api/v1/privacy-policy/current';
  static const String privacyPolicyConsent = '/api/v1/privacy-policy/consent';

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

  // Sharing
  static const String shares = '/api/v1/shares';
  static const String sharesReceived = '/api/v1/shares/received';
  static const String sharesSent = '/api/v1/shares/sent';
  static const String shareKeypair = '/api/v1/shares/keypair';
  static const String shareRecipientLookup =
      '/api/v1/shares/recipients/lookup';
  static String share(String id) => '$shares/$id';

  /// Web/server-side Google OAuth client ID. google_sign_in needs this as
  /// `serverClientId` so it returns an idToken our backend can verify.
  static const String googleServerClientId =
      '1079351951981-71qeiqapgjnofkkk481uni5tg14rakq6.apps.googleusercontent.com';
}
