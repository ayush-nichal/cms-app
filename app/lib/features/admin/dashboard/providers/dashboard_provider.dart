import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/user/schedules/data/schedule_model.dart';
import '../../analytics/data/analytics_repository.dart';

class DashboardState {
  final List<Schedule> recentSchedules;
  final bool isLoading;
  final int totalScheduled;

  DashboardState({required this.recentSchedules, this.isLoading = false, this.totalScheduled = 0});

  DashboardState copyWith({List<Schedule>? recentSchedules, bool? isLoading, int? totalScheduled}) {
    return DashboardState(
      recentSchedules: recentSchedules ?? this.recentSchedules,
      isLoading: isLoading ?? this.isLoading,
      totalScheduled: totalScheduled ?? this.totalScheduled,
    );
  }
}

class DashboardNotifier extends StateNotifier<DashboardState> {
  final AnalyticsRepository _analyticsRepository;

  DashboardNotifier(this._analyticsRepository) : super(DashboardState(recentSchedules: []));

  Future<void> loadRecentSchedules({DateTime? from, DateTime? to}) async {
    state = state.copyWith(isLoading: true);
    try {
      final data = await _analyticsRepository.getDashboardSummary(from: from, to: to);
      final schedules = (data['recent'] as List).map((s) => Schedule.fromJson(s as Map<String, dynamic>)).toList();
      state = state.copyWith(
        recentSchedules: schedules, 
        totalScheduled: data['total'] as int,
        isLoading: false
      );
    } catch (e) {
      state = state.copyWith(isLoading: false);
    }
  }
}

final dashboardProvider = StateNotifierProvider<DashboardNotifier, DashboardState>((ref) {
  final repo = ref.watch(analyticsRepositoryProvider);
  return DashboardNotifier(repo);
});
