import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/providers/auth_provider.dart';
import '../providers/schedule_provider.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/design/design_tokens.dart';
import 'package:intl/intl.dart';

class SchedulesScreen extends ConsumerStatefulWidget {
  const SchedulesScreen({super.key});

  @override
  ConsumerState<SchedulesScreen> createState() => _SchedulesScreenState();
}

class _SchedulesScreenState extends ConsumerState<SchedulesScreen> {
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authProvider).valueOrNull;
      if (user != null && user.assignments.isNotEmpty) {
        ref.read(scheduleProvider.notifier).selectChannel(user.assignments.first.channelId);
      }
    });
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    if (_scrollController.position.pixels >= _scrollController.position.maxScrollExtent - 200) {
      final channelId = ref.read(scheduleProvider).selectedChannelId;
      if (channelId != null) {
        ref.read(scheduleProvider.notifier).loadMore(channelId);
      }
    }
  }

  static const _contentTypeStyles = <String, ({String label, Color bg, Color fg})>{
    'text_post': (label: 'TEXT POST', bg: Color(0xFFF3E5F5), fg: Color(0xFF6A1B9A)),
    'image_post': (label: 'IMAGE POST', bg: Color(0xFFE3F2FD), fg: Color(0xFF1565C0)),
    'short_form_video': (label: 'SHORT FORM', bg: Color(0xFFE8F5E9), fg: Color(0xFF2E7D32)),
    'long_form_video': (label: 'LONG VIDEO', bg: Color(0xFFFFF3E0), fg: Color(0xFFE65100)),
    'carousel_post': (label: 'CAROUSEL', bg: Color(0xFFFCE4EC), fg: Color(0xFFC62828)),
  };

  Widget _contentTypePill(String primitive) {
    final style = _contentTypeStyles[primitive] ?? (label: primitive.toUpperCase(), bg: surfaceLow, fg: onSurfaceVar);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: style.bg,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Text(
        style.label,
        style: GoogleFonts.epilogue(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: style.fg,
          letterSpacing: 10 * 0.05,
        ),
      ),
    );
  }

  Widget _statusWidget({required bool isPastDue, required DateTime? scheduledAt}) {
    // Note: in current v2 Schedule model, scheduledAt is required (non-null). Draft path remains for forward compatibility.
    if (scheduledAt == null) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: surfaceLow, borderRadius: BorderRadius.circular(9999)),
        child: Text(
          'DRAFT',
          style: GoogleFonts.epilogue(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: onSurfaceVar,
            letterSpacing: 11 * 0.05,
          ),
        ),
      );
    }
    if (isPastDue) {
      return Text(
        'PAST DUE',
        style: GoogleFonts.epilogue(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: errorRed,
          letterSpacing: 11 * 0.05,
        ),
      );
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: const Color(0xFFE8F0FB), borderRadius: BorderRadius.circular(9999)),
      child: Text(
        'SCHEDULED',
        style: GoogleFonts.epilogue(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: primary,
          letterSpacing: 11 * 0.05,
        ),
      ),
    );
  }

  Widget _userNavBar(BuildContext context) {
    return NavigationBar(
      backgroundColor: surfaceWhite,
      indicatorColor: const Color(0xFFE8F0FB),
      height: 72,
      labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
      selectedIndex: 0,
      onDestinationSelected: (index) {
        if (index == 0) context.go('/user/schedules');
        // index 1 (Channels) + 2 (Profile) are reserved for future user tabs.
      },
      destinations: const [
        NavigationDestination(
          icon: Icon(Icons.grid_view_outlined, color: onSurfaceVar),
          selectedIcon: Icon(Icons.grid_view_rounded, color: primary),
          label: 'Schedules',
        ),
        NavigationDestination(
          icon: Icon(Icons.subscriptions_outlined, color: onSurfaceVar),
          selectedIcon: Icon(Icons.subscriptions_rounded, color: primary),
          label: 'Channels',
        ),
        NavigationDestination(
          icon: Icon(Icons.people_outline_rounded, color: onSurfaceVar),
          selectedIcon: Icon(Icons.people_rounded, color: primary),
          label: 'Profile',
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final user = authState.valueOrNull;
    
    if (user == null || user.assignments.isEmpty) {
      return Scaffold(
        body: EmptyState.noChannels(null),
      );
    }

    final scheduleState = ref.watch(scheduleProvider);
    final notifier = ref.read(scheduleProvider.notifier);
    final selectedChannelId = scheduleState.selectedChannelId ?? user.assignments.first.channelId;
    
    final isCreator = user.role == 'creator';
    
    final schedules = scheduleState.schedulesByChannel[selectedChannelId] ?? [];
    final isLoading = scheduleState.isLoading;

    final now = DateTime.now();
    final sortedSchedules = [...schedules]..sort((a, b) {
      final aPast = a.scheduledAt.isBefore(now);
      final bPast = b.scheduledAt.isBefore(now);
      if (aPast != bPast) return aPast ? 1 : -1;
      return a.scheduledAt.compareTo(b.scheduledAt);
    });

    final dateFmt = DateFormat('MMM d');
    final timeFmt = DateFormat('hh:mm a');

    return Scaffold(
      backgroundColor: surface,
      bottomNavigationBar: _userNavBar(context),
      floatingActionButton: isCreator
          ? FloatingActionButton(
              backgroundColor: primary,
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              onPressed: () => context.push('/user/schedules/new', extra: selectedChannelId),
              child: const Icon(Icons.add_rounded, color: Colors.white, size: 28),
            )
          : null,
      body: RefreshIndicator(
        color: primary,
        onRefresh: () => notifier.loadSchedules(selectedChannelId),
        child: SingleChildScrollView(
          controller: _scrollController,
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'CREATOR STUDIO',
                          style: GoogleFonts.epilogue(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            letterSpacing: 11 * 0.08,
                            color: onSurfaceVar,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'My Schedules',
                          style: GoogleFonts.publicSans(
                            fontSize: 26,
                            fontWeight: FontWeight.w700,
                            color: primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: () => ref.read(authProvider.notifier).logout(),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.logout_rounded, color: errorRed, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          'LOGOUT',
                          style: GoogleFonts.epilogue(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: errorRed,
                            letterSpacing: 11 * 0.08,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    for (final assignment in user.assignments) ...[
                      GestureDetector(
                        onTap: () => notifier.selectChannel(assignment.channelId),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(9999),
                            gradient: assignment.channelId == selectedChannelId ? primaryGradient : null,
                            color: assignment.channelId == selectedChannelId ? null : surfaceLow,
                          ),
                          child: Text(
                            '${assignment.channelName} (${assignment.platformName})',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: assignment.channelId == selectedChannelId ? Colors.white : onSurfaceVar,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'UPCOMING & PAST',
                style: GoogleFonts.epilogue(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 11 * 0.08,
                  color: onSurfaceVar,
                ),
              ),
              const SizedBox(height: 12),
              if (isLoading && sortedSchedules.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 48),
                  child: Center(child: CircularProgressIndicator(color: primary)),
                )
              else if (sortedSchedules.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 40),
                  child: EmptyState.noSchedules(isCreator ? () => context.push('/user/schedules/new', extra: selectedChannelId) : null),
                )
              else
                Column(
                  children: [
                    for (final schedule in sortedSchedules) ...[
                      InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () => context.push('/user/schedules/${schedule.id}', extra: {'schedule': schedule, 'isCreator': isCreator}),
                        child: Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: surfaceWhite,
                            borderRadius: BorderRadius.circular(16),
                            boxShadow: const [
                              BoxShadow(color: Color(0x0A191C1D), blurRadius: 24, offset: Offset(0, 8)),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  _contentTypePill(schedule.contentType),
                                  const Spacer(),
                                  _statusWidget(isPastDue: schedule.scheduledAt.isBefore(now), scheduledAt: schedule.scheduledAt),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Text(
                                schedule.title.toUpperCase(),
                                style: GoogleFonts.publicSans(
                                  fontSize: 17,
                                  fontWeight: FontWeight.w700,
                                  color: onSurface,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Builder(
                                builder: (_) {
                                  final isPastDue = schedule.scheduledAt.isBefore(now);
                                  final icon = isPastDue ? Icons.calendar_today_rounded : Icons.schedule_rounded;
                                  final iconColor = isPastDue ? onSurface : onSurfaceVar;
                                  final textColor = isPastDue ? onSurface : onSurfaceVar;
                                  final text = '${dateFmt.format(schedule.scheduledAt)} · ${timeFmt.format(schedule.scheduledAt)}';
                                  return Row(
                                    children: [
                                      Icon(icon, size: 14, color: iconColor),
                                      const SizedBox(width: 4),
                                      Text(
                                        text,
                                        style: GoogleFonts.plusJakartaSans(fontSize: 13, color: textColor),
                                      ),
                                    ],
                                  );
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                    ],
                    if (scheduleState.isLoadMore)
                      const Padding(
                        padding: EdgeInsets.all(16.0),
                        child: Center(child: CircularProgressIndicator(color: primary)),
                      ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: () {
                        // Keep existing archive flow if present; otherwise reuse refresh.
                        notifier.loadSchedules(selectedChannelId);
                      },
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        decoration: BoxDecoration(
                          color: surfaceWhite,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0x66C1C6D4)),
                        ),
                        child: Center(
                          child: Text(
                            'VIEW ARCHIVE',
                            style: GoogleFonts.epilogue(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: onSurfaceVar,
                              letterSpacing: 12 * 0.08,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
