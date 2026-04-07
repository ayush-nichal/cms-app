import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/providers/auth_provider.dart';
import '../../shared/widgets/app_shell_admin.dart';
import '../../shared/widgets/app_shell_user.dart';
import '../../features/admin/platforms/screens/platforms_screen.dart';
import '../../features/admin/platforms/screens/platform_form_screen.dart';
import '../../features/admin/channels/screens/channel_form_screen.dart';
import '../../features/admin/platforms/data/platform_model.dart';
import '../../features/admin/users/screens/users_screen.dart';
import '../../features/admin/users/screens/user_form_screen.dart';
import '../../features/admin/users/screens/user_detail_screen.dart';
import '../../features/admin/users/data/user_model.dart';
import '../../features/admin/dashboard/screens/dashboard_screen.dart';
import '../../features/admin/dashboard/screens/platform_stats_screen.dart';
import '../../features/user/schedules/screens/schedules_screen.dart';
import '../../features/user/schedules/screens/schedule_form_screen.dart';
import '../../features/user/schedules/screens/schedule_detail_screen.dart';
import '../../features/user/schedules/data/schedule_model.dart';

class _RouterNotifier extends ChangeNotifier {
  final Ref _ref;
  _RouterNotifier(this._ref) {
    _ref.listen(authProvider, (_, __) => notifyListeners());
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  return GoRouter(
    initialLocation: '/',
    refreshListenable: _RouterNotifier(ref),
    redirect: (context, state) {
      final authState = ref.read(authProvider);

      return authState.when(
        data: (user) {
          final isAuthRoute = state.uri.path == '/login' || state.uri.path == '/' || state.uri.path == '/splash';
          
          if (user == null) {
            return state.uri.path == '/login' ? null : '/login';
          }

          if (isAuthRoute) {
            if (user.role == 'admin') {
              return '/admin/dashboard';
            } else {
              return '/user/schedules';
            }
          }
          
          if (state.uri.path.startsWith('/admin') && user.role != 'admin') {
            return '/user/schedules';
          }
          if (state.uri.path.startsWith('/user') && user.role == 'admin') {
            return '/admin/dashboard';
          }

          return null;
        },
        loading: () => '/splash',
        error: (_, __) => '/login',
      );
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/',
        redirect: (_, __) => '/login',
      ),
      ShellRoute(
        builder: (context, state, child) => AppShellAdmin(child: child),
        routes: [
          GoRoute(
            path: '/admin/dashboard',
            builder: (context, state) => const DashboardScreen(),
          ),
          GoRoute(
            path: '/admin/platforms/:id/stats',
            builder: (context, state) => PlatformStatsScreen(
              platformId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: '/admin/platforms',
            builder: (context, state) => const PlatformsScreen(),
          ),
          GoRoute(
            path: '/admin/channels',
            builder: (context, state) => const PlatformsScreen(),
          ),
          GoRoute(
            path: '/admin/platforms/new',
            builder: (context, state) => const PlatformFormScreen(),
          ),
          GoRoute(
            path: '/admin/platforms/edit',
            builder: (context, state) => PlatformFormScreen(platform: state.extra as Platform),
          ),
          GoRoute(
            path: '/admin/channels/new',
            builder: (context, state) {
              final platform = state.extra as Platform;
              return ChannelFormScreen(platformId: platform.id, platformName: platform.name);
            },
          ),
          GoRoute(
            path: '/admin/channels/edit',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>;
              final platform = extra['platform'] as Platform;
              final channel = extra['channel'] as Channel;
              return ChannelFormScreen(platformId: platform.id, platformName: platform.name, channel: channel);
            },
          ),
          GoRoute(
            path: '/admin/users',
            builder: (context, state) => const UsersScreen(),
          ),
          GoRoute(
            path: '/admin/users/new',
            builder: (context, state) => const UserFormScreen(),
          ),
          GoRoute(
            path: '/admin/users/edit',
            builder: (context, state) => UserFormScreen(user: state.extra as AppUser),
          ),
          GoRoute(
            path: '/admin/users/:id',
            builder: (context, state) => UserDetailScreen(userId: state.pathParameters['id']!),
          ),
        ],
      ),
      ShellRoute(
        builder: (context, state, child) => AppShellUser(child: child),
        routes: [
          GoRoute(
            path: '/user/schedules',
            builder: (context, state) => const SchedulesScreen(),
          ),
          GoRoute(
            path: '/user/schedules/new',
            builder: (context, state) => ScheduleFormScreen(channelId: state.extra as String, platformName: 'default'),
          ),
          GoRoute(
            path: '/user/schedules/edit',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>;
              return ScheduleFormScreen(
                channelId: extra['channelId'] as String,
                schedule: extra['schedule'] as Schedule,
                platformName: 'default',
              );
            },
          ),
          GoRoute(
            path: '/user/schedules/:id',
            builder: (context, state) {
              final extra = state.extra as Map<String, dynamic>;
              return ScheduleDetailScreen(
                schedule: extra['schedule'] as Schedule,
                isCreator: extra['isCreator'] as bool,
              );
            },
          ),
        ],
      ),
    ],
  );
});
