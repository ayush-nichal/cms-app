import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/design/design_tokens.dart';
import '../providers/platform_provider.dart';

class AddPlatformScreen extends ConsumerStatefulWidget {
  const AddPlatformScreen({super.key});

  @override
  ConsumerState<AddPlatformScreen> createState() => _AddPlatformScreenState();
}

class _AddPlatformScreenState extends ConsumerState<AddPlatformScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration({required String hintText}) {
    return InputDecoration(
      hintText: hintText,
      hintStyle: GoogleFonts.plusJakartaSans(fontSize: 14, color: onSurfaceVar),
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

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      await ref.read(platformProvider.notifier).createPlatform(_nameController.text.trim());
      if (!mounted) return;
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Platform created', style: GoogleFonts.plusJakartaSans())),
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

  Widget _primaryCta({required String label, required VoidCallback onTap}) {
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
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (_isSubmitting) ...[
              const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2, valueColor: AlwaysStoppedAnimation<Color>(Colors.white)),
              ),
              const SizedBox(width: 10),
            ],
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
          'Add Platform',
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
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: surfaceWhite,
                borderRadius: BorderRadius.circular(16),
                boxShadow: const [
                  BoxShadow(color: Color(0x0A191C1D), blurRadius: 32, offset: Offset(0, 12)),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Add New Platform', style: displayTextStyle(fontSize: 26, fontWeight: FontWeight.w700)),
                  const SizedBox(height: 8),
                  Text(
                    'Define your platform identity to start aggregating multi-channel metrics.',
                    style: bodyTextStyle(fontSize: 14, color: onSurfaceVar),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
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
                    Text('PLATFORM NAME', style: labelCapsTextStyle(fontSize: 11)),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameController,
                      style: bodyTextStyle(fontSize: 14, color: onSurface),
                      decoration: _inputDecoration(hintText: 'e.g. Marketing Dashboard HQ'),
                      validator: (value) {
                        final v = value?.trim() ?? '';
                        if (v.length < 2) return 'Name must be at least 2 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'This name will be visible to all assigned administrators.',
                      style: bodyTextStyle(fontSize: 12, color: onSurfaceVar, fontStyle: FontStyle.italic),
                    ),
                    const SizedBox(height: 24),
                    _primaryCta(label: 'Save Platform', onTap: _submit),
                    const SizedBox(height: 12),
                    Center(
                      child: TextButton(
                        onPressed: _isSubmitting ? null : () => context.pop(),
                        child: Text('Cancel', style: bodyTextStyle(fontSize: 16, fontWeight: FontWeight.w600, color: primary)),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

