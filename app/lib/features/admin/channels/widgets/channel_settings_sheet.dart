import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/design/design_tokens.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../../platforms/data/platform_model.dart';
import '../../platforms/providers/platform_provider.dart';

class ChannelSettingsSheet extends ConsumerWidget {
  final Platform platform;
  final Channel channel;

  const ChannelSettingsSheet({
    super.key,
    required this.platform,
    required this.channel,
  });

  Future<void> _confirmAndDelete(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => const ConfirmDialog(
        title: 'Delete Channel',
        message: 'Are you sure you want to delete this channel? If users are assigned to it, it will fail.',
        confirmText: 'Delete',
      ),
    );
    if (confirm != true) return;

    try {
      await ref.read(platformProvider.notifier).deleteChannel(channel.id, platform.id);
      if (context.mounted) {
        Navigator.of(context).pop(); // close sheet
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Channel deleted', style: GoogleFonts.plusJakartaSans())),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString().replaceAll('Exception: ', ''), style: GoogleFonts.plusJakartaSans()),
            backgroundColor: errorRed,
          ),
        );
      }
    }
  }

  Widget _actionTile({
    required Widget leading,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
    Color? titleColor,
  }) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            leading,
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: bodyTextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: titleColor ?? onSurface,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(subtitle, style: bodyTextStyle(fontSize: 13, color: onSurfaceVar)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: const Color(0xFFE0E0E0),
                borderRadius: BorderRadius.circular(9999),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'CHANNEL ACTIONS',
            style: labelCapsTextStyle(fontSize: 11, color: onSurfaceVar, letterSpacingEm: 0.05),
          ),
          const SizedBox(height: 20),
          _actionTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: surfaceLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.edit_rounded, color: primary),
            ),
            title: 'Edit Channel',
            subtitle: 'Modify settings, names, and permissions',
            onTap: () {
              Navigator.of(context).pop();
              context.push('/admin/channels/edit', extra: {'platform': platform, 'channel': channel});
            },
          ),
          const SizedBox(height: 12),
          _actionTile(
            leading: Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: const Color(0xFFFFEDEA),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.delete_outline_rounded, color: errorRed),
            ),
            title: 'Delete Channel',
            subtitle: 'Permanently remove this channel and its data',
            titleColor: errorRed,
            onTap: () => _confirmAndDelete(context, ref),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: outlineGhost),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: Text(
                'CANCEL',
                style: GoogleFonts.epilogue(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: onSurface,
                  letterSpacing: 11 * 0.05,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

