import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Auto-lock idle window. `never` disables idle auto-lock entirely.
enum AutoLockOption {
  oneMinute(Duration(minutes: 1), '1 minute'),
  threeMinutes(Duration(minutes: 3), '3 minutes'),
  fiveMinutes(Duration(minutes: 5), '5 minutes'),
  fifteenMinutes(Duration(minutes: 15), '15 minutes'),
  thirtyMinutes(Duration(minutes: 30), '30 minutes'),
  never(null, 'Never');

  const AutoLockOption(this.duration, this.label);
  final Duration? duration;
  final String label;

  static AutoLockOption fromKey(String? key) {
    return AutoLockOption.values.firstWhere(
      (o) => o.name == key,
      orElse: () => AutoLockOption.threeMinutes,
    );
  }
}

class AppSettings {
  const AppSettings({
    required this.autoLock,
    required this.rememberMasterKey,
  });

  final AutoLockOption autoLock;
  final bool rememberMasterKey;

  AppSettings copyWith({
    AutoLockOption? autoLock,
    bool? rememberMasterKey,
  }) => AppSettings(
    autoLock: autoLock ?? this.autoLock,
    rememberMasterKey: rememberMasterKey ?? this.rememberMasterKey,
  );

  static const defaults = AppSettings(
    autoLock: AutoLockOption.threeMinutes,
    rememberMasterKey: false,
  );
}

class SettingsService {
  SettingsService._();
  static final instance = SettingsService._();

  final FlutterSecureStorage _storage = const FlutterSecureStorage(
    aOptions: AndroidOptions(),
    iOptions: IOSOptions(accessibility: KeychainAccessibility.first_unlock),
  );

  static const _kAutoLock = 'settings_auto_lock';
  static const _kRememberKey = 'settings_remember_key';
  static const _kMasterKey = 'master_key_b64';

  Future<AppSettings> read() async {
    final autoLockKey = await _storage.read(key: _kAutoLock);
    final remember = await _storage.read(key: _kRememberKey);
    return AppSettings(
      autoLock: AutoLockOption.fromKey(autoLockKey),
      rememberMasterKey: remember == 'true',
    );
  }

  Future<void> writeAutoLock(AutoLockOption option) =>
      _storage.write(key: _kAutoLock, value: option.name);

  Future<void> writeRememberMasterKey(bool value) =>
      _storage.write(key: _kRememberKey, value: value ? 'true' : 'false');

  Future<Uint8List?> readMasterKey() async {
    final b64 = await _storage.read(key: _kMasterKey);
    if (b64 == null) return null;
    return base64Decode(b64);
  }

  Future<void> writeMasterKey(Uint8List key) =>
      _storage.write(key: _kMasterKey, value: base64Encode(key));

  Future<void> clearMasterKey() => _storage.delete(key: _kMasterKey);
}
