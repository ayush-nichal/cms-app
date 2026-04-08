import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/design/design_tokens.dart';
import '../../platforms/data/platform_model.dart';
import '../../platforms/providers/platform_provider.dart';

class EditChannelScreen extends ConsumerStatefulWidget {
  final Platform platform;
  final Channel channel;

  const EditChannelScreen({
    super.key,
    required this.platform,
    required this.channel,
  });

  @override
  ConsumerState<EditChannelScreen> createState() => _EditChannelScreenState();
}

class _EditChannelScreenState extends ConsumerState<EditChannelScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _currentNameController = TextEditingController(text: widget.channel.name);
  final _newNameController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _currentNameController.dispose();
    _newNameController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration({String? hintText, Widget? suffixIcon, bool enabled = true}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.plusJakartaSans(fontSize: 14, color: onSurfaceVar),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: surfaceWhite,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      enabled: enabled,
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

  Widget _primaryButton({required String label, required VoidCallback onTap}) {
    return InkWell(
      borderRadius: BorderRadius.circular(9999),
      onTap: _isSubmitting ? null : onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
        decoration: BoxDecoration(
          gradient: primaryGradient,
          borderRadius: BorderRadius.circular(9999),
          boxShadow: const [
            BoxShadow(color: Color(0x0A191C1D), blurRadius: 32, offset: Offset(0, 12)),
          ],
        ),
        child: Center(
          child: _isSubmitting
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
                )
              : Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600, color: Colors.white),
                ),
        ),
      ),
    );
  }

  Widget _secondaryButton({required String label, required VoidCallback onTap}) {
    return SizedBox(
      width: double.infinity,
      child: OutlinedButton(
        onPressed: _isSubmitting ? null : onTap,
        style: OutlinedButton.styleFrom(
          side: const BorderSide(color: outlineGhost),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9999)),
          padding: const EdgeInsets.symmetric(vertical: 16),
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w600, color: onSurface),
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    final newName = _newNameController.text.trim();
    setState(() => _isSubmitting = true);
    try {
      await ref.read(platformProvider.notifier).updateChannel(
            widget.channel.id,
            widget.platform.id,
            newName,
            widget.channel.handle,
          );
      if (!mounted) return;
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Channel updated', style: GoogleFonts.plusJakartaSans())),
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
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
          'Edit Channel',
          style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w600, color: primary),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 24),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: surfaceWhite,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Color(0x0A191C1D), blurRadius: 32, offset: Offset(0, 12)),
                ],
              ),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CHANNEL SETTINGS', style: labelCapsTextStyle(fontSize: 11, color: onSurfaceVar)),
                    const SizedBox(height: 4),
                    Text('Rename Channel', style: headlineTextStyle(fontSize: 24, fontWeight: FontWeight.w700)),
                    const SizedBox(height: 8),
                    Text(
                      'Update your channel details to better align with your current content strategy.',
                      style: bodyTextStyle(fontSize: 14, color: onSurfaceVar),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Current Channel Name',
                      style: bodyTextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: onSurface),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _currentNameController,
                      readOnly: true,
                      style: bodyTextStyle(fontSize: 14, color: onSurfaceVar),
                      decoration: _inputDecoration(
                        enabled: false,
                        suffixIcon: const Icon(Icons.lock_outline, color: onSurfaceVar),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'New Channel Name',
                      style: bodyTextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: onSurface),
                    ),
                    const SizedBox(height: 8),
                    TextFormField(
                      controller: _newNameController,
                      style: bodyTextStyle(fontSize: 14, color: onSurface),
                      decoration: _inputDecoration(hintText: 'Enter new name'),
                      validator: (value) {
                        final v = value?.trim() ?? '';
                        if (v.length < 2) return 'Name must be at least 2 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Visible to all subscribers and across the library analytics.',
                      style: bodyTextStyle(fontSize: 12, color: onSurfaceVar, fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 24),
                    _primaryButton(label: 'Save Changes', onTap: _submit),
                    const SizedBox(height: 12),
                    _secondaryButton(label: 'Cancel', onTap: () => context.pop()),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: surfaceLow,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.info_outline_rounded, color: onSurfaceVar, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Propagation Delay',
                          style: bodyTextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: onSurface),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Name changes may take up to 24 hours to reflect across all connected library and analytics modules.',
                          style: bodyTextStyle(fontSize: 13, color: onSurfaceVar),
                        ),
                      ],
                    ),
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

