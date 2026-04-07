import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import 'schedule_model.dart';

final scheduleRepositoryProvider = Provider<ScheduleRepository>((ref) {
  final dio = ref.watch(dioClientProvider);
  return ScheduleRepository(dio);
});

class ScheduleRepository {
  final Dio dio;

  ScheduleRepository(this.dio);

  String _extractErrorMessage(dynamic e) {
    if (e is DioException) {
      if (e.response?.data != null && e.response?.data is Map && e.response?.data['message'] != null) {
        return e.response!.data['message'].toString();
      }
      return e.message ?? 'Network Error';
    }
    return e.toString();
  }

  Future<SchedulePage> getSchedules(String channelId, {int page = 1}) async {
    try {
      final response = await dio.get('/schedules', queryParameters: {
        'channelId': channelId,
        'page': page,
        'limit': 20,
      });
      return SchedulePage.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  Future<Schedule> getSchedule(String id) async {
    try {
      final response = await dio.get('/schedules/$id');
      return Schedule.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  Future<Schedule> createSchedule(CreateScheduleRequest request) async {
    try {
      final response = await dio.post('/schedules', data: request.toJson());
      return Schedule.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  Future<Schedule> updateSchedule(String id, CreateScheduleRequest request) async {
    try {
      final response = await dio.put('/schedules/$id', data: request.toJson());
      return Schedule.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  Future<void> deleteSchedule(String id) async {
    try {
      await dio.delete('/schedules/$id');
    } catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }
}
