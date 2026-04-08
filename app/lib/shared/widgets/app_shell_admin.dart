import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../design/design_tokens.dart';
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
      body: ErrorBannerOverlay(child: child),
      bottomNavigationBar: NavigationBar(
        backgroundColor: surfaceWhite,
        indicatorColor: const Color(0xFFE8F0FB),
        height: 72,
        selectedIndex: calculateSelectedIndex(context),
        onDestinationSelected: (index) => onItemTapped(index, context),
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        labelTextStyle: WidgetStateProperty.resolveWith<TextStyle?>(
          (states) {
            final isSelected = states.contains(WidgetState.selected);
            return TextStyle(
              color: isSelected ? primary : onSurfaceVar,
            );
          },
        ),
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.bar_chart_rounded),
            selectedIcon: Icon(Icons.bar_chart_rounded),
            label: 'Dashboard',
          ),
          NavigationDestination(
            icon: Icon(Icons.layers_outlined),
            selectedIcon: Icon(Icons.layers_rounded),
            label: 'Channels',
          ),
          NavigationDestination(
            icon: Icon(Icons.people_outline_rounded),
            selectedIcon: Icon(Icons.people_rounded),
            label: 'Users',
          ),
        ],
      ),
    );
  }
}
