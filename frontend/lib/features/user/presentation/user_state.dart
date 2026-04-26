import '../data/user_model.dart';

class UserState {
  const UserState({
    this.users = const [],
    this.isLoading = false,
    this.isSaving = false,
    this.errorMessage,
  });

  final List<User> users;
  final bool isLoading;
  final bool isSaving;
  final String? errorMessage;

  UserState copyWith({
    List<User>? users,
    bool? isLoading,
    bool? isSaving,
    String? errorMessage,
  }) {
    return UserState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      errorMessage: errorMessage,
    );
  }
}
