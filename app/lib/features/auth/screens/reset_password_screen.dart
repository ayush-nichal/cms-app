import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../../../shared/design/design_tokens.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String? token;

  const ResetPasswordScreen({super.key, this.token});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isSuccess = false;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _handleReset() async {
    if (!_formKey.currentState!.validate()) return;
    if (widget.token == null) {
      setState(() => _errorMessage = 'Invalid or missing reset token.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      await ref.read(authProvider.notifier).resetPassword(
            token: widget.token!,
            newPassword: _passwordController.text.trim(),
          );
      setState(() {
        _isLoading = false;
        _isSuccess = true;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
        _errorMessage = e.toString().replaceAll('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isSuccess) {
      return _buildSuccessView();
    }

    return Scaffold(
      backgroundColor: surface,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 400),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(Icons.lock_reset_rounded, size: 80, color: primary),
                  const SizedBox(height: 24),
                  Text(
                    'Reset Password',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.publicSans(
                      fontSize: 32,
                      fontWeight: FontWeight.w700,
                      color: onSurface,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please enter a new password to secure your account.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: onSurfaceVar,
                    ),
                  ),
                  const SizedBox(height: 32),
                  if (_errorMessage != null)
                    Container(
                      padding: const EdgeInsets.all(12),
                      margin: const EdgeInsets.only(bottom: 24),
                      decoration: BoxDecoration(
                        color: errorRed.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: errorRed.withOpacity(0.3)),
                      ),
                      child: Text(
                        _errorMessage!,
                        style: GoogleFonts.plusJakartaSans(
                          color: errorRed,
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                  Text(
                    'NEW PASSWORD',
                    style: GoogleFonts.epilogue(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: onSurfaceVar,
                      letterSpacing: 11 * 0.05,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    style: GoogleFonts.plusJakartaSans(fontSize: 14),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: surfaceWhite,
                      hintText: 'Enter new password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                          size: 20,
                        ),
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0x66C1C6D4)),
                      ),
                    ),
                    validator: (v) => (v == null || v.length < 6) ? 'Password must be at least 6 characters' : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'CONFIRM PASSWORD',
                    style: GoogleFonts.epilogue(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: onSurfaceVar,
                      letterSpacing: 11 * 0.05,
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _confirmPasswordController,
                    obscureText: _obscurePassword,
                    style: GoogleFonts.plusJakartaSans(fontSize: 14),
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: surfaceWhite,
                      hintText: 'Re-type new password',
                      prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: const BorderSide(color: Color(0x66C1C6D4)),
                      ),
                    ),
                    validator: (v) => v != _passwordController.text ? 'Passwords do not match' : null,
                  ),
                  const SizedBox(height: 32),
                  SizedBox(
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handleReset,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : const Text('Update Password', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/login'),
                    child: Text(
                      'Back to Login',
                      style: GoogleFonts.plusJakartaSans(
                        color: primary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSuccessView() {
    return Scaffold(
      backgroundColor: surface,
      body: Padding(
        padding: const EdgeInsets.all(32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_circle_rounded, size: 100, color: successGreen),
            const SizedBox(height: 24),
            Text(
              'Password Updated!',
              style: GoogleFonts.publicSans(
                fontSize: 32,
                fontWeight: FontWeight.w700,
                color: onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Your password has been reset successfully. You can now log in with your new credentials.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: onSurfaceVar,
              ),
            ),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => context.go('/login'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: const Text('Go to Login', style: TextStyle(fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Simple helper for platform specific border radius (just using 12 for consistency here)
class RoundedRectanglePlatform {
  static BorderRadius borderRadius(double r) => BorderRadius.circular(r);
}
