import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/error/error_l10n.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/common.dart';
import '../../auth/presentation/session_providers.dart';
import '../../profile/domain/profile.dart';
import 'subscription_providers.dart';

/// Premium paywall. Tier limits are 100% DB-driven via [tierLimitsProvider];
/// only the weekly prices are client-side. Upgrading opens Stripe Checkout in
/// an external browser — the actual tier change lands via webhook.
class PaywallScreen extends ConsumerStatefulWidget {
  const PaywallScreen({super.key});

  @override
  ConsumerState<PaywallScreen> createState() => _PaywallScreenState();
}

class _PaywallScreenState extends ConsumerState<PaywallScreen> {
  static const _tierOrder = ['basic', 'pro', 'max'];

  /// 'pro' | 'max' while a checkout is being created, 'portal' for the
  /// billing portal, null when idle.
  String? _busy;

  Future<void> _upgrade(String tier) async {
    if (_busy != null) return;
    setState(() => _busy = tier);
    try {
      final url = await ref
          .read(subscriptionRepositoryProvider)
          .createCheckoutSession(tier);
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) showAppError(context, e);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  Future<void> _openPortal() async {
    if (_busy != null) return;
    setState(() => _busy = 'portal');
    try {
      final url =
          await ref.read(subscriptionRepositoryProvider).createPortalSession();
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (e) {
      if (mounted) showAppError(context, e);
    } finally {
      if (mounted) setState(() => _busy = null);
    }
  }

  String _tierName(AppLocalizations l10n, String tier) => switch (tier) {
        'pro' => l10n.tierPro,
        'max' => l10n.tierMax,
        _ => l10n.tierBasic,
      };

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final limitsAsync = ref.watch(tierLimitsProvider);
    final profile = ref.watch(myProfileProvider).valueOrNull;
    final subscription = ref.watch(mySubscriptionProvider).valueOrNull;
    final currentTier = profile?.tier ?? 'basic';
    final reduceMotion = MediaQuery.of(context).disableAnimations;

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(title: Text(l10n.subscriptionTitle)),
      body: limitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, _) => EmptyState(
          icon: Icons.wifi_off,
          title: l10n.errorLoadFailed,
          actionLabel: l10n.retry,
          onAction: () => ref.invalidate(tierLimitsProvider),
        ),
        data: (limits) {
          final sorted = [...limits]..sort((a, b) => _tierOrder
              .indexOf(a.tier)
              .compareTo(_tierOrder.indexOf(b.tier)));
          final hasActiveSub = subscription != null &&
              (subscription['status'] as String?) == 'active';

          final children = <Widget>[
            Text(
              '${l10n.currentPlan}: ${_tierName(l10n, currentTier)}',
              style: AppTypography.caption,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: AppSpacing.lg),
            for (final limit in sorted) ...[
              _TierCard(
                limit: limit,
                name: _tierName(l10n, limit.tier),
                isCurrent: limit.tier == currentTier,
                busy: _busy == limit.tier,
                onUpgrade:
                    limit.tier == 'basic' ? null : () => _upgrade(limit.tier),
              ),
              const SizedBox(height: AppSpacing.lg),
            ],
            const SizedBox(height: AppSpacing.sm),
            Text(
              l10n.noTrialNoRefund,
              style: AppTypography.caption,
              textAlign: TextAlign.center,
            ),
            if (hasActiveSub) ...[
              const SizedBox(height: AppSpacing.lg),
              SecondaryButton(
                label: l10n.manageSubscription,
                icon: Icons.credit_card,
                onPressed: _busy == null ? _openPortal : null,
              ),
            ],
            const SizedBox(height: AppSpacing.xxl),
          ];

          if (!reduceMotion) {
            for (var i = 0; i < children.length; i++) {
              children[i] = children[i]
                  .animate(delay: (60 * i).ms)
                  .fadeIn(duration: 300.ms, curve: Curves.easeOutCubic)
                  .slideY(begin: 0.06, end: 0, curve: Curves.easeOutCubic);
            }
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg, AppSpacing.lg, AppSpacing.lg, AppSpacing.lg),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: children,
            ),
          );
        },
      ),
    );
  }
}

class _TierCard extends StatelessWidget {
  const _TierCard({
    required this.limit,
    required this.name,
    required this.isCurrent,
    required this.busy,
    required this.onUpgrade,
  });

  final TierLimit limit;
  final String name;
  final bool isCurrent;
  final bool busy;
  final VoidCallback? onUpgrade;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final highlighted = limit.tier == 'pro';
    final price = switch (limit.tier) {
      'pro' => l10n.perWeek('3'),
      'max' => l10n.perWeek('5'),
      _ => l10n.free,
    };
    // Feature lines come straight from the DB-driven TierLimit — never
    // hardcode swipe/photo numbers here.
    final features = <String>[
      limit.dailySwipeLimit == null
          ? l10n.unlimitedSwipes
          : l10n.swipesPerDay(limit.dailySwipeLimit!),
      l10n.upToPhotos(limit.maxPhotos),
      if (limit.tier != 'basic') l10n.rewindFeature,
      if (limit.tier != 'basic') l10n.readReceipts,
    ];

    final inner = Container(
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(AppRadius.card - 2),
      ),
      padding: const EdgeInsets.all(AppSpacing.xl),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(name, style: AppTypography.h2)),
              if (highlighted)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: AppSpacing.md, vertical: AppSpacing.xs),
                  decoration: BoxDecoration(
                    color: AppColors.poke,
                    borderRadius: BorderRadius.circular(AppRadius.chip),
                  ),
                  child: Text(
                    l10n.mostPopular,
                    style: AppTypography.caption.copyWith(
                        color: AppColors.onPrimary,
                        fontWeight: FontWeight.w600),
                  ),
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.xs),
          Text(price,
              style:
                  AppTypography.h3.copyWith(color: AppColors.primaryDark)),
          const SizedBox(height: AppSpacing.lg),
          for (final feature in features)
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.sm),
              child: Row(
                children: [
                  const Icon(Icons.check_circle,
                      size: 18, color: AppColors.primary),
                  const SizedBox(width: AppSpacing.sm),
                  Expanded(child: Text(feature, style: AppTypography.body)),
                ],
              ),
            ),
          if (isCurrent) ...[
            const SizedBox(height: AppSpacing.sm),
            Container(
              width: double.infinity,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: AppColors.cyan50,
                borderRadius: BorderRadius.circular(AppRadius.button),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check,
                      size: 20, color: AppColors.primaryDark),
                  const SizedBox(width: AppSpacing.sm),
                  Text(
                    l10n.currentPlan,
                    style: AppTypography.button
                        .copyWith(color: AppColors.primaryDark),
                  ),
                ],
              ),
            ),
          ] else if (onUpgrade != null) ...[
            const SizedBox(height: AppSpacing.sm),
            PrimaryButton(
              label: l10n.upgrade,
              loading: busy,
              onPressed: onUpgrade,
            ),
          ],
        ],
      ),
    );

    return Container(
      decoration: BoxDecoration(
        gradient: highlighted ? AppColors.ctaGradient : null,
        color: highlighted ? null : AppColors.divider,
        borderRadius: BorderRadius.circular(AppRadius.card),
        boxShadow: const [
          BoxShadow(
              color: AppColors.cardShadow,
              blurRadius: 16,
              offset: Offset(0, 6)),
        ],
      ),
      padding: EdgeInsets.all(highlighted ? 2 : 1),
      child: inner,
    );
  }
}
