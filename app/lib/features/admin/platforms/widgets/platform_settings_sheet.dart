import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/design/design_tokens.dart';
import '../../../../shared/widgets/confirm_dialog.dart';
import '../data/platform_model.dart';
import '../providers/platform_provider.dart';

class PlatformSettingsSheet extends ConsumerWidget {
  final Platform platform;

  const PlatformSettingsSheet({super.key, required this.platform});

  Future<void> _confirmAndDelete(BuildContext context, WidgetRef ref) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (_) => const ConfirmDialog(
        title: 'Delete Platform',
        message: 'Are you sure you want to delete this platform? If channels exist under it, it will fail.',
        confirmText: 'Delete',
      ),
    );
    if (confirm != true) return;

    try {
      await ref.read(platformProvider.notifier).deletePlatform(platform.id);
      if (context.mounted) {
        Navigator.of(context).pop(); // close sheet
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Platform deleted', style: GoogleFonts.plusJakartaSans())),
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
          Text('Platform Settings', style: displayTextStyle(fontSize: 22, fontWeight: FontWeight.w700)),
          const SizedBox(height: 6),
          Text(
            'Manage your active social media integrations',
            style: bodyTextStyle(fontSize: 14, color: onSurfaceVar),
          ),
          const SizedBox(height: 24),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.add_rounded, color: primary, size: 24),
            title: Text('Add Channel', style: bodyTextStyle(fontSize: 16, fontWeight: FontWeight.w400)),
            onTap: () {
              Navigator.of(context).pop();
              context.push('/admin/channels/new', extra: platform);
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.edit_rounded, color: onSurfaceVar, size: 24),
            title: Text('Edit Platform', style: bodyTextStyle(fontSize: 16, fontWeight: FontWeight.w400)),
            onTap: () {
              Navigator.of(context).pop();
              context.push('/admin/platforms/edit', extra: platform);
            },
          ),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.delete_outline_rounded, color: errorRed, size: 24),
            title: Text(
              'Delete Platform',
              style: bodyTextStyle(fontSize: 16, fontWeight: FontWeight.w400, color: errorRed),
            ),
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

