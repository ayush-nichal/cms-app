import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../platforms/providers/platform_provider.dart';
import '../../platforms/data/platform_model.dart';
import '../providers/dashboard_provider.dart';
import '../../analytics/providers/analytics_provider.dart';
import '../../analytics/widgets/coverage_heatmap.dart';
import '../../analytics/widgets/lead_time_line_chart.dart';
import '../../analytics/widgets/content_mix_doughnut.dart';
import '../../../../core/utils/content_type_translator.dart';
import '../../../../core/widgets/loading_skeleton.dart';
import '../widgets/schedule_details_dialog.dart';

// Shared Color Tokens
const surface = Color(0xFFF8FAFB);
const surfaceLow = Color(0xFFF2F4F5);
const surfaceWhite = Color(0xFFFFFFFF);
const primary = Color(0xFF005DAC);
const primaryAlt = Color(0xFF1976D2);
const onSurface = Color(0xFF191C1D);
const onSurfaceVar = Color(0xFF8A9099);
const outlineGhost = Color(0x26C1C6D4);
const errorRed = Color(0xFFB3261E);
const successGreen = Color(0xFF1A7A4A);

LinearGradient getPlatformGradient(String name) {
  final lower = name.toLowerCase();
  if (lower.contains('youtube')) {
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFFF4B4B), Color(0xFFFF0000)],
    );
  }
  if (lower.contains('instagram')) {
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFF58529), Color(0xFFDD2A7B), Color(0xFF8134AF)],
    );
  }
  if (lower.contains('linkedin')) {
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF0A66C2), Color(0xFF0077B5)],
    );
  }
  if (lower.contains('tiktok')) {
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF010101), Color(0xFF69C9D0), Color(0xFFEE1D52)],
    );
  }
  if (lower.contains('facebook')) {
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF1877F2), Color(0xFF0C5CBF)],
    );
  }
  if (lower.contains('twitter') || lower.contains('x')) {
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF1DA1F2), Color(0xFF0D8ECF)],
    );
  }
  return const LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryAlt],
  );
}

class PlatformStatsScreen extends ConsumerStatefulWidget {
  final String platformId;

  const PlatformStatsScreen({super.key, required this.platformId});

  @override
  ConsumerState<PlatformStatsScreen> createState() => _PlatformStatsScreenState();
}

class _PlatformStatsScreenState extends ConsumerState<PlatformStatsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(platformProvider.notifier).loadChannels(widget.platformId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final platformState = ref.watch(platformProvider);
    final platform = platformState.platforms.firstWhere(
      (p) => p.id == widget.platformId,
      orElse: () => Platform(id: widget.platformId, name: 'Platform', channelCount: 0),
    );
    
    final channels = platformState.channelsByPlatformId[widget.platformId] ?? [];
    final dashboardState = ref.watch(dashboardProvider);
    
    final schedules = dashboardState.recentSchedules
        .where((s) => s.channelName != null && s.channelName!.contains(platform.name))
        .toList();

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        if (context.canPop()) {
          context.pop();
        } else {
          context.go('/admin/dashboard');
        }
      },
      child: Scaffold(
        backgroundColor: surface,
        appBar: AppBar(
          backgroundColor: surface,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: primary),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/admin/dashboard');
              }
            },
          ),
          title: Text(
            '${platform.name} Stats',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: onSurface,
            ),
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.more_vert, color: onSurfaceVar),
              onPressed: () {},
            ),
          ],
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Section Header: Channel Statistics
              Container(
                margin: const EdgeInsets.only(top: 16, bottom: 16),
                child: Text(
                  'Channel Statistics',
                  style: GoogleFonts.publicSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: primary,
                  ),
                ),
              ),

              if (platformState.isLoading && channels.isEmpty)
                LoadingSkeleton(height: 200, width: double.infinity)
              else if (channels.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text('No channels mapped to this platform.', 
                      style: GoogleFonts.plusJakartaSans(color: onSurfaceVar, fontSize: 14)),
                  ),
                )
              else
                ...channels.map((c) => _ChannelStatsPair(channel: c, platformName: platform.name)),

              // 3. Section Header: Scheduled Posts
              Container(
                margin: const EdgeInsets.only(top: 16, bottom: 12),
                child: Text(
                  'Scheduled Posts',
                  style: GoogleFonts.publicSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: primary,
                  ),
                ),
              ),

              if (schedules.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(bottom: 40),
                  child: Text('No scheduled posts found.', 
                    style: GoogleFonts.plusJakartaSans(color: onSurfaceVar, fontSize: 14)),
                )
              else
                ...schedules.map((s) => InkWell(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => ScheduleDetailsDialog(schedule: s),
                        );
                      },
                      borderRadius: BorderRadius.circular(16),
                      child: _PostCard(s: s),
                    )),

              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _ChannelStatsPair extends ConsumerStatefulWidget {
  final dynamic channel; 
  final String platformName;

  const _ChannelStatsPair({required this.channel, required this.platformName});

  @override
  ConsumerState<_ChannelStatsPair> createState() => _ChannelStatsPairState();
}

