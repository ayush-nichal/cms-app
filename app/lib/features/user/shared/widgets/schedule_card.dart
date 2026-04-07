import 'package:flutter/material.dart';
import '../../schedules/data/schedule_model.dart';
import 'package:intl/intl.dart';
import '../../../../core/utils/content_type_translator.dart';

class ScheduleCard extends StatelessWidget {
  final Schedule schedule;
  final VoidCallback? onTap;

  const ScheduleCard({super.key, required this.schedule, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isPast = schedule.isPastDue;
    final Color textColor = isPast ? Colors.grey : Colors.black87;
    final bool isVideo = schedule.mediaUrl != null && (schedule.mediaUrl!.toLowerCase().endsWith('.mp4') || schedule.mediaUrl!.toLowerCase().endsWith('.mov'));
    
    final platformName = schedule.channelName != null && schedule.channelName!.contains('(') 
        ? schedule.channelName!.substring(schedule.channelName!.indexOf('(') + 1, schedule.channelName!.indexOf(')'))
        : 'default';
        
    final typeLabel = ContentTypeTranslator.translate(schedule.contentType, platformName);
    final badgeColor = ContentTypeTranslator.getColor(schedule.contentType);
    final badgeIcon = ContentTypeTranslator.getIcon(schedule.contentType);

    final card = Card(
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
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: badgeColor,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Row(
                                children: [
                                  Icon(badgeIcon, size: 12, color: Colors.white),
                                  const SizedBox(width: 4),
                                  Text(
                                    typeLabel.toUpperCase(),
                                    style: const TextStyle(fontSize: 10, color: Colors.white, fontWeight: FontWeight.bold),
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
              Row(
                children: [
                  if (schedule.channelHandle != null)
                    Expanded(
                      child: Text(
                        schedule.channelHandle!,
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        DateFormat('MMM d · hh:mm a').format(schedule.scheduledAt),
                        style: TextStyle(fontSize: 12, color: isPast ? Colors.red.shade300 : Colors.blue.shade700, fontWeight: FontWeight.w600),
                      ),
                      if (isPast)
                        Text('Past due', style: TextStyle(fontSize: 10, color: Colors.red.shade300, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (isPast) {
      return Opacity(opacity: 0.55, child: card);
    }
    return card;
  }
}
