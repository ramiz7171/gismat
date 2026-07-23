import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/buttons.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    Widget hero = Stack(
      alignment: Alignment.center,
      children: [
        for (final (i, size) in const [(0, 260.0), (1, 200.0), (2, 140.0)])
          Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.primary.withValues(alpha: 0.06 + i * 0.06),
            ),
          ),
        Container(
          width: 96,
          height: 96,
          decoration: BoxDecoration(
            gradient: AppColors.ctaGradient,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 32,
                  offset: const Offset(0, 12)),
            ],
          ),
          child:
              const Icon(Icons.favorite, color: AppColors.onPrimary, size: 44),
        ),
      ],
    );
    if (!reduceMotion) {
      hero = hero
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .scaleXY(begin: 0.97, end: 1.03, duration: 2400.ms, curve: Curves.easeInOut);
    }

    List<Widget> animateIn(List<Widget> children) {
      if (reduceMotion) return children;
      return children
          .mapIndexed((i, w) => w
              .animate(delay: (120 * i).ms)
              .fadeIn(duration: 350.ms, curve: Curves.easeOutCubic)
              .slideY(begin: 0.1, end: 0))
          .toList();
    }

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(AppSpacing.xl),
          child: Column(
            children: [
              const Spacer(),
              hero,
              const Spacer(),
              ...animateIn([
                Text('GISMAT',
                    textAlign: TextAlign.center,
                    style: AppTypography.display.copyWith(
                        letterSpacing: 6, color: AppColors.primaryDark)),
                const SizedBox(height: AppSpacing.sm),
                Text(l10n.welcomeTagline,
                    textAlign: TextAlign.center,
                    style: AppTypography.h3
                        .copyWith(color: AppColors.textSecondary)),
                const SizedBox(height: AppSpacing.xxl),
                PrimaryButton(
                    label: l10n.createAccount,
                    onPressed: () => context.push(Routes.register)),
                const SizedBox(height: AppSpacing.md),
                SecondaryButton(
                    label: l10n.signIn,
                    onPressed: () => context.push(Routes.signIn)),
                const SizedBox(height: AppSpacing.lg),
                _LegalLinks(l10n: l10n),
              ]),
            ],
          ),
        ),
      ),
    );
  }
}

extension<T> on List<T> {
  List<R> mapIndexed<R>(R Function(int, T) f) =>
      [for (var i = 0; i < length; i++) f(i, this[i])];
}

class _LegalLinks extends StatelessWidget {
  const _LegalLinks({required this.l10n});
  final AppLocalizations l10n;

  @override
  Widget build(BuildContext context) {
    return Text.rich(
      TextSpan(
        style: AppTypography.caption,
        children: [
          TextSpan(
            text: l10n.termsAndConditions,
            style: const TextStyle(
                color: AppColors.primaryDark,
                decoration: TextDecoration.underline),
            recognizer: TapGestureRecognizer()
              ..onTap = () => context.push(Routes.terms),
          ),
          const TextSpan(text: '   ·   '),
          TextSpan(
            text: l10n.privacyPolicy,
            style: const TextStyle(
                color: AppColors.primaryDark,
                decoration: TextDecoration.underline),
            recognizer: TapGestureRecognizer()
              ..onTap = () => context.push(Routes.privacy),
          ),
        ],
      ),
      textAlign: TextAlign.center,
    );
  }
}
