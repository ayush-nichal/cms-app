import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/platform_model.dart';
import '../data/platform_repository.dart';

class PlatformState {
  final List<Platform> platforms;
  final Map<String, List<Channel>> channelsByPlatformId;
  final bool isLoading;
  final String? error;

  PlatformState({
    required this.platforms,
    required this.channelsByPlatformId,
    required this.isLoading,
    this.error,
  });

  PlatformState copyWith({
    List<Platform>? platforms,
    Map<String, List<Channel>>? channelsByPlatformId,
    bool? isLoading,
    String? error,
  }) {
    return PlatformState(
      platforms: platforms ?? this.platforms,
      channelsByPlatformId: channelsByPlatformId ?? this.channelsByPlatformId,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
  
  PlatformState copyWithError(String? errorMsg) {
    return PlatformState(
      platforms: platforms,
      channelsByPlatformId: channelsByPlatformId,
      isLoading: isLoading,
      error: errorMsg,
    );
  }
}

final platformProvider = StateNotifierProvider<PlatformNotifier, PlatformState>((ref) {
  final repository = ref.watch(platformRepositoryProvider);
  return PlatformNotifier(repository);
});

class PlatformNotifier extends StateNotifier<PlatformState> {
  final PlatformRepository _repository;

  PlatformNotifier(this._repository)
      : super(PlatformState(
          platforms: [],
          channelsByPlatformId: {},
          isLoading: false,
        )) {
    loadPlatforms();
  }

  Future<void> loadPlatforms() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final platforms = await _repository.getPlatforms();
      state = state.copyWith(platforms: platforms, isLoading: false);
    } catch (e) {
      state = state.copyWithError(e.toString().replaceAll('Exception: ', '')).copyWith(isLoading: false);
    }
  }

  Future<void> loadChannels(String platformId) async {
    try {
      final channels = await _repository.getChannels(platformId);
      final newMap = Map<String, List<Channel>>.from(state.channelsByPlatformId);
      newMap[platformId] = channels;
      state = state.copyWith(channelsByPlatformId: newMap);
    } catch (e) {
      state = state.copyWithError(e.toString().replaceAll('Exception: ', ''));
    }
  }

  Future<void> createPlatform(String name) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final platform = await _repository.createPlatform(name);
      state = state.copyWith(
        platforms: [platform, ...state.platforms],
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWithError(e.toString().replaceAll('Exception: ', '')).copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> updatePlatform(String id, String name) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final platform = await _repository.updatePlatform(id, name);
      final platforms = state.platforms.map((p) => p.id == id ? platform.copyWith(channelCount: p.channelCount) : p).toList();
      state = state.copyWith(platforms: platforms, isLoading: false);
    } catch (e) {
      state = state.copyWithError(e.toString().replaceAll('Exception: ', '')).copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> deletePlatform(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.deletePlatform(id);
      final platforms = state.platforms.where((p) => p.id != id).toList();
      state = state.copyWith(platforms: platforms, isLoading: false);
    } catch (e) {
      final errMsg = e.toString().replaceAll('Exception: ', '');
      state = state.copyWithError(errMsg).copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> createChannel(String platformId, String name, String handle) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final channel = await _repository.createChannel(platformId, name, handle);
      
      final newMap = Map<String, List<Channel>>.from(state.channelsByPlatformId);
      final currentList = newMap[platformId] ?? [];
      newMap[platformId] = [channel, ...currentList];
      
      final platforms = state.platforms.map((p) {
        if (p.id == platformId) return p.copyWith(channelCount: p.channelCount + 1);
        return p;
      }).toList();

      state = state.copyWith(channelsByPlatformId: newMap, platforms: platforms, isLoading: false);
    } catch (e) {
      state = state.copyWithError(e.toString().replaceAll('Exception: ', '')).copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> updateChannel(String id, String platformId, String name, String handle) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final channel = await _repository.updateChannel(id, name, handle);
      
      final newMap = Map<String, List<Channel>>.from(state.channelsByPlatformId);
      final currentList = newMap[platformId] ?? [];
      newMap[platformId] = currentList.map((c) => c.id == id ? channel : c).toList();
      
      state = state.copyWith(channelsByPlatformId: newMap, isLoading: false);
    } catch (e) {
      state = state.copyWithError(e.toString().replaceAll('Exception: ', '')).copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> deleteChannel(String id, String platformId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.deleteChannel(id);
      
      final newMap = Map<String, List<Channel>>.from(state.channelsByPlatformId);
      final currentList = newMap[platformId] ?? [];
      newMap[platformId] = currentList.where((c) => c.id != id).toList();
      
      final platforms = state.platforms.map((p) {
        if (p.id == platformId) return p.copyWith(channelCount: (p.channelCount - 1).clamp(0, 999));
        return p;
      }).toList();

      state = state.copyWith(channelsByPlatformId: newMap, platforms: platforms, isLoading: false);
    } catch (e) {
      final errMsg = e.toString().replaceAll('Exception: ', '');
      state = state.copyWithError(errMsg).copyWith(isLoading: false);
      rethrow;
    }
  }
}
