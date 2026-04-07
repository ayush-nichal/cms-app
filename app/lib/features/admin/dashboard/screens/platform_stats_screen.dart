import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';

import '../../platforms/providers/platform_provider.dart';
import '../../platforms/data/platform_model.dart';
import '../providers/dashboard_provider.dart';
import '../../analytics/providers/analytics_provider.dart';
import '../../analytics/widgets/coverage_heatmap.dart';
import '../../analytics/widgets/lead_time_line_chart.dart';
import '../../analytics/widgets/content_mix_doughnut.dart';
import '../../analytics/widgets/trend_indicator.dart';
import '../../../../core/utils/content_type_translator.dart';
import '../../../../core/widgets/loading_skeleton.dart';

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
    
    // (In actual app, the dashboard Provider gets schedules, we'll assume it exists or use mock list)
    final dashboardState = ref.watch(dashboardProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: Text('${platform.name} Stats'),
        elevation: 0,
        actions: [
          IconButton(icon: const Icon(Icons.more_vert), onPressed: () {}),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text('Channel Statistics', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue.shade800)),
                  const SizedBox(height: 16),
                  if (platformState.isLoading && channels.isEmpty)
                    LoadingSkeleton(height: 200, width: double.infinity)
                  else if (channels.isEmpty)
                    const Text('No channels for this platform.', style: TextStyle(color: Colors.grey))
                  else
                    ...channels.map((c) => _ChannelStatsBlock(channel: c, platformName: platform.name)),
                    
                  const SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text('Scheduled Posts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blue.shade800)),
                      Text(
                        '(${dashboardState.totalScheduled} Total in dashboard range)',
                        style: const TextStyle(fontSize: 12, color: Colors.grey, fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  
                  // Mock or fetch dashboard schedules
                  ...dashboardState.recentSchedules.where((s) => s.channelName != null && s.channelName!.contains(platform.name)).map((s) {
                    final isPast = s.isPastDue;
                    final typeLabel = ContentTypeTranslator.translate(s.contentType, platform.name);
                    final color = ContentTypeTranslator.getColor(s.contentType);
                    
                    return Opacity(
                      opacity: isPast ? 0.55 : 1.0,
                      child: Card(
                        elevation: 1,
                        margin: const EdgeInsets.only(bottom: 8),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(12),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(4)),
                                    child: Text(typeLabel.toUpperCase(), style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold)),
                                  ),
                                  // EMPTY STATUS SLOT
                                ],
                              ),
                              const SizedBox(height: 8),
                              Text(s.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                              if (s.channelHandle != null) Text('@${s.channelHandle}', style: TextStyle(fontSize: 12, color: Colors.blue.shade600)),
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_today, size: 12, color: Colors.grey),
                                      const SizedBox(width: 4),
                                      Text(DateFormat('MMM d, HH:mm').format(s.scheduledAt), style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                    ],
                                  ),
                                  Text(s.creatorName ?? 'unknown', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                ],
                              )
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ChannelStatsBlock extends ConsumerWidget {
  final dynamic channel; // Using dynamic because actual Channel model lacks some fields like last post in default query
  final String platformName;

  const _ChannelStatsBlock({required this.channel, required this.platformName});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final analyticsState = ref.watch(channelAnalyticsProvider(channel.id));
    final notifier = ref.read(channelAnalyticsProvider(channel.id).notifier);

    Widget graphWidget;
    if (analyticsState.isLoading) {
       graphWidget = Padding(padding: const EdgeInsets.only(top: 16), child: LoadingSkeleton(height: 150, width: double.infinity));
    } else {
       switch (analyticsState.selectedGraph) {
         case 'Creator Lead Time':
           graphWidget = LeadTimeLineChart(data: analyticsState.leadTime);
           break;
         case 'Content Mix':
           graphWidget = ContentMixDoughnut(data: analyticsState.contentMix, platformName: platformName);
           break;
         case 'Coverage Heatmap':
         default:
           graphWidget = CoverageHeatmap(data: analyticsState.heatmap, monthDate: analyticsState.currentStatsMonth);
       }
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 24.0),
      child: Column(
        children: [
          // PART 1 - Four quadrant card
          Card(
            elevation: 2,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(14.0),
              child: Column(
                children: [
                  Row(
                    children: [
                      // TOP LEFT
                      Expanded(
                        child: Row(
                          children: [
                            CircleAvatar(radius: 18, child: Text(channel.name.substring(0, 1).toUpperCase())),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(channel.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                                  Text('@${channel.handle}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(height: 40, width: 1, color: Colors.black12, margin: const EdgeInsets.symmetric(horizontal: 8)),
                      // TOP RIGHT
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('LAST POST:', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                            Text(
                              channel.lastPostAt != null 
                                ? DateFormat('MMM d, yyyy').format(channel.lastPostAt!) 
                                : 'N/A', 
                              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  Row(
                    children: [
                      // BOTTOM LEFT
                      Expanded(
                        child: TrendIndicator(data: analyticsState.trend),
                      ),
                      Container(height: 30, width: 1, color: Colors.black12, margin: const EdgeInsets.symmetric(horizontal: 8)),
                      // BOTTOM RIGHT
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('View as', style: TextStyle(fontSize: 10, color: Colors.grey)),
                            DropdownButton<String>(
                              value: analyticsState.selectedGraph,
                              isDense: true,
                              isExpanded: true,
                              underline: const SizedBox.shrink(),
                              style: const TextStyle(fontSize: 11, color: Colors.black87, fontWeight: FontWeight.w600),
                              items: const [
                                DropdownMenuItem(value: 'Coverage Heatmap', child: Text('Coverage Heatmap')),
                                DropdownMenuItem(value: 'Creator Lead Time', child: Text('Creator Lead Time')),
                                DropdownMenuItem(value: 'Content Mix', child: Text('Content Mix')),
                              ],
                              onChanged: (val) {
                                if (val != null) notifier.setGraph(val);
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 8),
          
          // PART 2 - Graph Container
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF5F5F5),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.chevron_left, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => notifier.previousMonth(),
                      color: Colors.blue.shade700,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat('MMMM yyyy').format(analyticsState.currentStatsMonth),
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black87),
                    ),
                    const SizedBox(width: 12),
                    IconButton(
                      icon: const Icon(Icons.chevron_right, size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () => notifier.nextMonth(),
                      color: Colors.blue.shade700,
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: analyticsState.selectedGraph == 'Coverage Heatmap' ? 200 : 160,
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
