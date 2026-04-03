import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/network/dio_client.dart';
import 'stats_model.dart';

final statsRepositoryProvider = Provider<StatsRepository>((ref) {
  return StatsRepository(ref.watch(dioClientProvider));
});

class StatsRepository {
  final Dio dio;

  StatsRepository(this.dio);

  Future<OverviewStats> getOverview({DateTime? from, DateTime? to}) async {
    final response = await dio.get('/stats/overview', queryParameters: {
      if (from != null) 'from': from.toUtc().toIso8601String(),
      if (to != null) 'to': to.toUtc().toIso8601String(),
    });
    return OverviewStats.fromJson(response.data as List<dynamic>);
  }

  Future<List<ChannelStat>> getPlatformStats(String platformId, {DateTime? from, DateTime? to}) async {
    final response = await dio.get('/stats/platform/$platformId', queryParameters: {
      if (from != null) 'from': from.toUtc().toIso8601String(),
      if (to != null) 'to': to.toUtc().toIso8601String(),
    });
    final list = response.data as List<dynamic>;
    return list.map((e) => ChannelStat.fromJson(e as Map<String, dynamic>)).toList();
  }
}
