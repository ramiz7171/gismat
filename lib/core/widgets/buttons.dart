import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Filled cyan-gradient CTA. States: default / pressed / disabled / loading.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.loading = false,
    this.icon,
    this.expand = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final bool expand;

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !loading;
    final child = DecoratedBox(
      decoration: BoxDecoration(
        gradient: enabled ? AppColors.ctaGradient : null,
        color: enabled ? null : AppColors.disabledFill,
        borderRadius: BorderRadius.circular(AppRadius.button),
        boxShadow: enabled
            ? [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ]
            : null,
      ),
      child: Material(
        type: MaterialType.transparency,
        child: InkWell(
          onTap: enabled ? onPressed : null,
          borderRadius: BorderRadius.circular(AppRadius.button),
          child: Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            alignment: Alignment.center,
            child: loading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        strokeWidth: 2.5, color: AppColors.onPrimary),
                  )
                : Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (icon != null) ...[
                        Icon(icon,
                            size: 20,
                            color: enabled
                                ? AppColors.onPrimary
                                : AppColors.textPrimary
                                    .withValues(alpha: 0.6)),
                        const SizedBox(width: AppSpacing.sm),
                      ],
                      Text(
                        label,
                        style: AppTypography.button.copyWith(
                          color: enabled
                              ? AppColors.onPrimary
                              : AppColors.textPrimary.withValues(alpha: 0.6),
                        ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
    return Semantics(
      button: true,
      enabled: enabled,
      label: label,
      child: expand ? SizedBox(width: double.infinity, child: child) : child,
    );
  }
}

/// Outlined cyan secondary button.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton(
      {super.key, required this.label, this.onPressed, this.icon});

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: icon == null
          ? OutlinedButton(onPressed: onPressed, child: Text(label))
          : OutlinedButton.icon(
              onPressed: onPressed, icon: Icon(icon, size: 20), label: Text(label)),
    );
  }
}

/// Circular icon action under the deck (Pass / Poke / Like).
class IconCircleButton extends StatelessWidget {
  const IconCircleButton({
    super.key,
    required this.icon,
    required this.onPressed,
    required this.semanticLabel,
    this.color = AppColors.primary,
    this.background = AppColors.surface,
    this.size = 60,
  });

  final IconData icon;
  final VoidCallback? onPressed;
  final String semanticLabel;
  final Color color;
  final Color background;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: background,
        shape: const CircleBorder(),
        elevation: 3,
        shadowColor: AppColors.cardShadow,
        child: InkWell(
          onTap: onPressed,
          customBorder: const CircleBorder(),
          child: SizedBox(
            width: size,
            height: size,
            child: Icon(icon, color: color, size: size * 0.45),
          ),
        ),
      ),
    );
  }
}
