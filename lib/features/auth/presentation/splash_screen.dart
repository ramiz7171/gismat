import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_typography.dart';

/// Animated logo splash shown while the auth gate resolves; go_router
/// redirects away automatically once the gate settles.
class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    Widget logo = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            gradient: AppColors.ctaGradient,
            borderRadius: BorderRadius.circular(28),
            boxShadow: [
              BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.4),
                  blurRadius: 32,
                  offset: const Offset(0, 12)),
            ],
          ),
          child: const Icon(Icons.favorite, color: AppColors.onPrimary, size: 48),
        ),
        const SizedBox(height: 24),
        Text('GISMAT',
            style: AppTypography.display
                .copyWith(letterSpacing: 6, color: AppColors.primaryDark)),
      ],
    );
    if (!reduceMotion) {
      logo = logo
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scaleXY(begin: 0.96, end: 1.04, duration: 1200.ms, curve: Curves.easeInOut);
    }
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Center(child: logo),
    );
  }
}
