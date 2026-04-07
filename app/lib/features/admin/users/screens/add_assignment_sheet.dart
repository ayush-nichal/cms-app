import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../platforms/providers/platform_provider.dart';
import '../providers/user_provider.dart';
import '../data/user_model.dart';

class AddAssignmentSheet extends ConsumerStatefulWidget {
  final AppUser user;

  const AddAssignmentSheet({super.key, required this.user});

  @override
  ConsumerState<AddAssignmentSheet> createState() => _AddAssignmentSheetState();
}

class _AddAssignmentSheetState extends ConsumerState<AddAssignmentSheet> {
  bool _isSubmitting = false;

  void _assignChannel(String channelId) async {
    setState(() => _isSubmitting = true);
    try {
      await ref.read(userProvider.notifier).addAssignment(widget.user.id, channelId);
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Assignment added')));
      }
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final platformState = ref.watch(platformProvider);
    final platformNotifier = ref.read(platformProvider.notifier);
    
    final assignedChannelIds = widget.user.assignments.map((a) => a.channelId).toSet();

    return Container(
      padding: const EdgeInsets.only(top: 16),
      child: Column(
        children: [
          Text('Select Channel to Assign', style: Theme.of(context).textTheme.titleLarge),
          const Divider(),
          if (_isSubmitting) const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()),
          Expanded(
            child: platformState.isLoading && platformState.platforms.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : ListView.builder(
                    itemCount: platformState.platforms.length,
                    itemBuilder: (context, index) {
                      final platform = platformState.platforms[index];
                      final channels = platformState.channelsByPlatformId[platform.id];

                      return ExpansionTile(
                        title: Text(platform.name),
                        onExpansionChanged: (expanded) {
                          if (expanded && channels == null) platformNotifier.loadChannels(platform.id);
                        },
                        children: (channels == null)
                            ? [const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())]
                            : channels.map((c) {
                                final isAssigned = assignedChannelIds.contains(c.id);
                                return ListTile(
                                  leading: Icon(isAssigned ? Icons.check_circle : Icons.tv, color: isAssigned ? Colors.green : null),
                                  title: Text(c.name, style: TextStyle(color: isAssigned ? Colors.grey : null)),
                                  subtitle: Text(c.handle),
                                  onTap: isAssigned || _isSubmitting ? null : () => _assignChannel(c.id),
                                );
                              }).toList(),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
