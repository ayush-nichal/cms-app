import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/user_provider.dart';
import '../data/user_model.dart';
import 'add_assignment_sheet.dart';
import '../../../../shared/design/design_tokens.dart';

class UserDetailScreen extends ConsumerStatefulWidget {
  final String userId;

  const UserDetailScreen({super.key, required this.userId});

  @override
  ConsumerState<UserDetailScreen> createState() => _UserDetailScreenState();
}

class _UserDetailScreenState extends ConsumerState<UserDetailScreen> {
  final TextEditingController _apiKeyController = TextEditingController();
  final TextEditingController _whatsappController = TextEditingController();
  bool _isSavingApiKey = false;
  bool _isSavingWhatsapp = false;
  bool _isSendingResetLink = false;
  bool _emailNotificationsEnabled = true;
  bool _obscureApiKey = true;
  final Set<String> _removingAssignmentIds = {};

  @override
  void dispose() {
    _apiKeyController.dispose();
    _whatsappController.dispose();
    super.dispose();
  }

  Future<void> _removeAssignment(AppUser user, String channelId, String channelName) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: surfaceWhite,
        title: Text('Remove Assignment', style: GoogleFonts.publicSans(fontWeight: FontWeight.bold)),
        content: Text('Are you sure you want to remove access to "$channelName" for ${user.email}?', style: GoogleFonts.plusJakartaSans()),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text('Cancel', style: GoogleFonts.plusJakartaSans(color: onSurfaceVar)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: errorRed, foregroundColor: Colors.white),
            child: Text('Remove', style: GoogleFonts.plusJakartaSans()),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    if (_removingAssignmentIds.contains(channelId)) return;
    setState(() => _removingAssignmentIds.add(channelId));

