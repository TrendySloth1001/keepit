import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';

/// Wraps `local_auth` to centralize availability checks and prompts.
class BiometricService {
  BiometricService._();
  static final instance = BiometricService._();

  final _auth = LocalAuthentication();

  Future<bool> isSupported() async {
    try {
      final supported = await _auth.isDeviceSupported();
      if (!supported) return false;
      final canCheck = await _auth.canCheckBiometrics;
      return canCheck;
    } on PlatformException {
      return false;
    }
  }

  /// Prompts the OS biometric (FaceID / TouchID / fingerprint) sheet.
  /// Returns true on success. Errors and cancellations resolve to false.
  Future<bool> authenticate({
    String reason = 'Unlock your KeepIt vault',
  }) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } on PlatformException {
      return false;
    }
  }
}