class _ChannelStatsPairState extends ConsumerState<_ChannelStatsPair> {
  final List<String> _graphs = ['Content Mix', 'Creator Lead Time', 'Coverage Heatmap'];
  int _graphIndex = 0;

  void _cyclePrev() {
    setState(() {
      _graphIndex = (_graphIndex - 1 + _graphs.length) % _graphs.length;
    });
    ref.read(channelAnalyticsProvider(widget.channel.id).notifier).setGraph(_graphs[_graphIndex]);
  }

  void _cycleNext() {
    setState(() {
      _graphIndex = (_graphIndex + 1) % _graphs.length;
    });
    ref.read(channelAnalyticsProvider(widget.channel.id).notifier).setGraph(_graphs[_graphIndex]);
  }

  @override
  Widget build(BuildContext context) {
    final analyticsState = ref.watch(channelAnalyticsProvider(widget.channel.id));
    final notifier = ref.read(channelAnalyticsProvider(widget.channel.id).notifier);
    
    // Ensure state matches internal tracking (for initial build)
    if (analyticsState.selectedGraph != _graphs[_graphIndex]) {
      final idx = _graphs.indexOf(analyticsState.selectedGraph);
      if (idx != -1) _graphIndex = idx;
    }

    final channelName = widget.channel.name as String;
    final firstLetter = channelName.isNotEmpty ? channelName[0].toUpperCase() : '?';
    final handle = widget.channel.handle as String?;

    IconData trendIcon;
    final trendStr = analyticsState.trend?.trend ?? 'neutral';
    if (trendStr == 'up') trendIcon = Icons.trending_up_rounded;
    else if (trendStr == 'down') trendIcon = Icons.trending_down_rounded;
    else trendIcon = Icons.trending_flat;

    String lastPostStr = 'N/A';
    if (widget.channel.lastPostAt != null) {
      final now = DateTime.now();
      final difference = now.difference(widget.channel.lastPostAt!);
      if (difference.inDays == 0) lastPostStr = 'TODAY';
      else if (difference.inDays == 1) lastPostStr = 'YESTERDAY';
      else lastPostStr = '${difference.inDays} DAYS AGO';
    }

    final monthStr = DateFormat('MMMM yyyy').format(analyticsState.currentStatsMonth).toUpperCase();
    
    // Determine the graph type based on the currently selected graph
    String graphLabelStr = '';
    Widget emptyIcon = const SizedBox.shrink();
    if (_graphs[_graphIndex] == 'Content Mix') {
      graphLabelStr = 'BAR GRAPH';
      emptyIcon = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.bar_chart, color: primary, size: 48),
          const SizedBox(height: 8),
          Text('GROWTH ENGAGEMENT VISUAL', style: GoogleFonts.epilogue(fontSize: 10, color: onSurfaceVar, letterSpacing: 0.5)),
        ],
      );
    } else if (_graphs[_graphIndex] == 'Creator Lead Time') {
      graphLabelStr = 'LINE GRAPH';
      emptyIcon = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.show_chart, color: primary.withOpacity(0.7), size: 48),
          const SizedBox(height: 8),
          Text('RETENTION RATE DATA', style: GoogleFonts.epilogue(fontSize: 10, color: onSurfaceVar, letterSpacing: 0.5)),
        ],
      );
    } else {
      graphLabelStr = 'COVERAGE HEATMAP';
      emptyIcon = Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.grid_view_rounded, color: primary, size: 48),
          const SizedBox(height: 8),
          Text('COVERAGE HEATMAP', style: GoogleFonts.epilogue(fontSize: 10, color: onSurfaceVar, letterSpacing: 0.5)),
        ],
      );
    }

    Widget graphWidget;
    if (analyticsState.isLoading) {
       graphWidget = const Center(child: CircularProgressIndicator(color: primary));
    } else {
       if (_graphs[_graphIndex] == 'Creator Lead Time') {
         if (analyticsState.leadTime.isEmpty) graphWidget = emptyIcon;
         else graphWidget = LeadTimeLineChart(data: analyticsState.leadTime);
       } else if (_graphs[_graphIndex] == 'Content Mix') {
         if (analyticsState.contentMix.isEmpty) graphWidget = emptyIcon;
         else graphWidget = ContentMixDoughnut(data: analyticsState.contentMix, platformName: widget.platformName, textColor: onSurface);
       } else {
         if (analyticsState.heatmap?.dateToCount.isEmpty ?? true) graphWidget = emptyIcon;
         else graphWidget = CoverageHeatmap(data: analyticsState.heatmap, monthDate: analyticsState.currentStatsMonth);
       }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        children: [
          // PART A: Channel Header Card
          Container(
            decoration: BoxDecoration(
              gradient: getPlatformGradient(widget.platformName),
              borderRadius: BorderRadius.circular(16),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.2),
                        shape: BoxShape.circle,
                      ),
                      alignment: Alignment.center,
                      child: Text(firstLetter, 
                        style: GoogleFonts.publicSans(fontSize: 20, fontWeight: FontWeight.w600, color: Colors.white)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(channelName, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: Colors.white)),
                          Text(handle != null ? '@$handle' : '', 
                            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.white.withOpacity(0.75))),
                        ],
                      ),
                    ),
                    Icon(trendIcon, color: Colors.white, size: 28),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('LAST POST:', style: GoogleFonts.epilogue(fontSize: 10, color: Colors.white.withOpacity(0.6), letterSpacing: 0.5)),
                        Text(lastPostStr, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: Colors.white)),
                        const SizedBox(height: 4),
                        // Note: Date ranges are hard to infer statically if we just have a month cursor, 
                        // so we can put a placeholder range mirroring designs or just the month
                        Text('THIS MONTH', style: GoogleFonts.epilogue(fontSize: 11, color: Colors.white.withOpacity(0.6), letterSpacing: 0.5)),
                      ],
                    ),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.chevron_left, color: Colors.white, size: 22),
                          onPressed: _cyclePrev,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          icon: const Icon(Icons.chevron_right, color: Colors.white, size: 22),
                          onPressed: _cycleNext,
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                        ),
                      ],
                    )
                  ],
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // PART B: Graph Container
          Container(
            decoration: BoxDecoration(
              color: surfaceWhite,
              borderRadius: BorderRadius.circular(16),
              boxShadow: const [
                BoxShadow(color: Color(0x0A191C1D), blurRadius: 32, offset: Offset(0, 12))
              ],
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(graphLabelStr, 
                  style: GoogleFonts.epilogue(fontSize: 11, fontWeight: FontWeight.w500, letterSpacing: 0.55, color: onSurfaceVar)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, color: onSurfaceVar),
                      onPressed: () => notifier.previousMonth(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                    const SizedBox(width: 8),
                    Text(monthStr, 
                      style: GoogleFonts.epilogue(fontSize: 12, fontWeight: FontWeight.w600, color: onSurface)),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, color: onSurfaceVar),
                      onPressed: () => notifier.nextMonth(),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Container(
                  constraints: const BoxConstraints(minHeight: 160),
                  alignment: Alignment.center,
                  child: graphWidget,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final dynamic s;

  const _PostCard({required this.s});

  @override
  Widget build(BuildContext context) {
    // Generate pill specs
    // We infer status from isPastDue for mock data. In actual data, status should be tracked
    // using scheduled, posted, not_posted flags if they exist. Defaulting based on time:
    String status = 'SCHEDULED';
    Color pillBg = const Color(0xFFE8F0FB);
    Color pillText = primary;
    
    if (s.isPastDue == true) {
      // Mocking past due items as randomly posted or not posted
      if (s.title.contains('Failed') || s.title.contains('Error')) {
        status = 'NOT_POSTED';
        pillBg = const Color(0xFFFFEDEA);
        pillText = errorRed;
      } else {
        status = 'POSTED';
        pillBg = const Color(0xFFE6F4EA);
        pillText = successGreen;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: surfaceWhite,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x0A191C1D), blurRadius: 32, offset: Offset(0, 12))
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: pillBg,
              borderRadius: BorderRadius.circular(9999),
            ),
            child: Text(status, 
              style: GoogleFonts.epilogue(fontSize: 10, fontWeight: FontWeight.w600, color: pillText, letterSpacing: 0.5)),
          ),
          const SizedBox(height: 8),
          Text(s.title, style: GoogleFonts.publicSans(fontSize: 16, fontWeight: FontWeight.w600, color: onSurface)),
          Text(s.channelHandle != null ? '@${s.channelHandle}' : '', 
            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: primary)),
          const SizedBox(height: 10),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.calendar_today_rounded, size: 12, color: onSurfaceVar),
                  const SizedBox(width: 4),
                  Text(DateFormat('MMM dd, HH:mm').format(s.scheduledAt), 
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: onSurfaceVar)),
                ],
              ),
              Flexible(
                child: Text(s.creatorEmail ?? s.creatorName ?? 'unknown', 
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(fontSize: 11, color: onSurfaceVar)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
