import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../shared/storage/settings_service.dart';

class SettingsNotifier extends StateNotifier<AppSettings> {
  SettingsNotifier() : super(AppSettings.defaults) {
    _load();
  }

  Future<void> _load() async {
    state = await SettingsService.instance.read();
  }

  Future<void> setAutoLock(AutoLockOption option) async {
    await SettingsService.instance.writeAutoLock(option);
    state = state.copyWith(autoLock: option);
  }

  Future<void> setRememberMasterKey(bool value) async {
    await SettingsService.instance.writeRememberMasterKey(value);
    if (!value) {
      await SettingsService.instance.clearMasterKey();
    }
    state = state.copyWith(rememberMasterKey: value);
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, AppSettings>(
      (_) => SettingsNotifier(),
    );
