import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'error_banner.dart';

class AppShellUser extends ConsumerWidget {
  final Widget child;

  const AppShellUser({super.key, required this.child});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      body: ErrorBannerOverlay(child: child),
    );
  }
}
