import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/stats_model.dart';
import '../data/stats_repository.dart';

class StatsState {
  final OverviewStats? overview;
  final List<ChannelStat>? selectedPlatformStats;
  final DateTime? from;
  final DateTime? to;
  final bool isLoading;
  final String? error;

  StatsState({
    this.overview,
    this.selectedPlatformStats,
    this.from,
    this.to,
    required this.isLoading,
    this.error,
  });

  StatsState copyWith({
    OverviewStats? overview,
    List<ChannelStat>? selectedPlatformStats,
    DateTime? from,
    DateTime? to,
    bool? isLoading,
    String? error,
  }) {
    return StatsState(
      overview: overview ?? this.overview,
      selectedPlatformStats: selectedPlatformStats ?? this.selectedPlatformStats,
      from: from ?? this.from,
      to: to ?? this.to,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

final statsProvider = StateNotifierProvider<StatsNotifier, StatsState>((ref) {
  return StatsNotifier(ref.watch(statsRepositoryProvider));
});

class StatsNotifier extends StateNotifier<StatsState> {
  final StatsRepository _repository;

  StatsNotifier(this._repository) : super(StatsState(isLoading: false));

  Future<void> loadOverview() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final overview = await _repository.getOverview(from: state.from, to: state.to);
      state = state.copyWith(overview: overview, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> loadPlatformStats(String platformId) async {
    state = state.copyWith(isLoading: true, error: null, selectedPlatformStats: []);
    try {
      final stats = await _repository.getPlatformStats(platformId, from: state.from, to: state.to);
      state = state.copyWith(selectedPlatformStats: stats, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void setDateRange(DateTime? from, DateTime? to) {
    state = StatsState(
      overview: state.overview,
      selectedPlatformStats: state.selectedPlatformStats,
      from: from,
      to: to,
      isLoading: state.isLoading,
      error: null,
    );
    loadOverview();
  }
}
