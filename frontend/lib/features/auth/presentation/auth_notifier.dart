import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/crypto/vault_crypto.dart';
import '../../../shared/storage/secure_storage.dart';
import '../../../shared/storage/settings_service.dart';
import '../data/auth_models.dart';
import '../data/auth_repository.dart';

enum AuthStage { signedOut, needsMasterSetup, locked, unlocked }

class AuthState {
  const AuthState({
    required this.stage,
    this.user,
    this.errorMessage,
    this.isBusy = false,
  });

  final AuthStage stage;
  final UserProfile? user;
  final String? errorMessage;
  final bool isBusy;

  AuthState copyWith({
    AuthStage? stage,
    UserProfile? user,
    Object? errorMessage = _sentinel,
    bool? isBusy,
  }) {
    return AuthState(
      stage: stage ?? this.stage,
      user: user ?? this.user,
      errorMessage: identical(errorMessage, _sentinel)
          ? this.errorMessage
          : errorMessage as String?,
      isBusy: isBusy ?? this.isBusy,
    );
  }

  static const _sentinel = Object();
}

class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState(stage: AuthStage.signedOut));

  Uint8List? _masterKey;
  Uint8List? get masterKey => _masterKey;

  Future<void> signInWithGoogle() async {
    state = state.copyWith(isBusy: true, errorMessage: null);
    try {
      final result = await AuthRepository.instance.signInWithGoogle();
      await SecureStore.instance.writeSessionToken(result.token);
      state = AuthState(
        stage: result.user.masterInitialized
            ? AuthStage.locked
            : AuthStage.needsMasterSetup,
        user: result.user,
      );
    } catch (e) {
      state = state.copyWith(isBusy: false, errorMessage: _readableError(e));
    }
  }

  Future<void> setupMaster(String password) async {
    state = state.copyWith(isBusy: true, errorMessage: null);
    try {
      const params = KdfParams.defaults;
      final saltBytes = VaultCrypto.randomBytes(16);
      final salt = base64Encode(saltBytes);
      final derived = await VaultCrypto.deriveMaster(
        password: password,
        salt: saltBytes,
        params: params,
      );
      await AuthRepository.instance.initMaster(
        saltBase64: salt,
        verifierBase64: derived.verifier,
        params: params,
      );
      _masterKey = derived.key;
      await _persistKeyIfRemembered();
      state = AuthState(
        stage: AuthStage.unlocked,
        user: state.user?.copyWith(),
      );
    } catch (e) {
      state = state.copyWith(isBusy: false, errorMessage: _readableError(e));
    }
  }

  Future<void> unlockMaster(String password) async {
    state = state.copyWith(isBusy: true, errorMessage: null);
    try {
      final user = state.user!;
      final salt = base64Decode(user.masterSalt!);
      final params = user.masterParams ?? KdfParams.defaults;
      final derived = await VaultCrypto.deriveMaster(
        password: password,
        salt: salt,
        params: params,
      );
      await AuthRepository.instance.verifyMaster(
        verifierBase64: derived.verifier,
      );
      _masterKey = derived.key;
      await _persistKeyIfRemembered();
      state = AuthState(stage: AuthStage.unlocked, user: user);
    } catch (e) {
      state = state.copyWith(isBusy: false, errorMessage: _readableError(e));
    }
  }

  /// Auto-lock entry point. Wipes in-memory key. If the user opted to
  /// remember the master key on this device, silently re-loads it from
  /// OS-encrypted storage so the unlock screen never appears.
  Future<void> lock() async {
    _masterKey = null;
    final stored = await SettingsService.instance.readMasterKey();
    if (stored != null) {
      _masterKey = stored;
      return;
    }
    if (state.stage == AuthStage.unlocked) {
      state = state.copyWith(stage: AuthStage.locked);
    }
  }

  Future<void> logout() async {
    state = state.copyWith(isBusy: true, errorMessage: null);
    _masterKey = null;
    await SettingsService.instance.clearMasterKey();
    await SecureStore.instance.clearSessionToken();
    await AuthRepository.instance.logout();
    state = const AuthState(stage: AuthStage.signedOut);
  }

  /// Called from settings when toggling remember-master-key on while unlocked.
  Future<void> persistCurrentKey() => _persistKeyIfRemembered();

  Future<void> _persistKeyIfRemembered() async {
    if (_masterKey == null) return;
    final settings = await SettingsService.instance.read();
    if (settings.rememberMasterKey) {
      await SettingsService.instance.writeMasterKey(_masterKey!);
    }
  }

  void updateUserBytesUsed(int bytesUsed) {
    final u = state.user;
    if (u == null) return;
    state = state.copyWith(user: u.copyWith(bytesUsed: bytesUsed));
  }
}

String _readableError(Object e) {
  final raw = e.toString();
  return raw.length > 240 ? raw.substring(0, 240) : raw;
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (_) => AuthNotifier(),
);
