import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// Color Tokens
const surface = Color(0xFFF8FAFB); // Page background canvas
const surfaceLow = Color(0xFFF2F4F5); // Secondary regions
const surfaceWhite = Color(0xFFFFFFFF); // Floating cards
const primary = Color(0xFF005DAC); // Brand blue
const primaryAlt = Color(0xFF1976D2); // Gradient end blue
const onSurface = Color(0xFF191C1D); // Primary text — NEVER use pure black
const onSurfaceVar = Color(0xFF8A9099); // Secondary / muted text
const outlineGhost = Color(0x26C1C6D4); // Ghost border at 15% opacity
const errorRed = Color(0xFFB3261E); // Destructive actions
const successGreen = Color(0xFF1A7A4A); // Success states

// Typography helpers (consistent across the admin suite)
TextStyle displayTextStyle({
  double fontSize = 28,
  FontWeight fontWeight = FontWeight.w700,
  Color color = onSurface,
}) {
  return GoogleFonts.publicSans(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
  );
}

TextStyle headlineTextStyle({
  double fontSize = 24,
  FontWeight fontWeight = FontWeight.w600,
  Color color = onSurface,
}) {
  return GoogleFonts.publicSans(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
  );
}

TextStyle bodyTextStyle({
  double fontSize = 14,
  FontWeight fontWeight = FontWeight.w400,
  Color color = onSurface,
  FontStyle? fontStyle,
}) {
  return GoogleFonts.plusJakartaSans(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    fontStyle: fontStyle,
  );
}

TextStyle labelCapsTextStyle({
  double fontSize = 11,
  FontWeight fontWeight = FontWeight.w500,
  Color color = onSurfaceVar,
  double letterSpacingEm = 0.05,
}) {
  return GoogleFonts.epilogue(
    fontSize: fontSize,
    fontWeight: fontWeight,
    color: color,
    letterSpacing: fontSize * letterSpacingEm,
  );
}

// Primary CTA gradient (top-left to bottom-right)
const primaryGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [Color(0xFF005DAC), Color(0xFF1976D2)],
);

Color getPlatformGradientStart(String platformName) {
  final name = platformName.toLowerCase();
  if (name.contains('youtube')) return const Color(0xFFFF4B4B);
  if (name.contains('instagram')) return const Color(0xFFF58529);
  if (name.contains('linkedin')) return const Color(0xFF0A66C2);
  if (name.contains('tiktok')) return const Color(0xFF010101);
  if (name.contains('facebook')) return const Color(0xFF1877F2);
  if (name.contains('telegram')) return const Color(0xFF26A5E4);
  if (name.contains('twitter') || name == 'x' || name.contains(' x ')) return const Color(0xFF1DA1F2);
  return primary; // Default
}

Color getPlatformGradientEnd(String platformName) {
  final name = platformName.toLowerCase();
  if (name.contains('youtube')) return const Color(0xFFFF0000);
  if (name.contains('instagram')) return const Color(0xFF8134AF);
  if (name.contains('linkedin')) return const Color(0xFF0077B5);
  if (name.contains('tiktok')) return const Color(0xFFEE1D52);
  if (name.contains('facebook')) return const Color(0xFF0C5CBF);
  if (name.contains('telegram')) return const Color(0xFF229ED9);
  if (name.contains('twitter') || name == 'x' || name.contains(' x ')) return const Color(0xFF0D8ECF);
  return primaryAlt; // Default
}

LinearGradient getPlatformGradient(String platformName) {
  final name = platformName.toLowerCase();
  if (name.contains('instagram')) {
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFFF58529), Color(0xFFDD2A7B), Color(0xFF8134AF)],
    );
  }
  if (name.contains('tiktok')) {
    return const LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [Color(0xFF010101), Color(0xFF69C9D0), Color(0xFFEE1D52)],
    );
  }
  return LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [getPlatformGradientStart(platformName), getPlatformGradientEnd(platformName)],
  );
}

IconData getPlatformIcon(String platformName) {
  final name = platformName.toLowerCase();
  if (name.contains('youtube')) return Icons.play_circle_filled_rounded;
  if (name.contains('instagram')) return Icons.camera_alt_rounded;
  if (name.contains('linkedin')) return Icons.work_rounded;
  if (name.contains('tiktok')) return Icons.music_note_rounded;
  if (name.contains('facebook')) return Icons.facebook_rounded;
  if (name.contains('telegram')) return Icons.send_rounded;
  if (name.contains('twitter') || name == 'x' || name.contains(' x ')) return Icons.tag_rounded;
  return Icons.public_rounded;
}

