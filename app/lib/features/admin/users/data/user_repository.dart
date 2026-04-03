import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import 'user_model.dart';

final userRepositoryProvider = Provider<UserRepository>((ref) {
  final dio = ref.watch(dioClientProvider);
  return UserRepository(dio);
});

class UserRepository {
  final Dio dio;

  UserRepository(this.dio);

  String _extractErrorMessage(dynamic e) {
    if (e is DioException) {
      if (e.response?.data != null &&
          e.response?.data is Map &&
          e.response?.data['message'] != null) {
        return e.response!.data['message'].toString();
      }
      return e.message ?? 'Network Error';
    }
    return e.toString();
  }

  Future<List<AppUser>> getUsers() async {
    try {
      final response = await dio.get('/users');
      final list = response.data as List;
      return list.map((e) => AppUser.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  Future<AppUser> getUserById(String id) async {
    try {
      final response = await dio.get('/users/$id');
      return AppUser.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  Future<AppUser> createUser(CreateUserRequest request) async {
    try {
      final response = await dio.post('/users', data: request.toJson());
      return AppUser.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  Future<AppUser> updateUser(String id, UpdateUserRequest request) async {
    try {
      final response = await dio.put('/users/$id', data: request.toJson());
      return AppUser.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  Future<void> deleteUser(String id) async {
    try {
      await dio.delete('/users/$id');
    } catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  Future<UserAssignment> addAssignment(String userId, String channelId, String role) async {
    try {
      final response = await dio.post('/users/$userId/assignments', data: {
        'channelId': channelId,
        'role': role,
      });
      return UserAssignment.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  Future<void> removeAssignment(String userId, String channelId) async {
    try {
      await dio.delete('/users/$userId/assignments/$channelId');
    } catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }
}
