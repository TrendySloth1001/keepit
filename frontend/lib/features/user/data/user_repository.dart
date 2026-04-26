import 'package:dio/dio.dart';

import '../../../constants/api_constants.dart';
import '../../../shared/network/api_client.dart';
import 'user_model.dart';

class UserRepository {
  UserRepository(this._client);

  final Dio _client;

  Future<List<User>> getUsers() async {
    final response = await _client.get(ApiConstants.usersPath);
    final data = response.data as Map<String, dynamic>;
    final list = (data['data'] as List<dynamic>? ?? const [])
        .cast<Map<String, dynamic>>()
        .map(User.fromJson)
        .toList(growable: false);
    return list;
  }

  Future<User> createUser({required String name, required String email}) async {
    final response = await _client.post(
      ApiConstants.usersPath,
      data: {'name': name, 'email': email},
    );
    final data = response.data as Map<String, dynamic>;
    return User.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<User> updateUser({
    required String id,
    required String name,
    required String email,
  }) async {
    final response = await _client.patch(
      '${ApiConstants.usersPath}/$id',
      data: {'name': name, 'email': email},
    );
    final data = response.data as Map<String, dynamic>;
    return User.fromJson(data['data'] as Map<String, dynamic>);
  }

  Future<void> deleteUser(String id) async {
    await _client.delete('${ApiConstants.usersPath}/$id');
  }
}

final userRepositoryProvider = UserRepository(ApiClient.instance.dio);
