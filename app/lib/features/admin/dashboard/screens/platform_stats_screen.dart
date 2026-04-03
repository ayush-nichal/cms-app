import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../user/schedules/data/schedule_model.dart';
import '../../../user/shared/widgets/status_chip.dart';
import '../providers/stats_provider.dart';
import '../data/stats_model.dart';

class PlatformStatsScreen extends ConsumerStatefulWidget {
  final String platformId;
  final String platformName;

  const PlatformStatsScreen({super.key, required this.platformId, required this.platformName});

  @override
  ConsumerState<PlatformStatsScreen> createState() => _PlatformStatsScreenState();
}

class _PlatformStatsScreenState extends ConsumerState<PlatformStatsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(statsProvider.notifier).loadPlatformStats(widget.platformId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(statsProvider);
    final schedulesAsync = ref.watch(platformSchedulesProvider(widget.platformId));

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.platformName} Stats'),
      ),
      body: state.isLoading && state.selectedPlatformStats == null
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(child: Text(state.error!))
              : RefreshIndicator(
                  onRefresh: () async {
                    ref.read(statsProvider.notifier).loadPlatformStats(widget.platformId);
                    ref.invalidate(platformSchedulesProvider(widget.platformId));
                  },
                  child: CustomScrollView(
                    slivers: [
                      if (state.selectedPlatformStats != null && state.selectedPlatformStats!.isNotEmpty) ...[
                        const SliverToBoxAdapter(
                          child: Padding(
                            padding: EdgeInsets.fromLTRB(16, 16, 16, 8),
                            child: Text('Channel Statistics', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          ),
                        ),
                        SliverPadding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate(
                              (context, index) {
                                final channel = state.selectedPlatformStats![index];
                                return ChannelStatCard(channel: channel);
                              },
                              childCount: state.selectedPlatformStats!.length,
                            ),
                          ),
                        ),
                      ],
                      const SliverToBoxAdapter(
                        child: Padding(
                          padding: EdgeInsets.fromLTRB(16, 24, 16, 8),
                          child: Text('Scheduled Posts', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                        ),
                      ),
                      schedulesAsync.when(
                        data: (schedules) {
                          if (schedules.isEmpty) {
                            return const SliverToBoxAdapter(
                              child: Padding(
                                padding: EdgeInsets.all(32),
                                child: Center(child: Text('No scheduled posts found.', style: TextStyle(color: Colors.grey))),
                              ),
                            );
                          }
                          return SliverPadding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            sliver: SliverList(
                              delegate: SliverChildBuilderDelegate(
                                (context, index) {
                                  final s = schedules[index];
                                  return Card(
                                    margin: const EdgeInsets.only(bottom: 8),
                                    child: ListTile(
                                      title: Text(s.title, style: const TextStyle(fontWeight: FontWeight.w600)),
                                      subtitle: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          const SizedBox(height: 4),
                                          if (s.channelName != null) 
                                            Row(
                                              children: [
                                                const Icon(Icons.account_circle, size: 14, color: Colors.grey),
                                                const SizedBox(width: 4),
                                                Expanded(
                                                  child: Text(
                                                    '${s.channelName} (${(s.channelHandle ?? '').startsWith('@') ? s.channelHandle : '@${s.channelHandle}'})'.replaceAll('(@null)', '').replaceAll(' ()', ''),
                                                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                                                    overflow: TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          if (s.channelName != null) const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(Icons.access_time, size: 14, color: Colors.grey),
                                              const SizedBox(width: 4),
                                              Text(DateFormat('MMM d, y h:mm a').format(s.scheduledAt), style: const TextStyle(fontSize: 13, color: Colors.grey)),
                                            ],
                                          ),
                                          const SizedBox(height: 4),
                                          Row(
                                            children: [
                                              const Icon(Icons.person, size: 14, color: Colors.grey),
                                              const SizedBox(width: 4),
                                              Text(s.creatorName ?? s.createdById, style: const TextStyle(fontSize: 13, color: Colors.grey)),
                                            ],
                                          ),
                                        ],
                                      ),
                                      trailing: StatusChip(status: s.status),
                                    ),
                                  );
                                },
                                childCount: schedules.length,
                              ),
                            ),
                          );
                        },
                        loading: () => const SliverToBoxAdapter(child: Center(child: Padding(padding: EdgeInsets.all(32.0), child: CircularProgressIndicator()))),
                        error: (err, stack) => SliverToBoxAdapter(child: Center(child: Padding(padding: const EdgeInsets.all(32.0), child: Text('Failed to load posts: $err', style: const TextStyle(color: Colors.red))))),
                      ),
                      const SliverPadding(padding: EdgeInsets.only(bottom: 32)),
                    ],
                  ),
                ),
    );
  }
}

class ChannelStatCard extends StatelessWidget {
  final ChannelStat channel;

  const ChannelStatCard({super.key, required this.channel});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(channel.channelName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
            Text(channel.handle.startsWith('@') ? channel.handle : '@${channel.handle}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _CompactStatChip(label: 'Scheduled', count: channel.scheduled, color: Colors.blue),
                _CompactStatChip(label: 'Posted', count: channel.posted, color: Colors.green),
                _CompactStatChip(label: 'Not Posted', count: channel.notPosted, color: Colors.red),
              ],
            ),
            const SizedBox(height: 8),
            Center(child: Text('Total: ${channel.total}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold))),
          ],
        ),
      ),
    );
  }
}

class _CompactStatChip extends StatelessWidget {
  final String label;
  final int count;
  final MaterialColor color;

  const _CompactStatChip({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(label, style: TextStyle(fontSize: 10, color: color.shade800)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(color: color.shade100, borderRadius: BorderRadius.circular(12)),
          child: Text('$count', style: TextStyle(fontWeight: FontWeight.bold, color: color.shade900)),
        ),
      ],
    );
  }
}
