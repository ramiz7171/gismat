import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/buttons.dart';

class SafetyCenterScreen extends StatelessWidget {
  const SafetyCenterScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final tips = <(IconData, String)>[
      (Icons.storefront_outlined, l10n.safetyTip1),
      (Icons.group_outlined, l10n.safetyTip2),
      (Icons.money_off_outlined, l10n.safetyTip3),
      (Icons.chat_bubble_outline, l10n.safetyTip4),
      (Icons.flag_outlined, l10n.safetyTip5),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(l10n.safetyCenter)),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Text(l10n.safetyTipsTitle, style: AppTypography.h2),
            const SizedBox(height: AppSpacing.lg),
            for (final (icon, text) in tips) _TipCard(icon: icon, text: text),
            const SizedBox(height: AppSpacing.lg),
            SecondaryButton(
              label: l10n.privacyPolicy,
              icon: Icons.privacy_tip_outlined,
              onPressed: () => context.push(Routes.privacy),
            ),
            const SizedBox(height: AppSpacing.xl),
          ],
        ),
      ),
    );
  }
}

class _TipCard extends StatelessWidget {
  const _TipCard({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSpacing.md),
      padding: const EdgeInsets.all(AppSpacing.lg),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: const [
          BoxShadow(
              color: AppColors.cardShadow, blurRadius: 12, offset: Offset(0, 4)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: const BoxDecoration(
                color: AppColors.cyan50, shape: BoxShape.circle),
            child: Icon(icon, size: 22, color: AppColors.primaryDark),
          ),
          const SizedBox(width: AppSpacing.lg),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: AppSpacing.xs),
              child: Text(text, style: AppTypography.body),
            ),
          ),
        ],
      ),
    );
  }
}
