import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../config/app_config.dart';
import '../storage/secure_storage.dart';
import '../../features/auth/providers/auth_provider.dart';

final dioClientProvider = Provider<Dio>((ref) {
  final secureStorage = ref.watch(secureStorageProvider);
  
  final dio = Dio(
    BaseOptions(
      baseUrl: AppConfig.apiBaseUrl,
      connectTimeout: const Duration(seconds: 60),
      receiveTimeout: const Duration(seconds: 60),
    ),
  );

  dio.interceptors.add(
    InterceptorsWrapper(
      onRequest: (options, handler) async {
        debugPrint('DIO REQ: ${options.method} ${options.uri}');
        final token = await secureStorage.readToken();
        if (token != null) {
          options.headers['Authorization'] = 'Bearer $token';
        }
        return handler.next(options);
      },
      onResponse: (response, handler) {
        debugPrint('DIO RES: ${response.statusCode} - ${response.data}');
        return handler.next(response);
      },
      onError: (DioException e, handler) {
        debugPrint('DIO ERR: ${e.message} - ${e.response?.statusCode}');
        final path = e.requestOptions.path;
        if (e.response?.statusCode == 401 && !path.contains('/auth/logout') && !path.contains('/auth/login')) {
          ref.read(authProvider.notifier).logout();
        }
        return handler.next(e);
      },
    ),
  );

  return dio;
});
