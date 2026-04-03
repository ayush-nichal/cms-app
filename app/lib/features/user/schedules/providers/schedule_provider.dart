import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/schedule_model.dart';
import '../data/schedule_repository.dart';

class ScheduleState {
  final Map<String, List<Schedule>> schedulesByChannel;
  final Map<String, int> pageByChannel;
  final Map<String, bool> hasMoreByChannel;
  final String? selectedChannelId;
  final bool isLoading;
  final bool isLoadMore;
  final String? error;

  ScheduleState({
    required this.schedulesByChannel,
    required this.pageByChannel,
    required this.hasMoreByChannel,
    this.selectedChannelId,
    required this.isLoading,
    this.isLoadMore = false,
    this.error,
  });

  ScheduleState copyWith({
    Map<String, List<Schedule>>? schedulesByChannel,
    Map<String, int>? pageByChannel,
    Map<String, bool>? hasMoreByChannel,
    String? selectedChannelId,
    bool? isLoading,
    bool? isLoadMore,
    String? error,
  }) {
    return ScheduleState(
      schedulesByChannel: schedulesByChannel ?? this.schedulesByChannel,
      pageByChannel: pageByChannel ?? this.pageByChannel,
      hasMoreByChannel: hasMoreByChannel ?? this.hasMoreByChannel,
      selectedChannelId: selectedChannelId ?? this.selectedChannelId,
      isLoading: isLoading ?? this.isLoading,
      isLoadMore: isLoadMore ?? this.isLoadMore,
      error: error,
    );
  }

  ScheduleState copyWithError(String? errorMsg) {
    return ScheduleState(
      schedulesByChannel: schedulesByChannel,
      pageByChannel: pageByChannel,
      hasMoreByChannel: hasMoreByChannel,
      selectedChannelId: selectedChannelId,
      isLoading: false,
      isLoadMore: false,
      error: errorMsg,
    );
  }
}

final scheduleProvider = StateNotifierProvider<ScheduleNotifier, ScheduleState>((ref) {
  final repository = ref.watch(scheduleRepositoryProvider);
  return ScheduleNotifier(repository);
});

class ScheduleNotifier extends StateNotifier<ScheduleState> {
  final ScheduleRepository _repository;

  ScheduleNotifier(this._repository)
      : super(ScheduleState(
          schedulesByChannel: {},
          pageByChannel: {},
          hasMoreByChannel: {},
          isLoading: false,
        ));

  void selectChannel(String channelId) {
    if (state.selectedChannelId == channelId) return;
    state = state.copyWith(selectedChannelId: channelId, error: null);
    if (!state.schedulesByChannel.containsKey(channelId) || state.schedulesByChannel[channelId]!.isEmpty) {
      loadSchedules(channelId);
    }
  }

