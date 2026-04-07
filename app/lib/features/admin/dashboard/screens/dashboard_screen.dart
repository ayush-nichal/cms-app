import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../auth/providers/auth_provider.dart';
import '../../platforms/providers/platform_provider.dart';
import '../../platforms/data/platform_model.dart';
import '../providers/dashboard_provider.dart';
import '../../analytics/providers/analytics_provider.dart';
import '../../analytics/widgets/pipeline_bar_chart.dart';
import '../../analytics/widgets/workload_bar_chart.dart';
import '../../analytics/widgets/content_mix_doughnut.dart';
import '../../../../core/utils/content_type_translator.dart';
import '../../../../core/widgets/loading_skeleton.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  DateTime? _fromDate;
  DateTime? _toDate;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(platformProvider.notifier).loadPlatforms();
      ref.read(dashboardProvider.notifier).loadRecentSchedules(from: _fromDate, to: _toDate);
    });
  }

  Future<void> _pickDateRange(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2020),
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: _fromDate != null && _toDate != null
          ? DateTimeRange(start: _fromDate!, end: _toDate!)
          : null,
    );
    if (picked != null) {
      setState(() {
        _fromDate = picked.start;
        _toDate = picked.end;
      });
      ref.read(dashboardProvider.notifier).loadRecentSchedules(from: _fromDate, to: _toDate);
      // Update global analytics for each expanded platform
      // Platform providers automatically read states but we must call them to update DateRange
    }
  }

  IconData _getPlatformIcon(String name) {
    name = name.toLowerCase();
    if (name.contains('youtube')) return Icons.play_circle;
    if (name.contains('instagram')) return Icons.camera_alt;
    if (name.contains('linkedin')) return Icons.work;
    if (name.contains('tiktok')) return Icons.music_note;
    if (name.contains('facebook')) return Icons.facebook;
    return Icons.public;
  }

  @override
  Widget build(BuildContext context) {
    final platformState = ref.watch(platformProvider);
    final dashboardState = ref.watch(dashboardProvider);

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () {
              ref.read(authProvider.notifier).logout();
              context.go('/login');
            },
            tooltip: 'Logout',
          ),
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
                  _buildTotalCard(platformState, dashboardState),
                  const SizedBox(height: 16),
                  _buildDateFilter(context),
                  const SizedBox(height: 24),
                  const Text('Platforms', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (platformState.isLoading)
                    LoadingSkeleton(height: 180, width: double.infinity)
                  else if (platformState.platforms.isEmpty)
                    const Center(child: Text('No platforms available.', style: TextStyle(color: Colors.grey)))
                  else
                    ...platformState.platforms.map((p) => _buildPlatformCard(p)),
                  const SizedBox(height: 32),
                  const Text('Recent Activity', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  _buildRecentActivity(dashboardState),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTotalCard(PlatformState platformState, DashboardState dashboardState) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [Colors.blue.shade700, Colors.blue.shade500]),
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('TOTAL SCHEDULED', style: TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text(dashboardState.totalScheduled.toString(), style: const TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold)), // Normally calculated
              ],
            ),
          ),
          Icon(Icons.calendar_month, size: 48, color: Colors.white.withOpacity(0.5)),
        ],
      ),
    );
  }

  Widget _buildDateFilter(BuildContext context) {
    final dateFormat = DateFormat('MMM d, yyyy');
    final fromStr = _fromDate != null ? dateFormat.format(_fromDate!) : 'Select from';
    final toStr = _toDate != null ? dateFormat.format(_toDate!) : 'Select to';

    return InkWell(
      onTap: () => _pickDateRange(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade300),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Date Range', style: TextStyle(fontSize: 10, color: Colors.grey, fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                Text('$fromStr  →  $toStr', style: const TextStyle(fontWeight: FontWeight.w600)),
              ],
            ),
            const Icon(Icons.date_range, color: Colors.blue),
          ],
        ),
      ),
    );
  }

  Widget _buildPlatformCard(Platform platform) {
    return _PlatformCardRef(
      platform: platform,
      fromDate: _fromDate,
      toDate: _toDate,
    );
  }

  Widget _buildRecentActivity(DashboardState dashboardState) {
    if (dashboardState.isLoading) return LoadingSkeleton(height: 100, width: double.infinity);
    if (dashboardState.recentSchedules.isEmpty) {
      return const Text('No recent activity.', style: TextStyle(color: Colors.grey));
    }

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: Colors.grey.shade200)),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: dashboardState.recentSchedules.length,
        separatorBuilder: (c, i) => const Divider(height: 1, indent: 48),
        itemBuilder: (context, index) {
           final schedule = dashboardState.recentSchedules[index];
           final platformName = schedule.channelName?.contains('(') == true
                ? schedule.channelName!.substring(schedule.channelName!.indexOf('(') + 1, schedule.channelName!.indexOf(')'))
                : 'default';
           final color = ContentTypeTranslator.getColor(schedule.contentType);

           return ListTile(
             leading: Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
             title: Text(schedule.title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
             subtitle: Text('@${schedule.channelHandle ?? 'unknown'}', style: TextStyle(fontSize: 12, color: Colors.blue.shade700)),
             trailing: Text(timeago.format(schedule.createdAt), style: const TextStyle(fontSize: 10, color: Colors.grey)),
           );
        },
      ),
    );
  }
}

