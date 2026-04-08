import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/user/schedules/data/schedule_model.dart';
import '../../analytics/data/analytics_repository.dart';
import '../../platforms/data/platform_model.dart';
import '../../platforms/data/platform_repository.dart';

class AdminSchedulesState {
  final List<Schedule> schedules;
  final List<Platform> platforms;
  final List<Channel> channels;
  final bool isLoading;
  final bool isFiltersLoading;
  final String? error;
  
  // Filters
  final String searchQuery;
  final String? selectedPlatformId;
  final String? selectedChannelId;
  
  // Pagination
  final int currentPage;
  final int totalItems;

  AdminSchedulesState({
    required this.schedules,
    required this.platforms,
    required this.channels,
    this.isLoading = false,
    this.isFiltersLoading = false,
    this.error,
    this.searchQuery = '',
    this.selectedPlatformId,
    this.selectedChannelId,
    this.currentPage = 1,
    this.totalItems = 0,
  });

  AdminSchedulesState copyWith({
    List<Schedule>? schedules,
    List<Platform>? platforms,
    List<Channel>? channels,
    bool? isLoading,
    bool? isFiltersLoading,
    String? error,
    String? searchQuery,
    String? selectedPlatformId = undefined,
    String? selectedChannelId = undefined,
    int? currentPage,
    int? totalItems,
  }) {
    return AdminSchedulesState(
      schedules: schedules ?? this.schedules,
      platforms: platforms ?? this.platforms,
      channels: channels ?? this.channels,
      isLoading: isLoading ?? this.isLoading,
      isFiltersLoading: isFiltersLoading ?? this.isFiltersLoading,
      error: error,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedPlatformId: selectedPlatformId != undefined ? selectedPlatformId : this.selectedPlatformId,
      selectedChannelId: selectedChannelId != undefined ? selectedChannelId : this.selectedChannelId,
      currentPage: currentPage ?? this.currentPage,
      totalItems: totalItems ?? this.totalItems,
    );
  }
}

// We use undefined to allow nulling out filters
const undefined = 'UNDEFINED_VALUE';

class AdminSchedulesNotifier extends StateNotifier<AdminSchedulesState> {
  final AnalyticsRepository _analyticsRepository;
  final PlatformRepository _platformRepository;

  AdminSchedulesNotifier(this._analyticsRepository, this._platformRepository)
      : super(AdminSchedulesState(schedules: [], platforms: [], channels: [])) {
    init();
  }

  Future<void> init() async {
    await loadInitialData();
    await loadSchedules();
  }

  Future<void> loadInitialData() async {
    state = state.copyWith(isFiltersLoading: true);
    try {
      final platforms = await _platformRepository.getPlatforms();
      state = state.copyWith(platforms: platforms, isFiltersLoading: false);
    } catch (e) {
      state = state.copyWith(error: e.toString(), isFiltersLoading: false);
    }
  }

  Future<void> loadSchedules({int page = 1}) async {
    state = state.copyWith(isLoading: true, currentPage: page);
    try {
      final result = await _analyticsRepository.getAllSchedules(
        search: state.searchQuery,
        platformId: state.selectedPlatformId,
        channelId: state.selectedChannelId,
        page: page,
      );
      
      final items = (result['items'] as List).map((e) => Schedule.fromJson(e)).toList();
      state = state.copyWith(
        schedules: items,
        totalItems: result['total'] as int,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(error: e.toString(), isLoading: false);
    }
  }

  Future<void> setPlatform(String? platformId) async {
    if (state.selectedPlatformId == platformId) return;
    
    state = state.copyWith(
      selectedPlatformId: platformId ?? null,
      selectedChannelId: null,
      channels: [],
      isFiltersLoading: platformId != null,
    );

    if (platformId != null) {
      try {
        final channels = await _platformRepository.getChannels(platformId);
        state = state.copyWith(channels: channels, isFiltersLoading: false);
      } catch (e) {
        state = state.copyWith(error: e.toString(), isFiltersLoading: false);
      }
    }
    
    loadSchedules(page: 1);
  }

  void setChannel(String? channelId) {
    state = state.copyWith(selectedChannelId: channelId ?? null);
    loadSchedules(page: 1);
  }

  void setSearch(String query) {
    state = state.copyWith(searchQuery: query);
    loadSchedules(page: 1);
  }

  void clearFilters() {
    state = state.copyWith(
      selectedPlatformId: null,
      selectedChannelId: null,
      searchQuery: '',
      channels: [],
    );
    loadSchedules(page: 1);
  }
}

final adminSchedulesProvider = StateNotifierProvider<AdminSchedulesNotifier, AdminSchedulesState>((ref) {
  final analyticsRepo = ref.watch(analyticsRepositoryProvider);
  final platformRepo = ref.watch(platformRepositoryProvider);
  return AdminSchedulesNotifier(analyticsRepo, platformRepo);
});
