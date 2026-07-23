import 'package:flutter/material.dart';

/// GISMAT cyan-forward palette. Single source of truth for every color.
abstract final class AppColors {
  // Brand cyan
  static const Color primary = Color(0xFF00BCD4); // cyan 500
  static const Color primaryDark = Color(0xFF0097A7); // pressed
  static const Color primaryDarker = Color(0xFF00838F);
  static const Color cyan100 = Color(0xFFB2EBF2);
  static const Color cyan50 = Color(0xFFE0F7FA);
  static const Color cyanBright = Color(0xFF00E5FF); // gradient start

  // Poke accent — coral pops against cyan (see docs/DECISIONS.md)
  static const Color poke = Color(0xFFFF6F61);
  static const Color pokeDark = Color(0xFFE85C4F);

  // Surfaces
  static const Color surface = Color(0xFFFFFFFF);
  static const Color background = Color(0xFFF7FAFB);
  static const Color card = Color(0xFFFFFFFF);
  static const Color cardShadow = Color(0x14000000); // rgba(0,0,0,0.08)

  // Text
  static const Color textPrimary = Color(0xFF0E1B1F);
  static const Color textSecondary = Color(0xFF5B6B70);
  static const Color onPrimary = Color(0xFFFFFFFF);

  // Semantic
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFF9A825);
  static const Color error = Color(0xFFD32F2F);

  // Misc
  static const Color online = Color(0xFF4CAF50);
  static const Color nope = Color(0xFF9E9E9E);
  static const Color divider = Color(0xFFE5EDEF);
  static const Color disabledFill = cyan100;

  static const LinearGradient ctaGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [cyanBright, primary, primaryDark],
  );

  /// Bottom scrim over deck photos for name/age legibility.
  static const LinearGradient cardScrim = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    stops: [0.45, 1.0],
    colors: [Colors.transparent, Color(0xA6000000)], // → rgba(0,0,0,0.65)
  );
}
