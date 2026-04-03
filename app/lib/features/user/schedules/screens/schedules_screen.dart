import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../auth/providers/auth_provider.dart';
import '../providers/schedule_provider.dart';
import '../../shared/widgets/schedule_card.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/loading_skeleton.dart';

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
    
    final selectedAssignment = user.assignments.firstWhere(
      (a) => a.channelId == selectedChannelId, 
      orElse: () => user.assignments.first
    );
    final isCreator = selectedAssignment.role == 'creator';
    
    final schedules = scheduleState.schedulesByChannel[selectedChannelId] ?? [];
    final isLoading = scheduleState.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Schedules'),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(50),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            child: Row(
              children: user.assignments.map((assignment) {
                final isSelected = assignment.channelId == selectedChannelId;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: ChoiceChip(
                    label: Text(assignment.channelName),
                    selected: isSelected,
                    onSelected: (selected) {
                      if (selected) notifier.selectChannel(assignment.channelId);
                    },
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
      body: isLoading && schedules.isEmpty
          ? const SkeletonList()
          : RefreshIndicator(
              onRefresh: () => notifier.loadSchedules(selectedChannelId),
              child: schedules.isEmpty
                  ? ListView(
                      children: [
                        const SizedBox(height: 50),
                        EmptyState.noSchedules(isCreator ? () => context.push('/user/schedules/new', extra: selectedChannelId) : null),
                      ],
                    )
                  : ListView.builder(
                      controller: _scrollController,
                      itemCount: schedules.length + (scheduleState.isLoadMore ? 1 : 0),
                      itemBuilder: (context, index) {
                        if (index == schedules.length) {
                          return const Padding(
                            padding: EdgeInsets.all(16.0),
                            child: Center(child: CircularProgressIndicator()),
                          );
                        }
                        
                        final schedule = schedules[index];
                        final card = ScheduleCard(
                          schedule: schedule,
                          onTap: () => context.push('/user/schedules/${schedule.id}', extra: {'schedule': schedule, 'isCreator': isCreator}),
                        );

                        if (!isCreator) return card;

                        return Dismissible(
                          key: Key(schedule.id),
                          direction: DismissDirection.endToStart,
                          background: Container(
                            color: Colors.red,
                            alignment: Alignment.centerRight,
                            padding: const EdgeInsets.only(right: 16),
                            child: const Icon(Icons.delete, color: Colors.white),
                          ),
                          onDismissed: (_) {
                            notifier.deleteSchedule(schedule.id, selectedChannelId).catchError((e) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
                            });
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: const Text('Schedule deleted'),
                                action: SnackBarAction(
                                  label: 'Dismiss',
                                  onPressed: () {},
                                ),
                              )
                            );
                          },
                          child: card,
                        );
                      },
                    ),
            ),
      floatingActionButton: isCreator
          ? FloatingActionButton(
              onPressed: () => context.push('/user/schedules/new', extra: selectedChannelId),
              child: const Icon(Icons.add),
            )
          : null,
    );
  }
}
