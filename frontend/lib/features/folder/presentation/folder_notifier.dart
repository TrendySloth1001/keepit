import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/network/api_error.dart';
import '../data/folder_models.dart';
import '../data/folder_repository.dart';

class FolderState {
  const FolderState({
    this.folders = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  final List<VaultFolder> folders;
  final bool isLoading;
  final String? errorMessage;

  FolderState copyWith({
    List<VaultFolder>? folders,
    bool? isLoading,
    Object? errorMessage = _sentinel,
  }) =>
      FolderState(
        folders: folders ?? this.folders,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: identical(errorMessage, _sentinel)
            ? this.errorMessage
            : errorMessage as String?,
      );

  static const _sentinel = Object();
}

class FolderNotifier extends StateNotifier<FolderState> {
  FolderNotifier() : super(const FolderState());

  final _repo = FolderRepository.instance;

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final folders = await _repo.list();
      state = state.copyWith(folders: folders, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: friendlyApiError(e),
      );
    }
  }

  Future<VaultFolder> create({required String name, String? iconKey}) async {
    final created = await _repo.create(name: name, iconKey: iconKey);
    state = state.copyWith(folders: [created, ...state.folders]);
    return created;
  }

  Future<void> rename(String id, String name) async {
    final updated = await _repo.update(id, name: name);
    state = state.copyWith(
      folders: [
        for (final f in state.folders)
          if (f.id == id) updated else f,
      ],
    );
  }

  Future<void> setIcon(String id, String? iconKey) async {
    final updated = await _repo.update(
      id,
      iconKey: iconKey,
      clearIcon: iconKey == null,
    );
    state = state.copyWith(
      folders: [
        for (final f in state.folders)
          if (f.id == id) updated else f,
      ],
    );
  }

  Future<void> delete(String id) async {
    await _repo.delete(id);
    state = state.copyWith(
      folders: state.folders.where((f) => f.id != id).toList(),
    );
  }

  /// Locally adjusts the cached itemCount for a folder when an item moves
  /// in or out. Called after a vault item move so chips show fresh counts
  /// without a round-trip to /folders.
  void bumpItemCount(String? folderId, int delta) {
    if (folderId == null || delta == 0) return;
    state = state.copyWith(
      folders: [
        for (final f in state.folders)
          if (f.id == folderId)
            f.copyWith(itemCount: (f.itemCount + delta).clamp(0, 1 << 30))
          else
            f,
      ],
    );
  }
}

final folderProvider =
    StateNotifierProvider<FolderNotifier, FolderState>((_) => FolderNotifier());
