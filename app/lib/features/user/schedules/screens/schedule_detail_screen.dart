import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import '../providers/schedule_provider.dart';
import '../data/schedule_model.dart';
import '../../../../shared/widgets/confirm_dialog.dart';

class ScheduleDetailScreen extends ConsumerStatefulWidget {
  final Schedule schedule;
  final bool isCreator;

  const ScheduleDetailScreen({super.key, required this.schedule, required this.isCreator});

  @override
  ConsumerState<ScheduleDetailScreen> createState() => _ScheduleDetailScreenState();
}

class _ScheduleDetailScreenState extends ConsumerState<ScheduleDetailScreen> {
  VideoPlayerController? _videoController;

  @override
  void initState() {
    super.initState();
    _initMedia();
  }

  void _initMedia() {
    final mediaUrl = widget.schedule.mediaUrl;
    if (mediaUrl != null && (mediaUrl.toLowerCase().endsWith('.mp4') || mediaUrl.toLowerCase().endsWith('.mov'))) {
      _videoController = VideoPlayerController.networkUrl(Uri.parse(mediaUrl))
        ..initialize().then((_) {
          setState(() {});
        });
    }
  }

  @override
  void dispose() {
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Schedule Details'),
        actions: [
          if (widget.isCreator)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => context.push('/user/schedules/edit', extra: {'channelId': widget.schedule.channelId, 'schedule': widget.schedule}),
            ),
          if (widget.isCreator)
            IconButton(
              icon: const Icon(Icons.delete),
              onPressed: () async {
                final confirm = await showDialog<bool>(
                  context: context,
                  builder: (_) => const ConfirmDialog(title: 'Delete Schedule', message: 'Are you sure?', confirmText: 'Delete'),
                );
                if (confirm == true) {
                  try {
                    await ref.read(scheduleProvider.notifier).deleteSchedule(widget.schedule.id, widget.schedule.channelId);
                    if (context.mounted) {
                      context.pop();
                      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted')));
                    }
                  } catch (e) {
                    if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: Colors.red));
                  }
                }
              },
            ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(widget.schedule.contentType == 'video' ? Icons.videocam : Icons.image, color: Colors.blue),
                const SizedBox(width: 8),
                Text(widget.schedule.contentType.toUpperCase(), style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
              ],
            ),
            const SizedBox(height: 8),
            Text(widget.schedule.title, style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 24),

            if (widget.schedule.mediaUrl != null) ...[
              if (_videoController != null)
                if (_videoController!.value.isInitialized)
                  GestureDetector(
                    onTap: () {
                      setState(() {
                         _videoController!.value.isPlaying ? _videoController!.pause() : _videoController!.play();
                      });
                    },
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        AspectRatio(
                          aspectRatio: _videoController!.value.aspectRatio,
                          child: VideoPlayer(_videoController!),
                        ),
                        if (!_videoController!.value.isPlaying)
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: const BoxDecoration(color: Colors.black54, shape: BoxShape.circle),
                            child: const Icon(Icons.play_arrow, color: Colors.white, size: 48),
                          ),
                      ],
                    ),
                  )
                else
                  const AspectRatio(aspectRatio: 16/9, child: Center(child: CircularProgressIndicator()))
              else
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: CachedNetworkImage(
                    imageUrl: widget.schedule.mediaUrl!,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    placeholder: (context, url) => const SizedBox(height: 200, child: Center(child: CircularProgressIndicator())),
                    errorWidget: (context, url, error) => const SizedBox(height: 200, child: Center(child: Icon(Icons.error))),
                  ),
                ),
              const SizedBox(height: 24),
            ],

            Row(
              children: [
                const Icon(Icons.calendar_today, size: 20, color: Colors.grey),
                const SizedBox(width: 8),
                Text(DateFormat('EEEE, d MMMM yyyy \'at\' hh:mm a').format(widget.schedule.scheduledAt), style: const TextStyle(fontSize: 16)),
              ],
            ),
            const SizedBox(height: 24),
            const Divider(height: 32),
            if (widget.schedule.description != null && widget.schedule.description!.isNotEmpty) ...[
              const Text('Description', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              Text(widget.schedule.description!),
            ],
            const SizedBox(height: 16),
            Text('Created by: ${widget.schedule.creatorName ?? widget.schedule.createdById}', style: const TextStyle(color: Colors.grey, fontSize: 12)),
          ],
        ),
      ),
    );
  }
}
