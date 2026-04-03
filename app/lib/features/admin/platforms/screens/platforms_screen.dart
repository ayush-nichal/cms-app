import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../providers/platform_provider.dart';
import '../data/platform_model.dart';
import '../../../../shared/widgets/confirm_dialog.dart';

class PlatformsScreen extends ConsumerWidget {
  const PlatformsScreen({super.key});

  void _showPlatformBottomSheet(BuildContext context, WidgetRef ref, Platform platform) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.add),
              title: const Text('Add Channel'),
              onTap: () {
                Navigator.pop(context);
                context.push('/admin/channels/new', extra: platform);
              },
            ),
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Platform'),
              onTap: () {
                Navigator.pop(context);
                context.push('/admin/platforms/edit', extra: platform);
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Platform', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => const ConfirmDialog(
                    title: 'Delete Platform',
                    message: 'Are you sure you want to delete this platform? If channels exist under it, it will fail.',
                    confirmText: 'Delete',
                  ),
                );
                if (confirm == true) {
                  try {
                    await ref.read(platformProvider.notifier).deletePlatform(platform.id);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                      );
                    }
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showChannelBottomSheet(BuildContext context, WidgetRef ref, Platform platform, Channel channel) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.edit),
              title: const Text('Edit Channel'),
              onTap: () {
                Navigator.pop(context);
                context.push('/admin/channels/edit', extra: {'platform': platform, 'channel': channel});
              },
            ),
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text('Delete Channel', style: TextStyle(color: Colors.red)),
              onTap: () async {
                Navigator.pop(context);
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => const ConfirmDialog(
                    title: 'Delete Channel',
                    message: 'Are you sure you want to delete this channel? If users are assigned to it, it will fail.',
                    confirmText: 'Delete',
                  ),
                );
                if (confirm == true) {
                  try {
                    await ref.read(platformProvider.notifier).deleteChannel(channel.id, platform.id);
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
                      );
                    }
                  }
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(platformProvider);
    final notifier = ref.read(platformProvider.notifier);

    return Scaffold(
      body: state.isLoading && state.platforms.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : state.platforms.isEmpty
              ? const Center(
                  child: Text(
                    'No platforms yet.\nTap + to add one.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 16, color: Colors.grey),
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => notifier.loadPlatforms(),
                  child: ListView.builder(
                    itemCount: state.platforms.length,
                    itemBuilder: (context, index) {
                      final platform = state.platforms[index];
                      final channels = state.channelsByPlatformId[platform.id];

                      return Card(
                        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        child: ExpansionTile(
                          title: GestureDetector(
                            onLongPress: () => _showPlatformBottomSheet(context, ref, platform),
                            child: Text(platform.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          ),
                          subtitle: GestureDetector(
                            onLongPress: () => _showPlatformBottomSheet(context, ref, platform),
                            child: Text('${platform.channelCount} Channels'),
                          ),
                          onExpansionChanged: (expanded) {
                            if (expanded && channels == null) {
                              notifier.loadChannels(platform.id);
                            }
                          },
                          children: [
                            if (channels == null)
                              const Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator())
                            else if (channels.isEmpty)
                              const Padding(
                                padding: EdgeInsets.all(16),
                                child: Text('No channels. Long press platform to add.'),
                              )
                            else
                              ...channels.map((channel) => ListTile(
                                leading: const Icon(Icons.tv),
                                title: Text(channel.name),
                                subtitle: Text(channel.handle),
                                onLongPress: () => _showChannelBottomSheet(context, ref, platform, channel),
                              )),
                          ],
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/admin/platforms/new'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
