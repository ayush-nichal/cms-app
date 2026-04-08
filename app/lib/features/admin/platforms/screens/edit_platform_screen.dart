import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/design/design_tokens.dart';
import '../data/platform_model.dart';
import '../providers/platform_provider.dart';

class EditPlatformScreen extends ConsumerStatefulWidget {
  final Platform platform;

  const EditPlatformScreen({super.key, required this.platform});

  @override
  ConsumerState<EditPlatformScreen> createState() => _EditPlatformScreenState();
}

class _EditPlatformScreenState extends ConsumerState<EditPlatformScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController = TextEditingController(text: widget.platform.name);
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration() {
    return InputDecoration(
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

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      await ref.read(platformProvider.notifier).updatePlatform(widget.platform.id, _nameController.text.trim());
      if (!mounted) return;
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Platform updated', style: GoogleFonts.plusJakartaSans())),
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
          icon: const Icon(Icons.arrow_back_rounded, color: onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Edit Platform',
          style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w600, color: onSurface),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 28),
            Text('Edit Platform', style: displayTextStyle(fontSize: 28, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              'Update your platform identity and configuration.',
              style: bodyTextStyle(fontSize: 14, color: onSurfaceVar),
            ),
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
                    Text('PLATFORM NAME', style: labelCapsTextStyle(fontSize: 11)),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _nameController,
                      style: bodyTextStyle(fontSize: 14, color: onSurface),
                      decoration: _inputDecoration(),
                      validator: (value) {
                        final v = value?.trim() ?? '';
                        if (v.length < 2) return 'Name must be at least 2 characters';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: surfaceLow,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: surfaceWhite,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(getPlatformIcon(widget.platform.name), color: primary, size: 22),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('VISUAL IDENTITY', style: labelCapsTextStyle(fontSize: 11, color: onSurfaceVar)),
                                const SizedBox(height: 6),
                                Text(
                                  'The system will automatically sync these changes across all connected sub-modules.',
                                  style: bodyTextStyle(fontSize: 13, color: onSurface),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            _primaryCta(label: 'Save Changes', onTap: _submit),
            const SizedBox(height: 12),
            Center(
              child: TextButton(
                onPressed: _isSubmitting ? null : () => context.pop(),
                child: Text(
                  'CANCEL',
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600, color: onSurfaceVar),
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