    try {
      await ref.read(userProvider.notifier).removeAssignment(user.id, channelId);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Assignment removed', style: GoogleFonts.plusJakartaSans())),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', ''), style: GoogleFonts.plusJakartaSans()),
          backgroundColor: errorRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _removingAssignmentIds.remove(channelId));
    }
  }

  static String _displayNameFromEmail(String email) {
    final local = email.split('@').first.trim();
    if (local.isEmpty) return 'User';
    final parts = local.split(RegExp(r'[._\-\s]+')).where((p) => p.isNotEmpty).toList();
    if (parts.isEmpty) return local;
    final derived = parts
        .take(2)
        .map((p) => p.length == 1 ? p.toUpperCase() : '${p[0].toUpperCase()}${p.substring(1).toLowerCase()}')
        .join(' ');
    return derived;
  }

  static const _avatarTints = <Color>[
    Color(0xFFBBD6F4),
    Color(0xFFB8E4D0),
    Color(0xFFE4C4B8),
    Color(0xFFD4B8E4),
    Color(0xFFC8C8C8),
  ];

  InputDecoration _outlinedInput({
    required String hintText,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.plusJakartaSans(fontSize: 14, color: onSurfaceVar),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: surfaceWhite,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0x66C1C6D4)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0x66C1C6D4)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: primary, width: 2),
      ),
    );
  }

  Future<void> _saveApiKey(AppUser user) async {
    if (_isSavingApiKey) return;
    setState(() => _isSavingApiKey = true);
    try {
      await ref.read(userProvider.notifier).updateUser(
        user.id,
        UpdateUserRequest(callmebotApiKey: _apiKeyController.text.trim()),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('API Key saved', style: GoogleFonts.plusJakartaSans())),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''), style: GoogleFonts.plusJakartaSans()), backgroundColor: errorRed),
      );
    } finally {
      if (mounted) setState(() => _isSavingApiKey = false);
    }
  }

  Future<void> _saveWhatsapp(AppUser user) async {
    if (_isSavingWhatsapp) return;
    setState(() => _isSavingWhatsapp = true);
    try {
      await ref.read(userProvider.notifier).updateUser(
        user.id,
        UpdateUserRequest(whatsappNumber: _whatsappController.text.trim()),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('WhatsApp saved', style: GoogleFonts.plusJakartaSans())),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.toString().replaceAll('Exception: ', ''), style: GoogleFonts.plusJakartaSans()), backgroundColor: errorRed),
      );
    } finally {
      if (mounted) setState(() => _isSavingWhatsapp = false);
    }
  }

  Future<void> _sendResetLink(AppUser user) async {
    if (_isSendingResetLink) return;
    setState(() => _isSendingResetLink = true);
    try {
      await ref.read(userProvider.notifier).sendResetLink(user.id);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Reset link sent to ${user.email}', style: GoogleFonts.plusJakartaSans()),
          backgroundColor: successGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(e.toString().replaceAll('Exception: ', ''), style: GoogleFonts.plusJakartaSans()),
          backgroundColor: errorRed,
        ),
      );
    } finally {
      if (mounted) setState(() => _isSendingResetLink = false);
    }
  }

  Widget _pill({
    required Widget child,
    required Color background,
    EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  }) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(9999),
      ),
      child: child,
    );
  }

  Widget _primaryCta({required String label, required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(9999),
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          gradient: primaryGradient,
          borderRadius: BorderRadius.circular(9999),
          boxShadow: const [BoxShadow(color: Color(0x0A191C1D), blurRadius: 32, offset: Offset(0, 12))],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
            ),
            const SizedBox(width: 10),
            const Icon(Icons.arrow_forward_rounded, color: Colors.white),
          ],
        ),
      ),
    );
  }

  Widget _secondaryCta({required String label, required VoidCallback? onTap, bool isLoading = false, IconData? icon}) {
    return OutlinedButton(
      onPressed: onTap,
      style: OutlinedButton.styleFrom(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 20),
        side: const BorderSide(color: Color(0x66C1C6D4)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
      ),
      child: isLoading
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[Icon(icon, size: 18, color: primary), const SizedBox(width: 8)],
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: primary),
                ),
              ],
            ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(userProvider);
    final user = state.users.firstWhere(
      (u) => u.id == widget.userId,
      orElse: () => AppUser(id: '', email: 'Not Found', role: '', isActive: false, assignments: [])
    );

    if (user.id.isEmpty) {
      return Scaffold(
        backgroundColor: surface,
        appBar: AppBar(
          backgroundColor: surface,
          elevation: 0,
          title: Text(
            'User Not Found',
            style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w600, color: onSurface),
          ),
        ),
        body: Center(child: Text('User not found', style: GoogleFonts.plusJakartaSans(color: onSurfaceVar))),
      );
    }

    if (_apiKeyController.text.isEmpty && (user.callmebotApiKey ?? '').isNotEmpty) {
      _apiKeyController.text = user.callmebotApiKey!;
    }
    if (_whatsappController.text.isEmpty && user.whatsappNumber != null) {
      _whatsappController.text = user.whatsappNumber!;
    }

    final displayName = _displayNameFromEmail(user.email);
    final isConfigured = (user.whatsappNumber ?? '').trim().isNotEmpty && (user.callmebotApiKey ?? '').trim().isNotEmpty;
    final role = user.role.toUpperCase();

    return Scaffold(
      backgroundColor: surface,
      appBar: AppBar(
        backgroundColor: surface,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded, color: onSurface),
        ),
        title: Text(
          'User Settings',
          style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w600, color: onSurface),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 16),
            // 1) Profile card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: surfaceWhite,
                borderRadius: BorderRadius.circular(20),
                boxShadow: const [
                  BoxShadow(color: Color(0x0A191C1D), blurRadius: 32, offset: Offset(0, 12)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Stack(
                    clipBehavior: Clip.none,
                    children: [
                      Container(
                        width: 80,
                        height: 80,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: _avatarTints[widget.userId.hashCode.abs() % _avatarTints.length].withOpacity(0.65),
                        ),
                        child: const Icon(Icons.person_rounded, color: primary, size: 40),
                      ),
                      Positioned(
                        right: 2,
                        bottom: 2,
                        child: Container(
                          width: 12,
                          height: 12,
                          decoration: BoxDecoration(
                            color: primaryAlt,
                            shape: BoxShape.circle,
                            border: Border.all(color: surfaceWhite, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(displayName, style: GoogleFonts.publicSans(fontSize: 22, fontWeight: FontWeight.w700, color: onSurface)),
                  const SizedBox(height: 4),
                  Text(user.email, style: GoogleFonts.plusJakartaSans(fontSize: 14, color: onSurfaceVar)),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _pill(
                        background: const Color(0xFFE8F0FB),
                        child: Text(
                          role,
                          style: GoogleFonts.epilogue(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: primary,
                            letterSpacing: 11 * 0.05,
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      _pill(
                        background: surfaceLow,
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 8,
                              height: 8,
                              decoration: BoxDecoration(
                                color: user.isActive ? successGreen : errorRed,
                                shape: BoxShape.circle,
                              ),
                            ),
                            const SizedBox(width: 6),
                            Text(
                              user.isActive ? 'ACTIVE' : 'INACTIVE',
                              style: GoogleFonts.epilogue(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                color: user.isActive ? successGreen : errorRed,
                                letterSpacing: 11 * 0.05,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _primaryCta(
                    label: 'Edit Profile',
                    onTap: () => context.push('/admin/users/edit', extra: user),
                  ),
                  const SizedBox(height: 12),
                  _secondaryCta(
                    label: 'Send Password Reset Link',
                    icon: Icons.mail_lock_rounded,
                    isLoading: _isSendingResetLink,
                    onTap: _isSendingResetLink ? null : () => _sendResetLink(user),
                  ),
                ],
              ),
            ),
            // 2) Channel assignments
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'CHANNEL ASSIGNMENTS',
                    style: GoogleFonts.epilogue(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: onSurfaceVar,
                      letterSpacing: 11 * 0.05,
                    ),
                  ),
                ),
                TextButton(
                  onPressed: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      useSafeArea: true,
                      backgroundColor: surfaceWhite,
                      shape: const RoundedRectangleBorder(
                        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
                      ),
                      builder: (_) => AddAssignmentSheet(user: user),
                    );
                  },
                  child: Text('+ Assign', style: GoogleFonts.plusJakartaSans(color: primary, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (user.assignments.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Text('No assigned channels', style: GoogleFonts.plusJakartaSans(color: onSurfaceVar)),
              )
            else
              Column(
                children: [
                  for (final assign in user.assignments) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: surfaceLow,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              color: surfaceWhite,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.grid_view_rounded, color: primary, size: 18),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  assign.channelName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: onSurface),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  assign.platformName.toUpperCase(),
                                  style: GoogleFonts.epilogue(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: onSurfaceVar,
                                    letterSpacing: 10 * 0.05,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            onPressed: _removingAssignmentIds.contains(assign.channelId) 
                                ? null 
                                : () => _removeAssignment(user, assign.channelId, assign.channelName),
                            icon: _removingAssignmentIds.contains(assign.channelId)
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.remove_circle_outline_rounded, color: errorRed, size: 20),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                  ]
                ],
              ),

            // 3) Notification settings
            const SizedBox(height: 20),
            Text(
              'NOTIFICATION SETTINGS',
              style: GoogleFonts.epilogue(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: onSurfaceVar,
                letterSpacing: 11 * 0.05,
              ),
            ),
            const SizedBox(height: 12),
            // Email Notifications card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surfaceWhite,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Color(0x0A191C1D), blurRadius: 32, offset: Offset(0, 12))],
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.mail_outline_rounded, color: primary, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Email Notifications',
                          style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600, color: onSurface),
                        ),
                      ),
                      Switch(
                        value: _emailNotificationsEnabled,
                        activeThumbColor: primary,
                        activeTrackColor: primary.withOpacity(0.25),
                        onChanged: (v) => setState(() => _emailNotificationsEnabled = v),
                      ),
                    ],
                  ),
                  if (_emailNotificationsEnabled) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: surfaceLow,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'PRIMARY EMAIL ADDRESS',
                            style: GoogleFonts.epilogue(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: onSurfaceVar,
                              letterSpacing: 10 * 0.05,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            user.email,
                            style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w500, color: onSurface),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.check_circle_rounded, color: successGreen, size: 14),
                              const SizedBox(width: 6),
                              Text(
                                'Email notifications active',
                                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: successGreen),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            // WhatsApp Configuration card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surfaceWhite,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [BoxShadow(color: Color(0x0A191C1D), blurRadius: 32, offset: Offset(0, 12))],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.chat_bubble_outline_rounded, color: primary, size: 22),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'WhatsApp\nConfiguration',
                          style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600, color: onSurface),
                        ),
                      ),
                      _pill(
                        background: isConfigured ? const Color(0xFFE6F4EA) : const Color(0xFFFFEDEA),
                        child: Text(
                          isConfigured ? 'ACTIVE' : 'NOT CONFIGURED',
                          style: GoogleFonts.epilogue(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isConfigured ? successGreen : errorRed,
                            letterSpacing: 10 * 0.05,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (!isConfigured) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: surfaceLow,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline_rounded, color: primary, size: 16),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Configuration Required',
                                  style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w600, color: primary),
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  "To receive alerts via WhatsApp, you must send a message containing your API key to the callmebot contact first. This authorizes our system to send you automated reports.",
                                  style: GoogleFonts.plusJakartaSans(fontSize: 12, color: onSurfaceVar),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 16),
                  Text(
                    'WHATSAPP NUMBER',
                    style: GoogleFonts.epilogue(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: onSurfaceVar,
                      letterSpacing: 11 * 0.05,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _whatsappController,
                    keyboardType: TextInputType.phone,
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, color: onSurface),
                    decoration: _outlinedInput(
                      hintText: '+1234567890',
                      suffixIcon: IconButton(
                        onPressed: _isSavingWhatsapp ? null : () => _saveWhatsapp(user),
                        icon: _isSavingWhatsapp
                            ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                            : const Icon(Icons.save_outlined, color: onSurfaceVar),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'API KEY',
                    style: GoogleFonts.epilogue(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: onSurfaceVar,
                      letterSpacing: 11 * 0.05,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _apiKeyController,
                    obscureText: _obscureApiKey,
                    style: GoogleFonts.plusJakartaSans(fontSize: 14, color: onSurface),
                    decoration: _outlinedInput(
                      hintText: '••••••••••••••',
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            onPressed: () => setState(() => _obscureApiKey = !_obscureApiKey),
                            icon: Icon(_obscureApiKey ? Icons.visibility_rounded : Icons.visibility_off_rounded, color: onSurfaceVar, size: 20),
                          ),
                          IconButton(
                            onPressed: _isSavingApiKey ? null : () => _saveApiKey(user),
                            icon: _isSavingApiKey
                                ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.save_outlined, color: onSurfaceVar),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // 3) Danger Zone
            const SizedBox(height: 24),
            Text(
              'DANGER ZONE',
              style: GoogleFonts.epilogue(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: errorRed,
                letterSpacing: 11 * 0.05,
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xFFFFFBFA),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: errorRed.withOpacity(0.2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                   Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user.isActive ? 'Deactivate Account' : 'Activate Account',
                              style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600, color: onSurface),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              user.isActive 
                                ? 'The user will be unable to log in, but their data will be preserved.' 
                                : 'Grant the user access to login and manage their assigned channels.',
                              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: onSurfaceVar),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 16),
                      _secondaryCta(
                        label: user.isActive ? 'Deactivate' : 'Activate',
                        onTap: () async {
                          final confirmed = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              backgroundColor: surfaceWhite,
                              title: Text(user.isActive ? 'Deactivate User?' : 'Activate User?', style: GoogleFonts.publicSans(fontWeight: FontWeight.bold)),
                              content: Text(
                                user.isActive 
                                  ? 'Are you sure you want to deactivate ${user.email}? They will lose access immediately.' 
                                  : 'Do you want to restore access for ${user.email}?',
                                style: GoogleFonts.plusJakartaSans(),
                              ),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text('Cancel', style: GoogleFonts.plusJakartaSans(color: onSurfaceVar))),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  style: ElevatedButton.styleFrom(backgroundColor: user.isActive ? errorRed : successGreen, foregroundColor: Colors.white),
                                  child: Text(user.isActive ? 'Deactivate' : 'Activate'),
                                ),
                              ],
                            ),
                          );
                          if (confirmed == true) {
                            try {
                              if (user.isActive) {
                                await ref.read(userProvider.notifier).softDeleteUser(user.id);
                              } else {
                                await ref.read(userProvider.notifier).updateUser(user.id, UpdateUserRequest(isActive: true)); 
                              }
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(user.isActive ? 'Account deactivated' : 'Account activated', style: GoogleFonts.plusJakartaSans()),
                                  backgroundColor: user.isActive ? errorRed : successGreen,
                                ),
                              );
                            } catch (e) {
                              if (!mounted) return;
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(e.toString()), backgroundColor: errorRed));
                            }
                          }
                        },
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}
