import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../features/auth/providers/auth_provider.dart';
import 'error_banner.dart';

class AppShellAdmin extends ConsumerWidget {
  final Widget child;

  const AppShellAdmin({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    int calculateSelectedIndex(BuildContext context) {
      final location = GoRouterState.of(context).uri.path;
      if (location.startsWith('/admin/dashboard')) return 0;
      if (location.startsWith('/admin/channels')) return 1;
      if (location.startsWith('/admin/users')) return 2;
      return 0;
    }

    void onItemTapped(int index, BuildContext context) {
      switch (index) {
        case 0:
          context.go('/admin/dashboard');
          break;
        case 1:
          context.go('/admin/channels');
          break;
        case 2:
          context.go('/admin/users');
          break;
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: ErrorBannerOverlay(child: child),
      bottomNavigationBar: NavigationBar(
        selectedIndex: calculateSelectedIndex(context),
        onDestinationSelected: (index) => onItemTapped(index, context),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.bar_chart),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.layers),
            label: 'Channels',
          ),
          NavigationDestination(
            icon: Icon(Icons.people),
            label: 'Users',
          ),
        ],
      ),
    );
  }
}
