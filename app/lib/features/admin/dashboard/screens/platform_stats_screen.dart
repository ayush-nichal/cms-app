import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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

    return Scaffold(
      appBar: AppBar(
        title: Text('${widget.platformName} Stats'),
      ),
      body: state.isLoading && state.selectedPlatformStats == null
          ? const Center(child: CircularProgressIndicator())
          : state.error != null
              ? Center(child: Text(state.error!))
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: state.selectedPlatformStats?.length ?? 0,
                  itemBuilder: (context, index) {
                    final channel = state.selectedPlatformStats![index];
                    return ChannelStatCard(channel: channel);
                  },
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
            Text('@${channel.handle}', style: TextStyle(color: Colors.grey.shade600, fontSize: 13)),
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