class _PlatformCardRef extends ConsumerStatefulWidget {
  final Platform platform;
  final DateTime? fromDate;
  final DateTime? toDate;

  const _PlatformCardRef({required this.platform, this.fromDate, this.toDate});

  @override
  ConsumerState<_PlatformCardRef> createState() => _PlatformCardRefState();
}

class _PlatformCardRefState extends ConsumerState<_PlatformCardRef> {
  bool _isInit = false;

  @override
  void didUpdateWidget(covariant _PlatformCardRef oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isInit && (oldWidget.fromDate != widget.fromDate || oldWidget.toDate != widget.toDate)) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(platformAnalyticsProvider(widget.platform.id).notifier)
          ..setDateRange(widget.fromDate, widget.toDate)
          ..loadAll();
      });
    }
  }

  void _initGraphIfNeeded() {
    if (!_isInit) {
      _isInit = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(platformAnalyticsProvider(widget.platform.id).notifier)
          ..setDateRange(widget.fromDate, widget.toDate)
          ..loadAll();
      });
    }
  }

  IconData _getPlatformIcon(String name) {
    name = name.toLowerCase();
    if (name.contains('youtube')) return Icons.play_circle;
    if (name.contains('instagram')) return Icons.camera_alt;
    if (name.contains('linkedin')) return Icons.work;
    if (name.contains('tiktok')) return Icons.music_note;
    if (name.contains('facebook')) return Icons.facebook;
    return Icons.public;
  }

  @override
  Widget build(BuildContext context) {
    _initGraphIfNeeded();
    final analyticsState = ref.watch(platformAnalyticsProvider(widget.platform.id));
    final notifier = ref.read(platformAnalyticsProvider(widget.platform.id).notifier);

    Widget graphWidget;
    if (analyticsState.isLoading) {
      graphWidget = Padding(padding: const EdgeInsets.only(top: 16), child: LoadingSkeleton(height: 100, width: double.infinity));
    } else {
      switch (analyticsState.selectedGraph) {
        case 'Pie Chart':
          graphWidget = ContentMixDoughnut(data: analyticsState.contentMix, platformName: widget.platform.name);
          break;
        case 'Line Chart': // Actually workload is BarChart rotated, fallback for names.
          graphWidget = WorkloadBarChart(data: analyticsState.workload);
          break;
        case 'Bar Graph':
        default:
          graphWidget = PipelineBarChart(data: analyticsState.pipeline);
      }
    }

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // TOP: Platform Info
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Icon(_getPlatformIcon(widget.platform.name), size: 40, color: Colors.blue.shade800),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(widget.platform.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                      const SizedBox(height: 2),
                      Text('Platform Data Hub', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
                    ],
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 8)),
                  onPressed: () {
                     context.push('/admin/platforms/${widget.platform.id}/stats');
                  },
                  child: const Text('VIEW STATS ↗', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Colors.black12),
          // BOTTOM: Graph View
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Analytics Overview', style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.black54)),
                    DropdownButton<String>(
                      value: analyticsState.selectedGraph,
                      isDense: true,
                      underline: const SizedBox.shrink(),
                      style: const TextStyle(fontSize: 12, color: Colors.black87, fontWeight: FontWeight.w500),
                      items: const [
                        DropdownMenuItem(value: 'Bar Graph', child: Text('Pipeline')),
                        DropdownMenuItem(value: 'Pie Chart', child: Text('Content Mix')),
                        DropdownMenuItem(value: 'Line Chart', child: Text('Workload')),
                      ],
                      onChanged: (val) {
                        if (val != null) notifier.setGraph(val);
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                SizedBox(
                  height: 220,
                  width: double.infinity,
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
