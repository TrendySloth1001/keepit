import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../shared/network/api_error.dart';
import '../data/collab_folder_models.dart';
import '../data/collab_folder_repository.dart';

class CollabFolderListState {
  const CollabFolderListState({
    this.folders = const [],
    this.isLoading = false,
    this.errorMessage,
  });

  final List<CollabFolderSummary> folders;
  final bool isLoading;
  final String? errorMessage;

  CollabFolderListState copyWith({
    List<CollabFolderSummary>? folders,
    bool? isLoading,
    Object? errorMessage = _sentinel,
  }) =>
      CollabFolderListState(
        folders: folders ?? this.folders,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: identical(errorMessage, _sentinel)
            ? this.errorMessage
            : errorMessage as String?,
      );

  static const _sentinel = Object();
}

class CollabFolderListNotifier
    extends StateNotifier<CollabFolderListState> {
  CollabFolderListNotifier() : super(const CollabFolderListState());

  final _repo = CollabFolderRepository.instance;

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

  Future<CollabFolderSummary> create({
    required String name,
    String? iconKey,
  }) async {
    final created = await _repo.create(name: name, iconKey: iconKey);
    state = state.copyWith(folders: [created, ...state.folders]);
    return created;
  }

  Future<void> deleteLocal(String id) async {
    state = state.copyWith(
      folders: state.folders.where((f) => f.id != id).toList(),
    );
  }

  void replace(CollabFolderSummary updated) {
    state = state.copyWith(
      folders: [
        for (final f in state.folders)
          if (f.id == updated.id) updated else f,
      ],
    );
  }
}

final collabFolderListProvider = StateNotifierProvider<
    CollabFolderListNotifier, CollabFolderListState>(
  (_) => CollabFolderListNotifier(),
);

/// Per-folder detail provider, keyed by folder id.
class CollabFolderDetailState {
  const CollabFolderDetailState({
    this.detail,
    this.isLoading = false,
    this.errorMessage,
  });

  final CollabFolderDetail? detail;
  final bool isLoading;
  final String? errorMessage;

  CollabFolderDetailState copyWith({
    CollabFolderDetail? detail,
    bool? isLoading,
    Object? errorMessage = _sentinel,
  }) =>
      CollabFolderDetailState(
        detail: detail ?? this.detail,
        isLoading: isLoading ?? this.isLoading,
        errorMessage: identical(errorMessage, _sentinel)
            ? this.errorMessage
            : errorMessage as String?,
      );

  static const _sentinel = Object();
}

class CollabFolderDetailNotifier
    extends StateNotifier<CollabFolderDetailState> {
  CollabFolderDetailNotifier(this.folderId)
      : super(const CollabFolderDetailState());

  final String folderId;
  final _repo = CollabFolderRepository.instance;

  Future<void> refresh() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final detail = await _repo.detail(folderId);
      state = state.copyWith(detail: detail, isLoading: false);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: friendlyApiError(e),
      );
    }
  }

  void addItemLocal(CollabItem item) {
    final d = state.detail;
    if (d == null) return;
    state = state.copyWith(
      detail: CollabFolderDetail(
        summary: d.summary,
        members: d.members,
        items: [item, ...d.items],
        activity: d.activity,
      ),
    );
  }

  void replaceItemLocal(CollabItem item) {
    final d = state.detail;
    if (d == null) return;
    state = state.copyWith(
      detail: CollabFolderDetail(
        summary: d.summary,
        members: d.members,
        items: [
          for (final i in d.items)
            if (i.id == item.id) item else i,
        ],
        activity: d.activity,
      ),
    );
  }

  void removeItemLocal(String itemId) {
    final d = state.detail;
    if (d == null) return;
    state = state.copyWith(
      detail: CollabFolderDetail(
        summary: d.summary,
        members: d.members,
        items: d.items.where((i) => i.id != itemId).toList(),
        activity: d.activity,
      ),
    );
  }

  void addMemberLocal(CollabMember member) {
    final d = state.detail;
    if (d == null) return;
    state = state.copyWith(
      detail: CollabFolderDetail(
        summary: d.summary,
        members: [...d.members, member],
        items: d.items,
        activity: d.activity,
      ),
    );
  }
}

final collabFolderDetailProvider = StateNotifierProvider.family<
    CollabFolderDetailNotifier, CollabFolderDetailState, String>(
  (_, folderId) => CollabFolderDetailNotifier(folderId),
);
