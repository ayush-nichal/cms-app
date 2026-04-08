import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../providers/auth_provider.dart';
import '../widgets/forgot_password_dialog.dart';

// Color Tokens
const surface = Color(0xFFF8FAFB);
const surfaceLow = Color(0xFFF2F4F5);
const surfaceWhite = Color(0xFFFFFFFF);
const primary = Color(0xFF005DAC);
const primaryAlt = Color(0xFF1976D2);
const onSurface = Color(0xFF191C1D);
const onSurfaceVar = Color(0xFF8A9099);
const outlineGhost = Color(0x26C1C6D4);
const errorRed = Color(0xFFB3261E);
const successGreen = Color(0xFF1A7A4A);

// Typography Tokens
TextStyle displayStyle() => GoogleFonts.publicSans(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      color: onSurface,
    );

TextStyle labelCapsStyle() => GoogleFonts.epilogue(
      fontSize: 11,
      fontWeight: FontWeight.w500,
      letterSpacing: 11 * 0.05, // 0.05em
      color: onSurfaceVar,
    );

TextStyle bodySmallStyle() => GoogleFonts.plusJakartaSans(
      fontSize: 12,
      fontWeight: FontWeight.w400,
      color: onSurfaceVar,
    );

TextStyle buttonTextStyle() => GoogleFonts.plusJakartaSans(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: Colors.white,
    );

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _errorMessage = null;
    });

    try {
      await ref.read(authProvider.notifier).login(
            _emailController.text.trim(),
            _passwordController.text,
          );

      final state = ref.read(authProvider);

      if (state.hasError) {
        if (mounted) {
          setState(() {
            _errorMessage = state.error.toString();
          });
        }
        return;
      }

      final user = state.value;
      if (user != null) {
        if (user.role == 'admin') {
          if (mounted) context.go('/admin');
        } else {
          if (mounted) context.go('/user');
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Login failed: $e";
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = authState.isLoading;

    return Scaffold(
      backgroundColor: surface,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // 1. Top Section
              Text(
                'ContentHive',
                style: displayStyle(),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                'ENTERPRISE ANALYTICS PORTAL',
                style: GoogleFonts.epilogue(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 11 * 0.08, // 0.08em
                  color: onSurfaceVar,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 40),

              // 2. Login Card
              Container(
                decoration: BoxDecoration(
                  color: surfaceWhite,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A191C1D),
                      blurRadius: 32,
                      offset: Offset(0, 12),
                    ),
                  ],
                ),
                padding: const EdgeInsets.all(32),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // EMAIL LABEL
                      Text(
                        'EMAIL',
                        style: labelCapsStyle(),
                      ),
                      const SizedBox(height: 8),
                      // Email Field
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: onSurface,
                        ),
                        decoration: _buildInputDecoration(
                          prefixIcon: Icons.mail_outline_rounded,
                        ).copyWith(
                          hintText: 'name@company.com',
                          hintStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: onSurfaceVar.withOpacity(0.5),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Please enter your email';
                          }
                          if (!RegExp(r'^.+@.+\..+$').hasMatch(value.trim())) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // PASSWORD LABEL & FORGOT
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'PASSWORD',
                            style: labelCapsStyle(),
                          ),
                          TextButton(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (context) => const ForgotPasswordDialog(),
                              );
                            },
                            style: TextButton.styleFrom(
                              foregroundColor: primary,
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                            child: Text(
                              'Forgot?',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: primary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      // Password Field
                      TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _handleLogin(),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w400,
                          color: onSurface,
                        ),
                        decoration: _buildInputDecoration(
                          prefixIcon: Icons.lock_outline_rounded,
                        ).copyWith(
                          hintText: '••••••••',
                          hintStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w400,
                            color: onSurfaceVar.withOpacity(0.5),
                          ),
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                              color: onSurfaceVar,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Please enter your password';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 28),

                      // Primary CTA Button
                      Container(
                        width: double.infinity,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(9999),
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [primary, primaryAlt],
                          ),
                        ),
                        child: Material(
                          color: Colors.transparent,
                          child: InkWell(
                            borderRadius: BorderRadius.circular(9999),
                            onTap: isLoading ? null : _handleLogin,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(
                                vertical: 16,
                                horizontal: 24,
                              ),
                              child: Center(
                                child: isLoading
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          Text(
                                            'Login',
                                            style: buttonTextStyle(),
                                          ),
                                          const SizedBox(width: 8),
                                          const Icon(
                                            Icons.arrow_forward_rounded,
                                            color: Colors.white,
                                            size: 20,
                                          ),
                                        ],
                                      ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      // Error Message
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 16),
                        Center(
                          child: Text(
                            _errorMessage!,
                            style: bodySmallStyle().copyWith(color: errorRed),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // 3. Footer Links
              Text(
                'PRIVACY POLICY  ·  SYSTEM STATUS',
                style: labelCapsStyle(),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),

              // 4. Page Footer
              Text(
                'ContentHive',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontStyle: FontStyle.italic,
                  color: onSurfaceVar,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),
              Text(
                '© 2024 CONTENTHIVE. ALL RIGHTS RESERVED.',
                style: GoogleFonts.epilogue(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  letterSpacing: 10 * 0.05,
                  color: onSurfaceVar,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _buildInputDecoration({required IconData prefixIcon}) {
    return InputDecoration(
      filled: true,
      fillColor: surfaceWhite,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      prefixIcon: Icon(prefixIcon, color: onSurfaceVar),
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorRed),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: errorRed, width: 2),
      ),
    );
  }
}
