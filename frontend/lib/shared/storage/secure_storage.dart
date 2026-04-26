import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStore {
  SecureStore._();
  static final instance = SecureStore._();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _kSessionToken = 'session_token';
  static const _kCachedUser = 'cached_user_profile';

  Future<String?> readSessionToken() => _storage.read(key: _kSessionToken);
  Future<void> writeSessionToken(String token) =>
      _storage.write(key: _kSessionToken, value: token);
  Future<void> clearSessionToken() => _storage.delete(key: _kSessionToken);

  Future<String?> readCachedUser() => _storage.read(key: _kCachedUser);
  Future<void> writeCachedUser(String userJson) =>
      _storage.write(key: _kCachedUser, value: userJson);
  Future<void> clearCachedUser() => _storage.delete(key: _kCachedUser);

  Future<void> clearAll() => _storage.deleteAll();
}
