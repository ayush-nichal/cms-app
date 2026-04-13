import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'error_banner.dart';

import 'package:go_router/go_router.dart';
import '../../shared/design/design_tokens.dart';
import 'package:google_fonts/google_fonts.dart';

class AppShellUser extends ConsumerWidget {
  final Widget child;

  const AppShellUser({super.key, required this.child});

  Widget _userNavBar(BuildContext context) {
    return Container(
      height: 72,
      decoration: const BoxDecoration(
        color: surfaceWhite,
        border: Border(top: BorderSide(color: Color(0x26C1C6D4))),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            final location = GoRouterState.of(context).uri.path;
            if (location != '/user/schedules') {
              context.go('/user/schedules');
            }
          },
          child: Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F0FB),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Icon(Icons.grid_view_rounded, color: primary),
                ),
                const SizedBox(height: 4),
                Text(
                  'Schedules',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      backgroundColor: surface,
      body: ErrorBannerOverlay(child: child),
      bottomNavigationBar: _userNavBar(context),
    );
  }
}
