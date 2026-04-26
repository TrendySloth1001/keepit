import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/network/api_error.dart';
import '../data/vault_models.dart';
import '../data/vault_repository.dart';

class StorageState {
  const StorageState({this.stats, this.isLoading = false, this.errorMessage});
  final StorageStats? stats;
  final bool isLoading;
  final String? errorMessage;

  StorageState copyWith({
    StorageStats? stats,
    bool? isLoading,
    Object? errorMessage = _sentinel,
  }) => StorageState(
    stats: stats ?? this.stats,
    isLoading: isLoading ?? this.isLoading,
    errorMessage: identical(errorMessage, _sentinel)
        ? this.errorMessage
        : errorMessage as String?,
  );
  static const _sentinel = Object();
}

class StorageNotifier extends StateNotifier<StorageState> {
  StorageNotifier() : super(const StorageState());

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final stats = await VaultRepository.instance.storage();
      state = state.copyWith(stats: stats, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, errorMessage: friendlyApiError(e));
    }
  }
}

final storageProvider =
    StateNotifierProvider<StorageNotifier, StorageState>(
      (_) => StorageNotifier(),
    );
