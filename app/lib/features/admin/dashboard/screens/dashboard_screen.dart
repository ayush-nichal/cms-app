import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;
import 'package:intl/intl.dart';

import '../providers/dashboard_provider.dart';
import '../providers/stats_provider.dart';
import '../data/stats_model.dart';
import '../../analytics/providers/analytics_provider.dart';
import '../../analytics/widgets/pipeline_bar_chart.dart';
import '../../analytics/widgets/workload_bar_chart.dart';
import '../../analytics/widgets/content_mix_doughnut.dart';
import '../../../../features/auth/providers/auth_provider.dart';
import '../../../../shared/design/design_tokens.dart';
import '../widgets/schedule_details_dialog.dart';

String getPlatformSubtitle(String platformName) {
  final name = platformName.toLowerCase();
  if (name.contains('youtube')) return 'Videos ready for release';
  if (name.contains('instagram')) return 'Posts and Reels pending';
  if (name.contains('linkedin')) return 'Professional updates queued';
  return 'Content ready for publish';
}

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  DateTime? _fromDate;
  DateTime? _toDate;
  String _searchQuery = '';
  final _searchController = TextEditingController();

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadData();
    });
  }

  Future<void> _loadData() async {
    ref.read(statsProvider.notifier).loadOverview();
    ref.read(dashboardProvider.notifier).loadRecentSchedules(from: _fromDate, to: _toDate);
  }

  Future<void> _selectDate(BuildContext context, bool isFrom) async {
    final current = isFrom ? _fromDate : _toDate;
    final picked = await showDatePicker(
      context: context,
      initialDate: current ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(primary: primary),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        if (isFrom) {
          _fromDate = picked;
        } else {
          _toDate = picked;
        }
      });
      _loadData();
    }
  }

  @override
  Widget build(BuildContext context) {
    final statsState = ref.watch(statsProvider);
    final dashboardState = ref.watch(dashboardProvider);
    final isLoading = statsState.isLoading || dashboardState.isLoading;
    final platforms = statsState.overview?.platforms ?? [];
    
    // Total Scheduled — use overview totalAcrossAll which counts all schedules correctly,
    // falling back to dashboardState.totalScheduled
    final int totalCount = statsState.overview?.totalAcrossAll ?? dashboardState.totalScheduled;

    final recentSchedules = dashboardState.recentSchedules;
    final filteredSchedules = recentSchedules.where((item) {
      final query = _searchQuery.toLowerCase();
      return item.title.toLowerCase().contains(query) || 
             (item.channelName?.toLowerCase().contains(query) ?? false);
    }).toList();

    return Scaffold(
      backgroundColor: surface,
      appBar: AppBar(
        backgroundColor: surface,
        elevation: 0,
        title: Text(
          'Admin Dashboard',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: onSurface,
          ),
        ),
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded, color: onSurfaceVar),
          onPressed: () {},
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout_rounded, color: onSurfaceVar),
            onPressed: () {
              ref.read(authProvider.notifier).logout();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        color: primary,
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              
              // 1. Total Scheduled Card
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Color(0xFF005DAC), Color(0xFF1976D2)],
                  ),
                  boxShadow: const [
                    BoxShadow(color: Color(0x0A191C1D), blurRadius: 32, offset: Offset(0, 12))
                  ],
                ),
                child: Stack(
                  children: [
                    Positioned(
                      right: 12,
                      bottom: -15, // Decorative offset
                      child: Icon(
                        Icons.calendar_month_rounded,
                        size: 100, // Adjusted size to fit well
                        color: Colors.white.withOpacity(0.15),
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'TOTAL SCHEDULED',
                            style: GoogleFonts.epilogue(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                              letterSpacing: 11 * 0.08,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                '$totalCount',
                                style: GoogleFonts.publicSans(
                                    fontSize: 48,
                                    fontWeight: FontWeight.w700,
                                    color: Colors.white,
                                  ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                'Posts',
                                style: GoogleFonts.publicSans(
                                    fontSize: 20,
                                    fontWeight: FontWeight.w400,
                                    color: Colors.white,
                                  ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // 2. Date Range Filter
              Row(
                children: [
                  Expanded(
                    child: _buildDateInput(
                      label: 'FROM',
                      value: _fromDate,
                      onTap: () => _selectDate(context, true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildDateInput(
                      label: 'TO',
                      value: _toDate,
                      onTap: () => _selectDate(context, false),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // 3. Platform Cards
              if (isLoading && platforms.isEmpty)
                _buildLoadingSkeleton()
              else ...[
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: platforms.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 16),
                  itemBuilder: (context, index) {
                    final stat = platforms[index];
                    return _PlatformCard(
                      stat: stat,
                      fromDate: _fromDate,
                      toDate: _toDate,
                    );
                  },
                ),
              ],
              
              const SizedBox(height: 20),

              // 4. Recent Activity Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Recent Activity',
                    style: GoogleFonts.publicSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: onSurface,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              
              // Search Bar
              Container(
                decoration: BoxDecoration(
                  color: surfaceWhite,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: const [
                    BoxShadow(color: Color(0x05191C1D), blurRadius: 20, offset: Offset(0, 4)),
                  ],
                ),
                child: TextField(
                  controller: _searchController,
                  onChanged: (value) => setState(() => _searchQuery = value),
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, color: onSurface),
                  decoration: InputDecoration(
                    hintText: 'Search posts by title or channel...',
                    hintStyle: GoogleFonts.plusJakartaSans(fontSize: 14, color: onSurfaceVar.withOpacity(0.5)),
                    prefixIcon: const Icon(Icons.search_rounded, color: onSurfaceVar, size: 20),
                    suffixIcon: _searchQuery.isNotEmpty 
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        ) 
                      : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              
              if (dashboardState.isLoading && recentSchedules.isEmpty)
                _buildActivitySkeleton()
              else if (recentSchedules.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: Text(
                    'No recent activity',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: onSurfaceVar,
                    ),
                  ),
                )
              else if (filteredSchedules.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      'No results found for "$_searchQuery"',
                      style: GoogleFonts.plusJakartaSans(fontSize: 14, color: onSurfaceVar),
                    ),
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: filteredSchedules.length > 5 ? 5 : filteredSchedules.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 4),
                  itemBuilder: (context, index) {
                    final item = filteredSchedules[index];
                    final colors = [
                      const Color(0xFF005DAC),
                      const Color(0xFFF58529),
                      const Color(0xFFFF4B4B),
                      const Color(0xFF69C9D0),
                      const Color(0xFF8134AF),
                    ];
                    final dotColor = colors[index % colors.length];

                    return InkWell(
                      onTap: () {
                        showDialog(
                          context: context,
                          builder: (_) => ScheduleDetailsDialog(schedule: item),
                        );
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              margin: const EdgeInsets.only(top: 4),
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: dotColor,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    item.title.isNotEmpty ? item.title : '${item.channelName ?? "Asset"} processed',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w400,
                                      color: onSurface,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    timeago.format(item.createdAt),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w400,
                                      color: onSurfaceVar,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const Icon(Icons.chevron_right_rounded, size: 18, color: onSurfaceVar),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              
              if (recentSchedules.isNotEmpty) ...[
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () => context.push('/admin/schedules'),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
                      backgroundColor: const Color(0xFFF0F5FA),
                    ),
                    child: Text(
                      'View all scheduled posts',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF005DAC),
                      ),
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDateInput({required String label, required DateTime? value, required VoidCallback onTap}) {
    final dateFormat = DateFormat('MM/dd/yyyy');
    final text = value == null ? '' : dateFormat.format(value);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.epilogue(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            letterSpacing: 11 * 0.05,
            color: onSurfaceVar,
          ),
        ),
        const SizedBox(height: 8),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: IgnorePointer(
            child: TextFormField(
              controller: TextEditingController(text: text),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: onSurface,
              ),
              decoration: InputDecoration(
                filled: true,
                fillColor: surfaceWhite,
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                suffixIcon: const Icon(Icons.calendar_today_outlined, color: onSurfaceVar, size: 20),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0x66C1C6D4)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Color(0x66C1C6D4)),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingSkeleton() {
    return Column(
      children: List.generate(3, (index) => Container(
        height: 180,
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: surfaceWhite,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
             BoxShadow(color: Color(0x0A191C1D), blurRadius: 32, offset: Offset(0, 12))
          ],
        ),
        child: const Center(child: CircularProgressIndicator(color: outlineGhost)),
      )),
    );
  }

  Widget _buildActivitySkeleton() {
    return Column(
      children: List.generate(3, (index) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            SizedBox(width: 8, height: 8, child: DecoratedBox(decoration: BoxDecoration(color: outlineGhost, shape: BoxShape.circle))),
            SizedBox(width: 12),
            Expanded(child: SizedBox(height: 14, child: DecoratedBox(decoration: BoxDecoration(color: outlineGhost)))),
          ],
        ),
      )),
    );
  }
}

enum ChartType { pipeline, workload, contentMix }

class _PlatformCard extends ConsumerStatefulWidget {
  final PlatformStat stat;
  final DateTime? fromDate;
  final DateTime? toDate;

  const _PlatformCard({
    required this.stat,
    this.fromDate,
    this.toDate,
  });

  @override
  ConsumerState<_PlatformCard> createState() => _PlatformCardState();
}

class _PlatformCardState extends ConsumerState<_PlatformCard> {
  ChartType _currentChart = ChartType.pipeline;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(platformAnalyticsProvider(widget.stat.platformId).notifier)
         .setDateRange(widget.fromDate, widget.toDate);
    });
  }

  @override
  void didUpdateWidget(_PlatformCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.fromDate != oldWidget.fromDate || widget.toDate != oldWidget.toDate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ref.read(platformAnalyticsProvider(widget.stat.platformId).notifier)
           .setDateRange(widget.fromDate, widget.toDate);
      });
    }
  }

  void _cycleNext() {
    setState(() {
      _currentChart = ChartType.values[(_currentChart.index + 1) % ChartType.values.length];
    });
  }

  void _cyclePrev() {
    setState(() {
      _currentChart = ChartType.values[(_currentChart.index - 1 + ChartType.values.length) % ChartType.values.length];
    });
  }

  String get _chartLabel {
    switch (_currentChart) {
      case ChartType.pipeline: return 'PIPELINE';
      case ChartType.workload: return 'WORKLOAD';
      case ChartType.contentMix: return 'CONTENT MIX';
    }
  }

  @override
  Widget build(BuildContext context) {
    final analyticsState = ref.watch(platformAnalyticsProvider(widget.stat.platformId));

    Widget chartWidget;
    if (analyticsState.isLoading) {
      chartWidget = const Center(child: CircularProgressIndicator(color: Colors.white));
    } else {
      switch (_currentChart) {
        case ChartType.pipeline:
          chartWidget = analyticsState.pipeline.isEmpty
              ? Center(child: Text('No pipeline data', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.white70)))
              : PipelineBarChart(data: analyticsState.pipeline);
          break;
        case ChartType.workload:
          chartWidget = analyticsState.workload.isEmpty
              ? Center(child: Text('No workload data', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.white70)))
              : WorkloadBarChart(data: analyticsState.workload);
          break;
        case ChartType.contentMix:
          chartWidget = analyticsState.contentMix.isEmpty
              ? Center(child: Text('No content mix data', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: Colors.white70)))
              : ContentMixDoughnut(data: analyticsState.contentMix, platformName: widget.stat.platformName);
          break;
      }
    }

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        gradient: getPlatformGradient(widget.stat.platformName),
        boxShadow: const [
          BoxShadow(color: Color(0x0A191C1D), blurRadius: 32, offset: Offset(0, 12))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // TOP ROW
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        getPlatformIcon(widget.stat.platformName),
                        color: Colors.white,
                        size: 28,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        widget.stat.platformName,
                        style: GoogleFonts.publicSans(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                  InkWell(
                    onTap: () {
                      context.push('/admin/platforms/${widget.stat.platformId}/stats');
                    },
                    borderRadius: BorderRadius.circular(9999),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.white.withOpacity(0.6)),
                        borderRadius: BorderRadius.circular(9999),
                      ),
                      child: Text(
                        'STATS ↗',
                        style: GoogleFonts.epilogue(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                          letterSpacing: 10 * 0.05,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // MIDDLE ROW
              Text(
                '${widget.stat.total} scheduled',
                style: GoogleFonts.publicSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
              Text(
                getPlatformSubtitle(widget.stat.platformName),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: Colors.white.withOpacity(0.75),
                ),
              ),
              const SizedBox(height: 16),

              // GRAPH SECTION
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left, color: Colors.white),
                    onPressed: _cyclePrev,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    _chartLabel,
                    style: GoogleFonts.epilogue(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                      letterSpacing: 11 * 0.05,
                    ),
                  ),
                  const SizedBox(width: 16),
                  IconButton(
                    icon: const Icon(Icons.chevron_right, color: Colors.white),
                    onPressed: _cycleNext,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Real Graph container
              Container(
                constraints: const BoxConstraints(minHeight: 140),
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                padding: const EdgeInsets.all(12),
                child: chartWidget,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
