import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/stats_provider.dart';
import '../data/stats_model.dart';
import 'package:intl/intl.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(statsProvider.notifier).loadOverview();
    });
  }

  Future<void> _selectDate(BuildContext context, bool isFrom) async {
    final state = ref.read(statsProvider);
    final initialDate = isFrom ? state.from ?? DateTime.now() : state.to ?? DateTime.now();
    
    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    
    if (picked != null) {
      if (isFrom) {
        ref.read(statsProvider.notifier).setDateRange(picked, state.to);
      } else {
        ref.read(statsProvider.notifier).setDateRange(state.from, picked);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(statsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
      ),
      body: RefreshIndicator(
        onRefresh: () => ref.read(statsProvider.notifier).loadOverview(),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header Row
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.blue.shade50,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.blue.shade100),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text(
                            'Total Schedules\n(Selected Range)',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          Text(
                            '${state.overview?.totalAcrossAll ?? 0}',
                            style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.blue),
                          )
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Date Filter Row
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectDate(context, true),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'From',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              child: Text(
                                state.from != null ? DateFormat('yyyy-MM-dd').format(state.from!) : 'All time',
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InkWell(
                            onTap: () => _selectDate(context, false),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'To',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              child: Text(
                                state.to != null ? DateFormat('yyyy-MM-dd').format(state.to!) : 'All time',
                              ),
                            ),
                          ),
                        ),
                        if (state.from != null || state.to != null) ...[
                          const SizedBox(width: 8),
                          IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => ref.read(statsProvider.notifier).setDateRange(null, null),
                          )
                        ]
                      ],
                    ),
                  ],
                ),
              ),
            ),
            if (state.isLoading && state.overview == null)
              const SliverFillRemaining(child: Center(child: CircularProgressIndicator()))
            else if (state.error != null)
              SliverFillRemaining(child: Center(child: Text(state.error!)))
            else if (state.overview != null)
              SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16.0),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final platform = state.overview!.platforms[index];
                      return PlatformStatCard(platform: platform);
                    },
                    childCount: state.overview!.platforms.length,
                  ),
                ),
              )
          ],
        ),
      ),
    );
  }
}

class PlatformStatCard extends StatelessWidget {
  final PlatformStat platform;

  const PlatformStatCard({super.key, required this.platform});

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        onTap: () => context.push('/admin/platforms/${platform.platformId}/stats', extra: platform.platformName),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(platform.platformName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _StatChip(label: 'Scheduled', count: platform.scheduled, color: Colors.blue),
                  _StatChip(label: 'Posted', count: platform.posted, color: Colors.green),
                  _StatChip(label: 'Not Posted', count: platform.notPosted, color: Colors.red),
                ],
              ),
              const SizedBox(height: 12),
              Center(
                child: Text('Total: ${platform.total}', style: TextStyle(color: Colors.grey.shade600, fontWeight: FontWeight.w500)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  final String label;
  final int count;
  final MaterialColor color;

  const _StatChip({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.shade200),
      ),
      child: Column(
        children: [
          Text(label, style: TextStyle(fontSize: 11, color: color.shade900, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text('$count', style: TextStyle(fontSize: 16, color: color.shade700, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
