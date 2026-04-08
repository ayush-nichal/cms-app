import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../../user/schedules/data/schedule_model.dart';
import '../../../../core/utils/content_type_translator.dart';
import '../../../../shared/design/design_tokens.dart';

class ScheduleDetailsDialog extends StatelessWidget {
  final Schedule schedule;

  const ScheduleDetailsDialog({super.key, required this.schedule});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isVideo = schedule.contentType.contains('video');
    final typeLabel = ContentTypeTranslator.translate(schedule.contentType, schedule.platformName ?? 'default');
    final typeColor = ContentTypeTranslator.getColor(schedule.contentType);
    final typeIcon = ContentTypeTranslator.getIcon(schedule.contentType);

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 500),
        decoration: BoxDecoration(
          color: surfaceWhite,
          borderRadius: BorderRadius.circular(28),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.1), blurRadius: 40, offset: const Offset(0, 20)),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(28),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with Media Preview
                _buildHeader(isVideo),
                
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Status & Type Badges
                      Row(
                        children: [
                          _buildBadge(
                            label: typeLabel.toUpperCase(),
                            color: typeColor,
                            icon: typeIcon,
                          ),
                          const SizedBox(width: 8),
                          _buildBadge(
                            label: 'SCHEDULED',
                            color: primary,
                            icon: Icons.access_time_filled_rounded,
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      
                      // Title & Description
                      Text(
                        schedule.title,
                        style: GoogleFonts.publicSans(
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                          color: onSurface,
                        ),
                      ),
                      if (schedule.description != null && schedule.description!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          schedule.description!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            color: onSurfaceVar,
                            height: 1.5,
                          ),
                        ),
                      ],
                      
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 24),
                        child: Divider(color: outlineGhost),
                      ),
                      
                      // Info Grid
                      _buildInfoRow(
                        icon: Icons.calendar_today_rounded,
                        label: 'Publish Date',
                        value: DateFormat('EEEE, MMMM d, yyyy').format(schedule.scheduledAt),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        icon: Icons.access_time_rounded,
                        label: 'Publish Time',
                        value: DateFormat('hh:mm a').format(schedule.scheduledAt),
                      ),
                      const SizedBox(height: 16),
                      _buildInfoRow(
                        icon: Icons.subscriptions_outlined,
                        label: 'Target Channel',
                        value: schedule.channelName ?? 'Primary Channel',
                      ),
                      if (schedule.platformName != null) ...[
                        const SizedBox(height: 16),
                        _buildInfoRow(
                          icon: getPlatformIcon(schedule.platformName!),
                          label: 'Platform',
                          value: schedule.platformName!,
                        ),
                      ],
                      
                      const SizedBox(height: 32),
                      
                      // Action Button
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: () => Navigator.pop(context),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primary,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                          ),
                          child: const Text('Close Details', style: TextStyle(fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isVideo) {
    if (schedule.mediaUrl == null) {
      return Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [primary.withOpacity(0.8), primaryAlt.withOpacity(0.8)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: const Center(
          child: Icon(Icons.description_rounded, size: 48, color: Colors.white24),
        ),
      );
    }

    return Stack(
      children: [
        SizedBox(
          height: 240,
          width: double.infinity,
          child: Image.network(
            schedule.mediaUrl!,
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Container(
              color: surfaceLow,
              child: const Icon(Icons.image_not_supported_rounded, size: 48, color: onSurfaceVar),
            ),
          ),
        ),
        if (isVideo)
          Positioned.fill(
            child: Container(
              color: Colors.black.withOpacity(0.3),
              child: const Center(
                child: Icon(Icons.play_circle_fill_rounded, size: 64, color: Colors.white),
              ),
            ),
          ),
        Positioned(
          top: 12,
          right: 12,
          child: IconButton(
            icon: const CircleAvatar(
              backgroundColor: Colors.black26,
              child: Icon(Icons.close_rounded, color: Colors.white, size: 18),
            ),
            onPressed: () => {}, // Handled by outer tap if needed, or close button below
          ),
        ),
      ],
    );
  }

  Widget _buildBadge({required String label, required Color color, required IconData icon}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.epilogue(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 10 * 0.05,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInfoRow({required IconData icon, required String label, required String value}) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: surfaceLow,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 18, color: onSurfaceVar),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label.toUpperCase(),
                style: GoogleFonts.epilogue(
                  fontSize: 9,
                  fontWeight: FontWeight.w600,
                  color: onSurfaceVar,
                  letterSpacing: 9 * 0.05,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: onSurface,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
