import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/platform_provider.dart';
import '../data/platform_model.dart';
import '../../../../shared/design/design_tokens.dart';
import '../../channels/widgets/channel_settings_sheet.dart';
import '../widgets/platform_settings_sheet.dart';

class PlatformsScreen extends ConsumerWidget {
  const PlatformsScreen({super.key});

  void _showPlatformBottomSheet(BuildContext context, Platform platform) {
    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceWhite,
      barrierColor: Colors.black.withOpacity(0.4),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(child: PlatformSettingsSheet(platform: platform)),
    );
  }

  void _showChannelBottomSheet(BuildContext context, Platform platform, Channel channel) {
    showModalBottomSheet(
      context: context,
      backgroundColor: surfaceWhite,
      barrierColor: Colors.black.withOpacity(0.4),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => SafeArea(child: ChannelSettingsSheet(platform: platform, channel: channel)),
    );
  }

  Future<void> _ensureChannelsLoaded(WidgetRef ref, Platform platform) async {
    final current = ref.read(platformProvider).channelsByPlatformId[platform.id];
    if (current != null) return;
    await ref.read(platformProvider.notifier).loadChannels(platform.id);
  }

  Widget _buildChannelAvatar(Channel channel) {
    // Backend doesn’t currently provide an avatar URL; we still support future URLs via heuristics.
    // If handle looks like a URL, show it; otherwise show initials.
    final handle = channel.handle.trim();
    final maybeUrl = (handle.startsWith('http://') || handle.startsWith('https://')) ? handle : null;
    final initials = channel.name.trim().isEmpty
        ? '?'
        : channel.name
            .trim()
            .split(RegExp(r'\s+'))
            .where((p) => p.isNotEmpty)
            .take(2)
            .map((p) => p.characters.first.toUpperCase())
            .join();

    return CircleAvatar(
      radius: 24,
      backgroundColor: const Color(0xFFE8F0FB),
      foregroundColor: primary,
      child: maybeUrl == null
          ? Text(
              initials,
              style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: primary),
            )
          : ClipOval(
              child: CachedNetworkImage(
                imageUrl: maybeUrl,
                width: 48,
                height: 48,
                fit: BoxFit.cover,
                errorWidget: (_, __, ___) => Text(
                  initials,
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: primary),
                ),
              ),
            ),
    );
  }

  Widget _platformHeaderCard(BuildContext context, Platform platform) {
    final badgeText = '${platform.channelCount} ${(platform.channelCount == 1) ? 'CHANNEL' : 'CHANNELS'}';
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () => _showPlatformBottomSheet(context, platform),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: getPlatformGradient(platform.name),
          boxShadow: const [
            BoxShadow(color: Color(0x0A191C1D), blurRadius: 32, offset: Offset(0, 12)),
          ],
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        child: Row(
          children: [
            Icon(getPlatformIcon(platform.name), color: Colors.white, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                platform.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.publicSans(fontSize: 22, fontWeight: FontWeight.w700, color: Colors.white),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.25),
                borderRadius: BorderRadius.circular(9999),
              ),
              child: Text(
                badgeText,
                style: GoogleFonts.epilogue(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.white,
                  letterSpacing: 11 * 0.05,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _channelCard(BuildContext context, Platform platform, Channel channel) {
    final usersText = '${channel.userCount} ${(channel.userCount == 1) ? 'USER' : 'USERS'}';
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: () => _showChannelBottomSheet(context, platform, channel),
      child: Container(
        decoration: BoxDecoration(
          color: surfaceWhite,
          borderRadius: BorderRadius.circular(12),
          boxShadow: const [
            BoxShadow(color: Color(0x0A191C1D), blurRadius: 32, offset: Offset(0, 12)),
          ],
        ),
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            _buildChannelAvatar(channel),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    channel.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: onSurface,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    channel.handle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w400, color: onSurfaceVar),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
            Text(
              usersText,
              style: GoogleFonts.epilogue(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: onSurfaceVar,
                letterSpacing: 11 * 0.05,
              ),
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
      backgroundColor: surface,
      body: RefreshIndicator(
        color: primary,
        onRefresh: () => notifier.loadPlatforms(),
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 24),
              Text('Channels', style: displayTextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
              const SizedBox(height: 16),
              if (state.isLoading && state.platforms.isEmpty)
                const Padding(
                  padding: EdgeInsets.only(top: 48),
                  child: Center(child: CircularProgressIndicator(color: primary)),
                )
              else if (state.platforms.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 80),
                  child: Center(
                    child: Text(
                      'No platforms yet.\nTap + to add one.',
                      textAlign: TextAlign.center,
                      style: bodyTextStyle(fontSize: 14, color: onSurfaceVar),
                    ),
                  ),
                )
              else
                ...state.platforms.map((platform) {
                  return Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _platformHeaderCard(context, platform),
                      const SizedBox(height: 8),
                      FutureBuilder<void>(
                        future: _ensureChannelsLoaded(ref, platform),
                        builder: (context, snapshot) {
                          final loadedChannels = ref.watch(platformProvider).channelsByPlatformId[platform.id];
                          final showLoading = loadedChannels == null;
                          if (showLoading) {
                            return const Padding(
                              padding: EdgeInsets.only(top: 8, bottom: 4),
                              child: Center(child: CircularProgressIndicator(color: primary)),
                            );
                          }
                          if (loadedChannels.isEmpty) {
                            return Padding(
                              padding: const EdgeInsets.only(top: 8),
                              child: Text('No channels yet.', style: bodyTextStyle(fontSize: 13, color: onSurfaceVar)),
                            );
                          }
                          return Column(
                            children: [
                              for (final channel in loadedChannels) ...[
                                _channelCard(context, platform, channel),
                                const SizedBox(height: 8),
                              ]
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 20),
                    ],
                  );
                }),
              const SizedBox(height: 96),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        backgroundColor: primary,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: const CircleBorder(),
        onPressed: () => context.push('/admin/platforms/new'),
        child: const Icon(Icons.add_rounded),
      ),
    );
  }
}
