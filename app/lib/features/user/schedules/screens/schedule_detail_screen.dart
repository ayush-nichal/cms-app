import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';
import '../providers/schedule_provider.dart';
import '../data/schedule_model.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../../../shared/design/design_tokens.dart';
import 'package:google_fonts/google_fonts.dart';

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
    final schedule = widget.schedule;
    final isVideo = schedule.mediaUrl != null &&
        (schedule.mediaUrl!.toLowerCase().endsWith('.mp4') || schedule.mediaUrl!.toLowerCase().endsWith('.mov'));

    // Content type badge styles
    const typeStyles = <String, ({String label, Color bg, Color fg})>{
      'text_post': (label: 'TEXT POST', bg: Color(0xFFF3E5F5), fg: Color(0xFF6A1B9A)),
      'image_post': (label: 'IMAGE POST', bg: Color(0xFFE3F2FD), fg: Color(0xFF1565C0)),
      'short_form_video': (label: 'SHORT FORM', bg: Color(0xFFE8F5E9), fg: Color(0xFF2E7D32)),
      'long_form_video': (label: 'LONG VIDEO', bg: Color(0xFFFFF3E0), fg: Color(0xFFE65100)),
      'carousel_post': (label: 'CAROUSEL', bg: Color(0xFFFCE4EC), fg: Color(0xFFC62828)),
    };
    final ts = typeStyles[schedule.contentType] ?? (label: schedule.contentType.toUpperCase(), bg: surfaceLow, fg: onSurfaceVar);

    Widget contentTypePill() {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: ts.bg,
          borderRadius: BorderRadius.circular(9999),
        ),
        child: Text(
          ts.label,
          style: GoogleFonts.epilogue(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: ts.fg,
            letterSpacing: 10 * 0.05,
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: surface,
      appBar: AppBar(
        backgroundColor: surface,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: primary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Schedule Details',
          style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w600, color: onSurface),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.delete_outline_rounded, color: onSurfaceVar),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (_) => const ConfirmDialog(title: 'Delete Schedule', message: 'Are you sure?', confirmText: 'Delete'),
              );
              if (confirm == true) {
                try {
                  await ref.read(scheduleProvider.notifier).deleteSchedule(schedule.id, schedule.channelId);
                  if (context.mounted) {
                    context.pop();
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Deleted')));
                  }
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
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: surfaceWhite,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [BoxShadow(color: Color(0x0A191C1D), blurRadius: 32, offset: Offset(0, 12))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  contentTypePill(),
                  const SizedBox(height: 16),
                  Text(
                    schedule.title.toUpperCase(),
                    style: GoogleFonts.publicSans(fontSize: 32, fontWeight: FontWeight.w800, color: onSurface),
                  ),
                  const SizedBox(height: 20),
                  Container(height: 1, color: surfaceLow),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: surfaceLow,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.calendar_month_rounded, color: primary, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'SCHEDULED FOR',
                              style: GoogleFonts.epilogue(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: onSurfaceVar,
                                letterSpacing: 10 * 0.06,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              DateFormat('EEEE, d MMMM yyyy').format(schedule.scheduledAt),
                              style: GoogleFonts.publicSans(fontSize: 18, fontWeight: FontWeight.w600, color: onSurface),
                            ),
                            Text(
                              'at ${DateFormat('hh:mm a').format(schedule.scheduledAt)}',
                              style: GoogleFonts.plusJakartaSans(fontSize: 14, color: onSurfaceVar),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(height: 1, color: surfaceLow),
                  const SizedBox(height: 20),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: const BoxDecoration(
                          color: Color(0xFFE8F0FB),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.person_rounded, color: primary, size: 24),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CREATED BY',
                              style: GoogleFonts.epilogue(
                                fontSize: 10,
                                fontWeight: FontWeight.w500,
                                color: onSurfaceVar,
                                letterSpacing: 10 * 0.06,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              schedule.creatorName ?? schedule.createdById,
                              style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w500, color: onSurface),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            if (schedule.mediaUrl != null) ...[
              const SizedBox(height: 16),
              ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: SizedBox(
                  height: 200,
                  width: double.infinity,
                  child: isVideo
                      ? Container(
                          color: surfaceLow,
                          child: Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.play_circle_rounded, size: 64, color: primary),
                                const SizedBox(height: 8),
                                Text(
                                  'Tap to preview video',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: onSurfaceVar),
                                ),
                              ],
                            ),
                          ),
                        )
                      : CachedNetworkImage(
                          imageUrl: schedule.mediaUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => const Center(child: CircularProgressIndicator(color: primary)),
                          errorWidget: (_, __, ___) => const Center(child: Icon(Icons.error_outline_rounded)),
                        ),
                ),
              ),
            ],
            if (schedule.description != null && schedule.description!.isNotEmpty) ...[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                decoration: BoxDecoration(
                  gradient: primaryGradient,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  schedule.description!.length <= 30 ? schedule.description! : '${schedule.description!.substring(0, 30)}…',
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ),
            ],
            const SizedBox(height: 100),
          ],
        ),
      ),
      floatingActionButton: widget.isCreator
          ? FloatingActionButton(
              backgroundColor: primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              onPressed: () => context.push('/user/schedules/edit', extra: {'channelId': schedule.channelId, 'schedule': schedule}),
              child: const Icon(Icons.edit_rounded, color: Colors.white),
            )
          : null,
    );
  }
}
