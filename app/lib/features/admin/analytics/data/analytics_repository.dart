import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import 'analytics_models.dart';

final analyticsRepositoryProvider = Provider<AnalyticsRepository>((ref) {
  final dio = ref.watch(dioClientProvider);
  return AnalyticsRepository(dio);
});

class AnalyticsRepository {
  final Dio dio;

  AnalyticsRepository(this.dio);

  String _extractErrorMessage(dynamic e) {
    if (e is DioException) {
      if (e.response?.data != null && e.response?.data is Map && e.response?.data['message'] != null) {
        return e.response!.data['message'].toString();
      }
      return e.message ?? 'Network Error';
    }
    return e.toString();
  }

  Future<List<PipelineWeek>> getPipelineForecast(String platformId, {DateTime? from, DateTime? to}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (from != null) queryParams['from'] = from.toUtc().toIso8601String();
      if (to != null) queryParams['to'] = to.toUtc().toIso8601String();
      
      final response = await dio.get('/analytics/platform/$platformId/pipeline', queryParameters: queryParams);
      return (response.data as List).map((e) => PipelineWeek.fromJson(e)).toList();
    } catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  Future<List<WorkloadChannel>> getWorkloadDistribution(String platformId, {DateTime? from, DateTime? to}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (from != null) queryParams['from'] = from.toUtc().toIso8601String();
      if (to != null) queryParams['to'] = to.toUtc().toIso8601String();
      
      final response = await dio.get('/analytics/platform/$platformId/workload', queryParameters: queryParams);
      return (response.data as List).map((e) => WorkloadChannel.fromJson(e)).toList();
    } catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  Future<List<ContentMixItem>> getPlatformContentMix(String platformId, {DateTime? from, DateTime? to}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (from != null) queryParams['from'] = from.toUtc().toIso8601String();
      if (to != null) queryParams['to'] = to.toUtc().toIso8601String();
      
      final response = await dio.get('/analytics/platform/$platformId/content-mix', queryParameters: queryParams);
      return (response.data as List).map((e) => ContentMixItem.fromJson(e)).toList();
    } catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  Future<HeatmapData> getCoverageHeatmap(String channelId, {int? month, int? year}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (month != null) queryParams['month'] = month;
      if (year != null) queryParams['year'] = year;
      
      final response = await dio.get('/analytics/channel/$channelId/heatmap', queryParameters: queryParams);
      return HeatmapData.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  Future<List<LeadTimeWeek>> getLeadTime(String channelId, {DateTime? from, DateTime? to}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (from != null) queryParams['from'] = from.toUtc().toIso8601String();
      if (to != null) queryParams['to'] = to.toUtc().toIso8601String();
      
      final response = await dio.get('/analytics/channel/$channelId/lead-time', queryParameters: queryParams);
      return (response.data as List).map((e) => LeadTimeWeek.fromJson(e)).toList();
    } catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  Future<List<ContentMixItem>> getChannelContentMix(String channelId, {DateTime? from, DateTime? to}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (from != null) queryParams['from'] = from.toUtc().toIso8601String();
      if (to != null) queryParams['to'] = to.toUtc().toIso8601String();
      
      final response = await dio.get('/analytics/channel/$channelId/content-mix', queryParameters: queryParams);
      return (response.data as List).map((e) => ContentMixItem.fromJson(e)).toList();
    } catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  Future<TrendData> getChannelTrend(String channelId, {int days = 7}) async {
    try {
      final response = await dio.get('/analytics/channel/$channelId/trend', queryParameters: {'days': days});
      return TrendData.fromJson(response.data as Map<String, dynamic>);
    } catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> getDashboardSummary({DateTime? from, DateTime? to}) async {
    try {
      final queryParams = <String, dynamic>{};
      if (from != null) queryParams['from'] = from.toUtc().toIso8601String();
      if (to != null) queryParams['to'] = to.toUtc().toIso8601String();
      
      final response = await dio.get('/analytics/dashboard/summary', queryParameters: queryParams);
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }

  Future<Map<String, dynamic>> getAllSchedules({
    String? search,
    String? platformId,
    String? channelId,
    int page = 1,
    int limit = 20,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'page': page,
        'limit': limit,
      };
      if (search != null && search.isNotEmpty) queryParams['search'] = search;
      if (platformId != null) queryParams['platformId'] = platformId;
      if (channelId != null) queryParams['channelId'] = channelId;

      final response = await dio.get('/analytics/dashboard/schedules-list', queryParameters: queryParams);
      return response.data as Map<String, dynamic>;
    } catch (e) {
      throw Exception(_extractErrorMessage(e));
    }
  }
}
