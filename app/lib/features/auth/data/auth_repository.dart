import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/network/dio_client.dart';
import '../../../core/storage/secure_storage.dart';
import 'auth_models.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final dio = ref.watch(dioClientProvider);
  final secureStorage = ref.watch(secureStorageProvider);
  return AuthRepository(dio: dio, secureStorage: secureStorage);
});

class AuthRepository {
  final Dio dio;
  final SecureStorage secureStorage;

  AuthRepository({required this.dio, required this.secureStorage});

  Future<AuthUser> login(String email, String password) async {
    try {
      final request = LoginRequest(email: email, password: password);
      final response = await dio.post(
        '/auth/login',
        data: request.toJson(),
      );

      final token = response.data['token'] as String;
      await secureStorage.writeToken(token);

      final userData = response.data['user'] as Map<String, dynamic>;
      return AuthUser.fromJson(userData);
    } catch (e) {
      if (e is DioException) {
        final message = e.response?.data['message'] ?? 'Authentication failed';
        throw Exception(message);
      }
      throw Exception('An unexpected error occurred');
    }
  }

  Future<void> logout() async {
    try {
      try {
        await dio.post('/auth/logout');
      } catch (_) {}
      
      await secureStorage.deleteToken();
    } catch (e) {
      throw Exception('Failed to logout');
    }
  }

  Future<AuthUser?> getCurrentUser() async {
    try {
      final token = await secureStorage.readToken();
      if (token == null) return null;

      final response = await dio.get('/auth/me');
      return AuthUser.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 401) {
        await secureStorage.deleteToken();
        return null;
      }
      return null;
    }
  }
  Future<void> resetPassword({required String token, required String newPassword}) async {
    try {
      await dio.post(
        '/auth/reset-password',
        data: {
          'token': token,
          'password': newPassword,
        },
      );
    } catch (e) {
      if (e is DioException) {
        final message = e.response?.data['message'] ?? 'Failed to reset password';
        throw Exception(message);
      }
      throw Exception('An unexpected error occurred');
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      await dio.post(
        '/auth/forgot-password',
        data: {'email': email},
      );
    } catch (e) {
      if (e is DioException) {
        final message = e.response?.data['message'] ?? 'Failed to request reset link';
        throw Exception(message);
      }
      throw Exception('An unexpected error occurred');
    }
  }
}