  Future<void> loadSchedules(String channelId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final pageData = await _repository.getSchedules(channelId, page: 1);
      final newMap = Map<String, List<Schedule>>.from(state.schedulesByChannel);
      final newPageMap = Map<String, int>.from(state.pageByChannel);
      final newHasMoreMap = Map<String, bool>.from(state.hasMoreByChannel);
      
      newMap[channelId] = pageData.items;
      newPageMap[channelId] = 1;
      newHasMoreMap[channelId] = pageData.hasMore;

      state = state.copyWith(
        schedulesByChannel: newMap,
        pageByChannel: newPageMap,
        hasMoreByChannel: newHasMoreMap,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWithError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> loadMore(String channelId) async {
    if (state.isLoading || state.isLoadMore || state.hasMoreByChannel[channelId] == false) return;
    
    final currentPage = state.pageByChannel[channelId] ?? 1;
    state = state.copyWith(isLoadMore: true, error: null);
    
    try {
      final pageData = await _repository.getSchedules(channelId, page: currentPage + 1);
      
      final newMap = Map<String, List<Schedule>>.from(state.schedulesByChannel);
      final newPageMap = Map<String, int>.from(state.pageByChannel);
      final newHasMoreMap = Map<String, bool>.from(state.hasMoreByChannel);
      
      final currentItems = newMap[channelId] ?? [];
      newMap[channelId] = [...currentItems, ...pageData.items];
      newPageMap[channelId] = currentPage + 1;
      newHasMoreMap[channelId] = pageData.hasMore;

      state = state.copyWith(
        schedulesByChannel: newMap,
        pageByChannel: newPageMap,
        hasMoreByChannel: newHasMoreMap,
        isLoadMore: false,
      );
    } catch (e) {
      state = state.copyWithError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> createSchedule(CreateScheduleRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final schedule = await _repository.createSchedule(request);
      final channelId = request.channelId;
      
      final newMap = Map<String, List<Schedule>>.from(state.schedulesByChannel);
      final currentItems = newMap[channelId] ?? [];
      newMap[channelId] = [schedule, ...currentItems];
      
      state = state.copyWith(schedulesByChannel: newMap, isLoading: false);
    } catch (e) {
      state = state.copyWithError(e.toString().replaceAll('Exception: ', '')).copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> updateSchedule(String id, CreateScheduleRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final schedule = await _repository.updateSchedule(id, request);
      final channelId = request.channelId;
      
      final newMap = Map<String, List<Schedule>>.from(state.schedulesByChannel);
      final currentItems = newMap[channelId] ?? [];
      newMap[channelId] = currentItems.map((s) => s.id == id ? schedule : s).toList();
      
      state = state.copyWith(schedulesByChannel: newMap, isLoading: false);
    } catch (e) {
      state = state.copyWithError(e.toString().replaceAll('Exception: ', '')).copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> deleteSchedule(String id, String channelId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.deleteSchedule(id);
      
      final newMap = Map<String, List<Schedule>>.from(state.schedulesByChannel);
      final currentItems = newMap[channelId] ?? [];
      newMap[channelId] = currentItems.where((s) => s.id != id).toList();
      
      state = state.copyWith(schedulesByChannel: newMap, isLoading: false);
    } catch (e) {
      state = state.copyWithError(e.toString().replaceAll('Exception: ', '')).copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> updateStatus(String id, String channelId, String newStatus) async {
    final oldMap = Map<String, List<Schedule>>.from(state.schedulesByChannel);
    final currentItems = oldMap[channelId] ?? [];
    
    final index = currentItems.indexWhere((s) => s.id == id);
    if (index == -1) return;
    
    final oldSchedule = currentItems[index];
    final optimisticSchedule = Schedule(
      id: oldSchedule.id,
      channelId: oldSchedule.channelId,
      title: oldSchedule.title,
      contentType: oldSchedule.contentType,
      description: oldSchedule.description,
      mediaUrl: oldSchedule.mediaUrl,
      scheduledAt: oldSchedule.scheduledAt,
      status: newStatus, 
      createdById: oldSchedule.createdById,
      creatorName: oldSchedule.creatorName,
      statusUpdatedByName: 'Updating...',
      statusUpdatedAt: DateTime.now(),
      createdAt: oldSchedule.createdAt,
    );
    
    currentItems[index] = optimisticSchedule;
    oldMap[channelId] = currentItems;
    state = state.copyWith(schedulesByChannel: oldMap);

    try {
      final updatedSchedule = await _repository.updateStatus(id, newStatus);
      final newMap = Map<String, List<Schedule>>.from(state.schedulesByChannel);
      final newItems = newMap[channelId] ?? [];
      final newIndex = newItems.indexWhere((s) => s.id == id);
      if (newIndex != -1) {
        newItems[newIndex] = updatedSchedule;
        newMap[channelId] = newItems;
        state = state.copyWith(schedulesByChannel: newMap);
      }
    } catch (e) {
      final revertMap = Map<String, List<Schedule>>.from(state.schedulesByChannel);
      final revertItems = revertMap[channelId] ?? [];
      final revertIndex = revertItems.indexWhere((s) => s.id == id);
      if (revertIndex != -1) {
        revertItems[revertIndex] = oldSchedule;
        revertMap[channelId] = revertItems;
        state = state.copyWithError(e.toString().replaceAll('Exception: ', '')).copyWith(schedulesByChannel: revertMap);
      }
      rethrow;
    }
  }
}
