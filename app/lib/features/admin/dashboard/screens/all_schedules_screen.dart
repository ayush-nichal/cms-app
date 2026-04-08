import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import '../providers/admin_schedules_provider.dart';
import '../widgets/schedule_details_dialog.dart';

class AllSchedulesScreen extends ConsumerWidget {
  const AllSchedulesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminSchedulesProvider);
    final notifier = ref.read(adminSchedulesProvider.notifier);

    const surfaceWhite = Color(0xFFFFFFFF);
    const surfaceLow = Color(0xFFF7F9FC);
    const onSurface = Color(0xFF191C1D);
    const onSurfaceVar = Color(0xFF40484B);
    const primaryBlue = Color(0xFF005DAC);
    const errorRed = Color(0xFFBA1A1A);

    return Scaffold(
      backgroundColor: surfaceLow,
      appBar: AppBar(
        backgroundColor: surfaceWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'All Scheduled Posts',
          style: GoogleFonts.publicSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: onSurface,
          ),
        ),
        actions: [
          if (state.selectedPlatformId != null || state.selectedChannelId != null || state.searchQuery.isNotEmpty)
            TextButton(
              onPressed: () => notifier.clearFilters(),
              child: Text(
                'Clear all',
                style: GoogleFonts.plusJakartaSans(
                  color: primaryBlue,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          // 1) Search and Static Header
          Container(
            color: surfaceWhite,
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            child: Column(
              children: [
                TextField(
                  onChanged: (val) => notifier.setSearch(val),
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, color: onSurface),
                  decoration: InputDecoration(
                    hintText: 'Search scheduled posts...',
                    hintStyle: GoogleFonts.plusJakartaSans(color: onSurfaceVar.withOpacity(0.6)),
                    prefixIcon: const Icon(Icons.search_rounded, size: 20, color: onSurfaceVar),
                    filled: true,
                    fillColor: surfaceLow,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                
                // 2) Platform Filter
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      _buildFilterChip(
                        label: 'All Platforms',
                        isSelected: state.selectedPlatformId == null,
                        onTap: () => notifier.setPlatform(null),
                      ),
                      if (state.isFiltersLoading && state.platforms.isEmpty)
                       const Padding(
                         padding: EdgeInsets.symmetric(horizontal: 12),
                         child: Center(child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))),
                       )
                      else
                        ...state.platforms.map((p) => _buildFilterChip(
                          label: p.name,
                          isSelected: state.selectedPlatformId == p.id,
                          onTap: () => notifier.setPlatform(p.id),
                        )),
                    ],
                  ),
                ),
                
                // 3) Channel Filter (Visible only when platform is selected)
                if (state.selectedPlatformId != null) ...[
                  const SizedBox(height: 12),
                  SizedBox(
                    height: 32,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        _buildSubFilterChip(
                          label: 'All Channels',
                          isSelected: state.selectedChannelId == null,
                          onTap: () => notifier.setChannel(null),
                        ),
                        if (state.isFiltersLoading)
                          const Padding(
                            padding: EdgeInsets.symmetric(horizontal: 12),
                            child: Center(child: SizedBox(width: 12, height: 12, child: CircularProgressIndicator(strokeWidth: 2))),
                          )
                        else
                          ...state.channels.map((c) => _buildSubFilterChip(
                            label: c.name,
                            isSelected: state.selectedChannelId == c.id,
                            onTap: () => notifier.setChannel(c.id),
                          )),
                      ],
                    ),
                  ),
                ],
              ],
            ),
          ),
          
          // 4) Results List
          Expanded(
            child: state.isLoading && state.schedules.isEmpty
                ? const Center(child: CircularProgressIndicator(color: primaryBlue))
                : state.error != null
                    ? _buildErrorPlaceholder(state.error!, () => notifier.loadSchedules())
                    : state.schedules.isEmpty
                        ? _buildEmptyPlaceholder()
                        : RefreshIndicator(
                            onRefresh: () => notifier.loadSchedules(),
                            child: ListView.separated(
                              padding: const EdgeInsets.all(16),
                              itemCount: state.schedules.length + (state.isLoading ? 1 : 0),
                              separatorBuilder: (_, __) => const SizedBox(height: 12),
                              itemBuilder: (context, index) {
                                if (index >= state.schedules.length) {
                                  return const Center(child: Padding(
                                    padding: EdgeInsets.all(8.0),
                                    child: CircularProgressIndicator(),
                                  ));
                                }
                                final item = state.schedules[index];
                                return _ScheduleListCard(schedule: item);
                              },
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({required String label, required bool isSelected, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: ChoiceChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onTap(),
        selectedColor: const Color(0xFF005DAC),
        backgroundColor: Colors.transparent,
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
          color: isSelected ? Colors.white : const Color(0xFF40484B),
        ),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: BorderSide(
            color: isSelected ? Colors.transparent : const Color(0xFFC1C6D4).withOpacity(0.5),
          ),
        ),
        showCheckmark: false,
      ),
    );
  }

  Widget _buildSubFilterChip({required String label, required bool isSelected, required VoidCallback onTap}) {
    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFE0E3E3) : Colors.transparent,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: isSelected ? Colors.transparent : const Color(0xFFC1C6D4).withOpacity(0.3)),
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? const Color(0xFF191C1D) : const Color(0xFF40484B),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyPlaceholder() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.event_busy_rounded, size: 48, color: const Color(0xFF40484B).withOpacity(0.2)),
          const SizedBox(height: 16),
          Text(
            'No scheduled posts found',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: const Color(0xFF40484B),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorPlaceholder(String error, VoidCallback onRetry) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline_rounded, color: Color(0xFFBA1A1A), size: 32),
            const SizedBox(height: 12),
            Text(error, textAlign: TextAlign.center, style: GoogleFonts.plusJakartaSans(fontSize: 13)),
            const SizedBox(height: 16),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _ScheduleListCard extends StatelessWidget {
  final dynamic schedule; // Using dynamic to avoid rigid cast if models differ slightly between layers
  
  const _ScheduleListCard({required this.schedule});

  @override
  Widget build(BuildContext context) {
    final dateFormat = DateFormat('MMM dd, yyyy • hh:mm a');
    final scheduledDate = schedule.scheduledAt;
    final isPast = scheduledDate.isBefore(DateTime.now());

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: const [
          BoxShadow(color: Color(0x08191C1D), blurRadius: 24, offset: Offset(0, 8))
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            showDialog(
              context: context,
              builder: (ctx) => ScheduleDetailsDialog(schedule: schedule),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF0F5FA),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        schedule.platformName?.toUpperCase() ?? 'SOCIAL',
                        style: GoogleFonts.epilogue(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF005DAC),
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        schedule.channelName ?? 'Auto Channel',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: const Color(0xFF40484B),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    _StatusPill(isPast: isPast),
                  ],
                ),
                const SizedBox(height: 12),
                Text(
                  schedule.title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF191C1D),
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Icon(Icons.access_time_rounded, size: 14, color: Color(0xFF40484B)),
                    const SizedBox(width: 6),
                    Text(
                      dateFormat.format(scheduledDate),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: const Color(0xFF40484B),
                      ),
                    ),
                  ],
                ),
                if (schedule.creatorName != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Created by: ${schedule.creatorName}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: const Color(0xFF40484B).withOpacity(0.6),
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final bool isPast;
  const _StatusPill({required this.isPast});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: isPast ? const Color(0xFFE0E3E3).withOpacity(0.5) : const Color(0xFFE8F5E9),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        isPast ? 'COMPLETED' : 'SCHEDULED',
        style: GoogleFonts.epilogue(
          fontSize: 8,
          fontWeight: FontWeight.w700,
          color: isPast ? const Color(0xFF40484B) : const Color(0xFF2E7D32),
        ),
      ),
    );
  }
}
