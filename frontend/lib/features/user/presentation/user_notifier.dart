import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/user_model.dart';
import '../data/user_repository.dart';
import 'user_state.dart';

final userControllerProvider = StateNotifierProvider<UserController, UserState>(
  (ref) {
    return UserController(userRepositoryProvider)..loadUsers();
  },
);

class UserController extends StateNotifier<UserState> {
  UserController(this._repository) : super(const UserState());

  final UserRepository _repository;

  Future<void> loadUsers() async {
    state = state.copyWith(isLoading: true, errorMessage: null);
    try {
      final users = await _repository.getUsers();
      state = state.copyWith(users: users, isLoading: false);
    } catch (error) {
      state = state.copyWith(isLoading: false, errorMessage: error.toString());
    }
  }

  Future<void> createUser(String name, String email) async {
    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      await _repository.createUser(name: name, email: email);
      await loadUsers();
    } catch (error) {
      state = state.copyWith(isSaving: false, errorMessage: error.toString());
    }
  }

  Future<void> updateUser(User user, String name, String email) async {
    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      await _repository.updateUser(id: user.id, name: name, email: email);
      await loadUsers();
    } catch (error) {
      state = state.copyWith(isSaving: false, errorMessage: error.toString());
    }
  }

  Future<void> deleteUser(String id) async {
    state = state.copyWith(isSaving: true, errorMessage: null);
    try {
      await _repository.deleteUser(id);
      await loadUsers();
    } catch (error) {
      state = state.copyWith(isSaving: false, errorMessage: error.toString());
    }
  }
}
