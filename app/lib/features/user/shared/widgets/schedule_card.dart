import 'package:flutter/material.dart';
import '../../schedules/data/schedule_model.dart';
import 'package:intl/intl.dart';
import 'status_chip.dart';

class ScheduleCard extends StatelessWidget {
  final Schedule schedule;
  final VoidCallback? onTap;

  const ScheduleCard({super.key, required this.schedule, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isPast = schedule.scheduledAt.isBefore(DateTime.now());
    final Color textColor = isPast ? Colors.grey : Colors.black87;
    final bool isVideo = schedule.mediaUrl != null && (schedule.mediaUrl!.toLowerCase().endsWith('.mp4') || schedule.mediaUrl!.toLowerCase().endsWith('.mov'));

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: isPast ? Colors.grey.shade100 : Colors.white,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          schedule.title,
                          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: textColor),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Icon(
                              schedule.contentType == 'video' ? Icons.videocam : Icons.image,
                              size: 16,
                              color: textColor,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              schedule.contentType.toUpperCase(),
                              style: TextStyle(fontSize: 12, color: textColor),
                            ),
                            const Spacer(),
                            Text(
                              DateFormat('MMM d · hh:mm a').format(schedule.scheduledAt),
                              style: TextStyle(fontSize: 12, color: isPast ? Colors.red.shade300 : Colors.blue.shade700, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  if (schedule.mediaUrl != null) ...[
                    const SizedBox(width: 12),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: isVideo 
                        ? Container(
                            width: 48,
                            height: 48,
                            color: Colors.black87,
                            child: const Icon(Icons.play_circle_fill, color: Colors.white, size: 24),
                          )
                        : Image.network(
                            schedule.mediaUrl!,
                            width: 48,
                            height: 48,
                            fit: BoxFit.cover,
                            errorBuilder: (ctx, err, stack) => const Icon(Icons.broken_image, size: 48, color: Colors.grey),
                          ),
                    ),
                  ],
                ],
              ),
              const Divider(height: 16),
              Align(
                alignment: Alignment.centerRight,
                child: StatusChip(status: schedule.status),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
