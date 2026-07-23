import 'package:flutter/material.dart';

import 'app_colors.dart';

/// Inter type scale. Bundled font (assets/fonts) with google_fonts parity —
/// the family name matches so no runtime fetch is needed.
abstract final class AppTypography {
  static const String fontFamily = 'Inter';

  static const TextStyle display = TextStyle(
      fontFamily: fontFamily, fontSize: 32, height: 40 / 32,
      fontWeight: FontWeight.w700, letterSpacing: -0.5,
      color: AppColors.textPrimary);
  static const TextStyle h1 = TextStyle(
      fontFamily: fontFamily, fontSize: 28, height: 36 / 28,
      fontWeight: FontWeight.w700, letterSpacing: -0.4,
      color: AppColors.textPrimary);
  static const TextStyle h2 = TextStyle(
      fontFamily: fontFamily, fontSize: 22, height: 28 / 22,
      fontWeight: FontWeight.w600, letterSpacing: -0.3,
      color: AppColors.textPrimary);
  static const TextStyle h3 = TextStyle(
      fontFamily: fontFamily, fontSize: 18, height: 24 / 18,
      fontWeight: FontWeight.w600, letterSpacing: -0.2,
      color: AppColors.textPrimary);
  static const TextStyle bodyLarge = TextStyle(
      fontFamily: fontFamily, fontSize: 16, height: 24 / 16,
      fontWeight: FontWeight.w400, color: AppColors.textPrimary);
  static const TextStyle body = TextStyle(
      fontFamily: fontFamily, fontSize: 14, height: 20 / 14,
      fontWeight: FontWeight.w400, color: AppColors.textPrimary);
  static const TextStyle caption = TextStyle(
      fontFamily: fontFamily, fontSize: 12, height: 16 / 12,
      fontWeight: FontWeight.w400, color: AppColors.textSecondary);
  static const TextStyle button = TextStyle(
      fontFamily: fontFamily, fontSize: 16, height: 20 / 16,
      fontWeight: FontWeight.w600);

  static TextTheme get textTheme => const TextTheme(
        displaySmall: display,
        headlineMedium: h1,
        headlineSmall: h2,
        titleMedium: h3,
        bodyLarge: bodyLarge,
        bodyMedium: body,
        bodySmall: caption,
        labelLarge: button,
      );
}
