import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/crypto/vault_crypto.dart';
import '../../../shared/network/api_error.dart';
import '../../../shared/network/api_client.dart';
import '../../../shared/storage/secure_storage.dart';
import '../../../shared/storage/settings_service.dart';
import '../data/auth_models.dart';
import '../data/auth_repository.dart';

enum AuthStage { initializing, signedOut, needsMasterSetup, locked, unlocked }

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
  AuthNotifier() : super(const AuthState(stage: AuthStage.initializing)) {
    _bootstrap();
  }

  Uint8List? _masterKey;
  Uint8List? get masterKey => _masterKey;

  Future<void> _bootstrap() async {
    final settings = await SettingsService.instance.read();
    final rememberedKey = settings.rememberMasterKey
        ? await SettingsService.instance.readMasterKey()
        : null;

    try {
      final token = await SecureStore.instance.readSessionToken();
      if (token == null || token.isEmpty) {
        state = const AuthState(stage: AuthStage.signedOut);
        return;
      }

      ApiClient.instance.setSessionToken(token);
      final user = await AuthRepository.instance.me();
      await SecureStore.instance.writeCachedUser(jsonEncode(user.toJson()));

      if (!user.masterInitialized) {
        state = AuthState(stage: AuthStage.needsMasterSetup, user: user);
        return;
      }

      if (rememberedKey != null) {
        _masterKey = rememberedKey;
        state = AuthState(stage: AuthStage.unlocked, user: user);
        return;
      }

      state = AuthState(stage: AuthStage.locked, user: user);
    } catch (e) {
      final cachedUserJson = await SecureStore.instance.readCachedUser();
      final cachedUser = cachedUserJson == null
          ? null
          : UserProfile.fromJson(
              Map<String, dynamic>.from(jsonDecode(cachedUserJson) as Map),
            );

      if (e is DioException &&
          (e.response?.statusCode == 401 || e.response?.statusCode == 403)) {
        _masterKey = null;
        ApiClient.instance.setSessionToken(null);
        await SecureStore.instance.clearSessionToken();
        await SecureStore.instance.clearCachedUser();
        await SettingsService.instance.clearMasterKey();
        state = const AuthState(stage: AuthStage.signedOut);
        return;
      }

      if (cachedUser == null) {
        state = const AuthState(stage: AuthStage.signedOut);
        return;
      }

      if (!cachedUser.masterInitialized) {
        state = AuthState(stage: AuthStage.needsMasterSetup, user: cachedUser);
        return;
      }

      if (rememberedKey != null) {
        _masterKey = rememberedKey;
        state = AuthState(stage: AuthStage.unlocked, user: cachedUser);
        return;
      }

      state = AuthState(stage: AuthStage.locked, user: cachedUser);
    }
  }

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
      await SecureStore.instance.writeCachedUser(
        jsonEncode(result.user.toJson()),
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
      final user = state.user?.copyWith(
        masterInitialized: true,
        masterSalt: salt,
        masterParams: params,
      );
      if (user != null) {
        await SecureStore.instance.writeCachedUser(jsonEncode(user.toJson()));
      }
      state = AuthState(stage: AuthStage.unlocked, user: user);
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
    await SecureStore.instance.clearCachedUser();
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
    final updated = u.copyWith(bytesUsed: bytesUsed);
    state = state.copyWith(user: updated);
    SecureStore.instance.writeCachedUser(jsonEncode(updated.toJson()));
  }
}

String _readableError(Object e) {
  return friendlyApiError(e);
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>(
  (_) => AuthNotifier(),
);
