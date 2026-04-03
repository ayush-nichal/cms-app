import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/user_model.dart';
import '../data/user_repository.dart';

class UserState {
  final List<AppUser> users;
  final bool isLoading;
  final String? error;

  UserState({
    required this.users,
    required this.isLoading,
    this.error,
  });

  UserState copyWith({
    List<AppUser>? users,
    bool? isLoading,
    String? error,
  }) {
    return UserState(
      users: users ?? this.users,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }

  UserState copyWithError(String? errorMsg) {
    return UserState(
      users: users,
      isLoading: isLoading,
      error: errorMsg,
    );
  }
}

final userProvider = StateNotifierProvider<UserNotifier, UserState>((ref) {
  final repository = ref.watch(userRepositoryProvider);
  return UserNotifier(repository);
});

class UserNotifier extends StateNotifier<UserState> {
  final UserRepository _repository;

  UserNotifier(this._repository)
      : super(UserState(
          users: [],
          isLoading: false,
        )) {
    loadUsers();
  }

  Future<void> loadUsers() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final users = await _repository.getUsers();
      state = state.copyWith(users: users, isLoading: false);
    } catch (e) {
      state = state.copyWithError(e.toString().replaceAll('Exception: ', '')).copyWith(isLoading: false);
    }
  }

  Future<void> reloadUser(String id) async {
    try {
      final updatedUser = await _repository.getUserById(id);
      final users = state.users.map((u) => u.id == id ? updatedUser : u).toList();
      state = state.copyWith(users: users);
    } catch (e) {
      // Internal swallow during targeted reload
    }
  }

  Future<void> createUser(CreateUserRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final user = await _repository.createUser(request);
      state = state.copyWith(users: [user, ...state.users], isLoading: false);
      reloadUser(user.id);
    } catch (e) {
      state = state.copyWithError(e.toString().replaceAll('Exception: ', '')).copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> updateUser(String id, UpdateUserRequest request) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final updatedUser = await _repository.updateUser(id, request);
      final users = state.users.map((u) {
        if (u.id == id) {
           return updatedUser.copyWith(assignments: u.assignments); 
        }
        return u;
      }).toList();
      state = state.copyWith(users: users, isLoading: false);
      reloadUser(id); 
    } catch (e) {
      state = state.copyWithError(e.toString().replaceAll('Exception: ', '')).copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> softDeleteUser(String id) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.deleteUser(id);
      final users = state.users.map((u) => u.id == id ? u.copyWith(isActive: false) : u).toList();
      state = state.copyWith(users: users, isLoading: false);
    } catch (e) {
      state = state.copyWithError(e.toString().replaceAll('Exception: ', '')).copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> addAssignment(String userId, String channelId, String role) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final assignment = await _repository.addAssignment(userId, channelId, role);
      final users = state.users.map((u) {
        if (u.id == userId) {
          return u.copyWith(assignments: [...u.assignments, assignment]);
        }
        return u;
      }).toList();
      state = state.copyWith(users: users, isLoading: false);
    } catch (e) {
      state = state.copyWithError(e.toString().replaceAll('Exception: ', '')).copyWith(isLoading: false);
      rethrow;
    }
  }

  Future<void> removeAssignment(String userId, String channelId) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _repository.removeAssignment(userId, channelId);
      final users = state.users.map((u) {
        if (u.id == userId) {
          return u.copyWith(assignments: u.assignments.where((a) => a.channelId != channelId).toList());
        }
        return u;
      }).toList();
      state = state.copyWith(users: users, isLoading: false);
    } catch (e) {
      state = state.copyWithError(e.toString().replaceAll('Exception: ', '')).copyWith(isLoading: false);
      rethrow;
    }
  }
}
