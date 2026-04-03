import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import 'platform_model.dart';

final platformRepositoryProvider = Provider<PlatformRepository>((ref) {
  final dio = ref.watch(dioClientProvider);
  return PlatformRepository(dio);
});

class PlatformRepository {
  final Dio dio;

  PlatformRepository(this.dio);

  String _extractErrorMessage(dynamic e) {
    if (e is DioException) {
      if (e.response?.data != null && e.response?.data is Map && e.response?.data['message'] != null) {
        return e.response!.data['message'].toString();
      }
      return e.message ?? 'Network Error';
    }
    return e.toString();
  }

  Future<List<Platform>> getPlatforms() async {
    try {
      final response = await dio.get('/platforms');
      final list = response.data as List;
      return list.map((e) => Platform.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  Future<Platform> createPlatform(String name) async {
    try {
      final response = await dio.post('/platforms', data: {'name': name});
      return Platform.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  Future<Platform> updatePlatform(String id, String name) async {
    try {
      final response = await dio.put('/platforms/$id', data: {'name': name});
      return Platform.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  Future<void> deletePlatform(String id) async {
    try {
      await dio.delete('/platforms/$id');
    } catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  Future<List<Channel>> getChannels(String platformId) async {
    try {
      final response = await dio.get('/platforms/$platformId/channels');
      final list = response.data as List;
      return list.map((e) => Channel.fromJson(e as Map<String, dynamic>)).toList();
    } catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  Future<Channel> createChannel(String platformId, String name, String handle) async {
    try {
      final response = await dio.post('/channels', data: {
        'platform_id': platformId,
        'name': name,
        'handle': handle,
      });
      return Channel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  Future<Channel> updateChannel(String id, String name, String handle) async {
    try {
      final response = await dio.put('/channels/$id', data: {
        'name': name,
        'handle': handle,
      });
      return Channel.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  Future<void> deleteChannel(String id) async {
    try {
      await dio.delete('/channels/$id');
    } catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }
}
