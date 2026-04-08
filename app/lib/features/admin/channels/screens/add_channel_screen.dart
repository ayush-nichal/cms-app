import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/design/design_tokens.dart';
import '../../platforms/data/platform_model.dart';
import '../../platforms/providers/platform_provider.dart';

class AddChannelScreen extends ConsumerStatefulWidget {
  final Platform platform;

  const AddChannelScreen({super.key, required this.platform});

  @override
  ConsumerState<AddChannelScreen> createState() => _AddChannelScreenState();
}

class _AddChannelScreenState extends ConsumerState<AddChannelScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _platformController = TextEditingController(text: widget.platform.name);
  final _nameController = TextEditingController();
  final _handleController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _platformController.dispose();
    _nameController.dispose();
    _handleController.dispose();
    super.dispose();
  }

  InputDecoration _inputDecoration({required String? hintText}) {
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

  Future<void> _submit() async {
    if (_isSubmitting) return;
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    try {
      final handleValue = _handleController.text.trim();
      final finalHandle = handleValue.startsWith('@') ? handleValue : '@$handleValue';
      await ref.read(platformProvider.notifier).createChannel(
            widget.platform.id,
            _nameController.text.trim(),
            finalHandle,
          );
      if (!mounted) return;
      context.pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Channel created', style: GoogleFonts.plusJakartaSans())),
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
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: onSurface),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'New Channel',
          style: GoogleFonts.publicSans(fontSize: 18, fontWeight: FontWeight.w600, color: onSurface),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Padding(
          padding: const EdgeInsets.only(top: 20),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                TextFormField(
                  controller: _platformController,
                  readOnly: true,
                  style: bodyTextStyle(fontSize: 14, color: onSurface),
                  decoration: _inputDecoration(hintText: null).copyWith(labelText: 'Platform'),
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nameController,
                  style: bodyTextStyle(fontSize: 14, color: onSurface),
                  decoration: _inputDecoration(hintText: 'Channel Name'),
                  validator: (value) {
                    if ((value?.trim() ?? '').isEmpty) return 'Channel name is required';
                    return null;
                  },
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _handleController,
                  style: bodyTextStyle(fontSize: 14, color: onSurface),
                  decoration: _inputDecoration(hintText: 'Handle'),
                  validator: (value) {
                    if ((value?.trim() ?? '').isEmpty) return 'Handle is required';
                    return null;
                  },
                ),
                const SizedBox(height: 24),
                _primaryButton(label: 'Save Channel', onTap: _submit),
                const SizedBox(height: 40),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

