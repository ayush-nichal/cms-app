import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../providers/auth_provider.dart';

// Reuse tokens from LoginScreen for consistency
const surfaceWhite = Color(0xFFFFFFFF);
const primary = Color(0xFF005DAC);
const primaryAlt = Color(0xFF1976D2);
const onSurface = Color(0xFF191C1D);
const onSurfaceVar = Color(0xFF8A9099);
const errorRed = Color(0xFFB3261E);
const successGreen = Color(0xFF1A7A4A);

class ForgotPasswordDialog extends ConsumerStatefulWidget {
  const ForgotPasswordDialog({super.key});

  @override
  ConsumerState<ForgotPasswordDialog> createState() => _ForgotPasswordDialogState();
}

class _ForgotPasswordDialogState extends ConsumerState<ForgotPasswordDialog> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  bool _isLoading = false;
  bool _isSuccess = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authProvider.notifier).forgotPassword(_emailController.text.trim());
      if (mounted) {
        setState(() {
          _isLoading = false;
          _isSuccess = true;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = e.toString();
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isSuccess) {
      return _buildSuccessState();
    }

    return AlertDialog(
      backgroundColor: surfaceWhite,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      contentPadding: const EdgeInsets.fromLTRB(24, 32, 24, 24),
      content: SizedBox(
        width: 380,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Forgot Password?',
                style: GoogleFonts.publicSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w700,
                  color: onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Enter your email address and we will send you a secure link to reset your password.',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: onSurfaceVar,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 28),
              Text(
                'EMAIL ADDRESS',
                style: GoogleFonts.epilogue(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 11 * 0.05,
                  color: onSurfaceVar,
                ),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w400,
                  color: onSurface,
                ),
                decoration: _buildInputDecoration(
                  hintText: 'name@company.com',
                  prefixIcon: Icons.mail_outline_rounded,
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Required';
                  }
                  if (!RegExp(r'^.+@.+\..+$').hasMatch(value.trim())) {
                    return 'Invalid email';
                  }
                  return null;
                },
              ),
              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: errorRed,
                  ),
                ),
              ],
              const SizedBox(height: 32),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                      ),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: onSurfaceVar,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(99),
                        gradient: const LinearGradient(
                          colors: [primary, primaryAlt],
                        ),
                      ),
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _handleSubmit,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Send Link',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessState() {
    return AlertDialog(
      backgroundColor: surfaceWhite,
      surfaceTintColor: Colors.transparent,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      contentPadding: const EdgeInsets.all(32),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: successGreen.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.mark_email_read_outlined, color: successGreen, size: 32),
          ),
          const SizedBox(height: 24),
          Text(
            'Check your email',
            style: GoogleFonts.publicSans(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'If an account exists for email you entered, we have sent a reset link to it. Please check your inbox and spam folder.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: onSurfaceVar,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(99)),
                elevation: 0,
              ),
              child: Text(
                'Back to Login',
                style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
    );
  }

  InputDecoration _buildInputDecoration({required String hintText, required IconData prefixIcon}) {
    return InputDecoration(
      filled: true,
      fillColor: surfaceWhite,
      hintText: hintText,
      hintStyle: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        color: onSurfaceVar.withOpacity(0.5),
      ),
      prefixIcon: Icon(prefixIcon, color: onSurfaceVar, size: 20),
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
}
