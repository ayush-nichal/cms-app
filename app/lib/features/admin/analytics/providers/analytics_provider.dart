import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../data/analytics_models.dart';
import '../data/analytics_repository.dart';

// --- Platform Level ---

class PlatformAnalyticsState {
  final List<PipelineWeek> pipeline;
  final List<WorkloadChannel> workload;
  final List<ContentMixItem> contentMix;
  final String selectedGraph; // 'Bar Graph', 'Pie Chart', 'Line Chart'
  final DateTime? dateFrom;
  final DateTime? dateTo;
  final bool isLoading;
  final String? error;

  PlatformAnalyticsState({
    required this.pipeline,
    required this.workload,
    required this.contentMix,
    required this.selectedGraph,
    this.dateFrom,
    this.dateTo,
    required this.isLoading,
    this.error,
  });

  PlatformAnalyticsState copyWith({
    List<PipelineWeek>? pipeline,
    List<WorkloadChannel>? workload,
    List<ContentMixItem>? contentMix,
    String? selectedGraph,
    DateTime? dateFrom,
    DateTime? dateTo,
    bool? isLoading,
    String? error,
  }) {
    return PlatformAnalyticsState(
      pipeline: pipeline ?? this.pipeline,
      workload: workload ?? this.workload,
      contentMix: contentMix ?? this.contentMix,
      selectedGraph: selectedGraph ?? this.selectedGraph,
      dateFrom: dateFrom ?? this.dateFrom,
      dateTo: dateTo ?? this.dateTo,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class PlatformAnalyticsNotifier extends StateNotifier<PlatformAnalyticsState> {
  final AnalyticsRepository _repository;
  final String platformId;

  PlatformAnalyticsNotifier(this._repository, this.platformId)
      : super(PlatformAnalyticsState(
          pipeline: [],
          workload: [],
          contentMix: [],
          selectedGraph: 'Bar Graph',
          isLoading: false,
        ));

  void setGraph(String type) {
    if (state.selectedGraph == type) return;
    state = state.copyWith(selectedGraph: type);
  }

  void setDateRange(DateTime? from, DateTime? to) {
    state = state.copyWith(dateFrom: from, dateTo: to);
    loadAll();
  }

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final pipeline = await _repository.getPipelineForecast(platformId, from: state.dateFrom, to: state.dateTo);
      final workload = await _repository.getWorkloadDistribution(platformId, from: state.dateFrom, to: state.dateTo);
      final contentMix = await _repository.getPlatformContentMix(platformId, from: state.dateFrom, to: state.dateTo);

      state = state.copyWith(
        pipeline: pipeline,
        workload: workload,
        contentMix: contentMix,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }
}

final platformAnalyticsProvider = StateNotifierProvider.family<PlatformAnalyticsNotifier, PlatformAnalyticsState, String>(
  (ref, platformId) {
    final repo = ref.watch(analyticsRepositoryProvider);
    return PlatformAnalyticsNotifier(repo, platformId);
  },
);

// --- Channel Level ---

class ChannelAnalyticsState {
  final HeatmapData? heatmap;
  final List<LeadTimeWeek> leadTime;
  final List<ContentMixItem> contentMix;
  final TrendData? trend;
  final String selectedGraph; // 'Coverage Heatmap', 'Creator Lead Time', 'Content Mix'
  final DateTime currentStatsMonth;
  final bool isLoading;
  final String? error;

  ChannelAnalyticsState({
    this.heatmap,
    required this.leadTime,
    required this.contentMix,
    this.trend,
    required this.selectedGraph,
    required this.currentStatsMonth,
    required this.isLoading,
    this.error,
  });

  ChannelAnalyticsState copyWith({
    HeatmapData? heatmap,
    List<LeadTimeWeek>? leadTime,
    List<ContentMixItem>? contentMix,
    TrendData? trend,
    String? selectedGraph,
    DateTime? currentStatsMonth,
    bool? isLoading,
    String? error,
  }) {
    return ChannelAnalyticsState(
      heatmap: heatmap ?? this.heatmap,
      leadTime: leadTime ?? this.leadTime,
      contentMix: contentMix ?? this.contentMix,
      trend: trend ?? this.trend,
      selectedGraph: selectedGraph ?? this.selectedGraph,
      currentStatsMonth: currentStatsMonth ?? this.currentStatsMonth,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}

class ChannelAnalyticsNotifier extends StateNotifier<ChannelAnalyticsState> {
  final AnalyticsRepository _repository;
  final String channelId;

  ChannelAnalyticsNotifier(this._repository, this.channelId)
      : super(ChannelAnalyticsState(
          leadTime: [],
          contentMix: [],
          selectedGraph: 'Coverage Heatmap',
          currentStatsMonth: DateTime.now(),
          isLoading: false,
        ));

  void setGraph(String type) {
    if (state.selectedGraph == type) return;
    state = state.copyWith(selectedGraph: type);
  }

  void previousMonth() {
    final prev = DateTime(state.currentStatsMonth.year, state.currentStatsMonth.month - 1);
    state = state.copyWith(currentStatsMonth: prev);
    loadAll();
  }

  void nextMonth() {
    final next = DateTime(state.currentStatsMonth.year, state.currentStatsMonth.month + 1);
    state = state.copyWith(currentStatsMonth: next);
    loadAll();
  }

  Future<void> loadAll() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final y = state.currentStatsMonth.year;
      final m = state.currentStatsMonth.month;
      final fromDate = DateTime(y, m, 1);
      final toDate = DateTime(y, m + 1, 0, 23, 59, 59);
      
      final heatmap = await _repository.getCoverageHeatmap(channelId, month: m, year: y);
      final leadTime = await _repository.getLeadTime(channelId, from: fromDate, to: toDate);
      final contentMix = await _repository.getChannelContentMix(channelId, from: fromDate, to: toDate);
      final trend = await _repository.getChannelTrend(channelId, days: 30); // Leave trend relative as general indicator

      state = state.copyWith(
        heatmap: heatmap,
        leadTime: leadTime,
        contentMix: contentMix,
        trend: trend,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }
}

final channelAnalyticsProvider = StateNotifierProvider.family<ChannelAnalyticsNotifier, ChannelAnalyticsState, String>(
  (ref, channelId) {
    final repo = ref.watch(analyticsRepositoryProvider);
    return ChannelAnalyticsNotifier(repo, channelId)..loadAll(); // Start loading immediately for channels
  },
);
