import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class SecureStore {
  SecureStore._();
  static final instance = SecureStore._();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _kSessionToken = 'session_token';

  Future<String?> readSessionToken() => _storage.read(key: _kSessionToken);
  Future<void> writeSessionToken(String token) =>
      _storage.write(key: _kSessionToken, value: token);
  Future<void> clearSessionToken() => _storage.delete(key: _kSessionToken);

  Future<void> clearAll() => _storage.deleteAll();
}
