import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:haptic_feedback/haptic_feedback.dart';
import 'package:swipable_stack/swipable_stack.dart';

import '../../../core/error/app_exception.dart';
import '../../../core/error/error_l10n.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/common.dart';
import '../../auth/presentation/session_providers.dart';
import '../domain/discovery_profile.dart';
import 'deck_card.dart';
import 'discovery_providers.dart';
import 'match_celebration.dart';

/// The swipe deck: drag with rotation, spring-back below threshold,
/// LIKE / NOPE / POKE overlays, mirrored action buttons, premium rewind.
class DiscoveryScreen extends ConsumerStatefulWidget {
  const DiscoveryScreen({super.key});

  @override
  ConsumerState<DiscoveryScreen> createState() => _DiscoveryScreenState();
}

class _DiscoveryScreenState extends ConsumerState<DiscoveryScreen> {
  late final SwipableStackController _controller;
  bool _busy = false;

  @override
  void initState() {
    super.initState();
    _controller = SwipableStackController();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _haptic() async {
    try {
      if (await Haptics.canVibrate()) {
        await Haptics.vibrate(HapticsType.light);
        return;
      }
    } catch (_) {}
    HapticFeedback.lightImpact();
  }

  Future<void> _hapticSuccess() async {
    try {
      if (await Haptics.canVibrate()) {
        await Haptics.vibrate(HapticsType.success);
        return;
      }
    } catch (_) {}
    HapticFeedback.mediumImpact();
  }

  Future<void> _onSwiped(
      List<DiscoveryProfile> deck, int index, SwipeDirection direction) async {
    if (index >= deck.length) return;
    final profile = deck[index];
    final notifier = ref.read(deckProvider.notifier);
    await _haptic();
    try {
      switch (direction) {
        case SwipeDirection.left:
          await notifier.swipe(profile, like: false);
        case SwipeDirection.right:
          await notifier.swipe(profile, like: true);
        case SwipeDirection.up:
          final result = await notifier.poke(profile);
          await _hapticSuccess();
          if (!mounted) return;
          if (result.matched && result.conversationId != null) {
            await showMatchCelebration(context,
                otherName: profile.firstName,
                conversationId: result.conversationId!);
          } else {
            showAppSnackbar(AppLocalizations.of(context).pokeSent);
          }
        case SwipeDirection.down:
          break;
      }
    } on AppException catch (e) {
      if (!mounted) return;
      if (e.code == AppErrorCode.swipeLimitReached) {
        _controller.rewind(
            duration: const Duration(milliseconds: 200));
        context.push(Routes.paywall);
      } else {
        showAppError(context, e);
      }
    } catch (e) {
      if (mounted) showAppError(context, e);
    }
  }

  Future<void> _rewind() async {
    final l10n = AppLocalizations.of(context);
    final profile = ref.read(myProfileProvider).valueOrNull;
    final isPremium =
        profile != null && (profile.tier != 'basic' || profile.isAdmin);
    if (!isPremium) {
      showAppSnackbar(l10n.rewindPremium);
      context.push(Routes.paywall);
      return;
    }
    if (_busy) return;
    setState(() => _busy = true);
    try {
      final restored = await ref.read(deckProvider.notifier).rewind();
      if (restored != null && _controller.canRewind) {
        _controller.rewind(duration: const Duration(milliseconds: 250));
      }
    } on AppException catch (e) {
      if (!mounted) return;
      if (e.code == AppErrorCode.premiumRequired) {
        context.push(Routes.paywall);
      } else {
        showAppError(context, e);
      }
    } catch (e) {
      if (mounted) showAppError(context, e);
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final deckAsync = ref.watch(deckProvider);
    final remaining = ref.watch(swipesRemainingProvider).valueOrNull;

    return deckAsync.when(
      loading: () => const _DeckSkeleton(),
      error: (e, _) => EmptyState(
        icon: Icons.wifi_off,
        title: l10n.errorLoadFailed,
        actionLabel: l10n.retry,
        onAction: () => ref.read(deckProvider.notifier).reload(),
      ),
      data: (deck) {
        if (deck.isEmpty || _controller.currentIndex >= deck.length) {
          return EmptyState(
            icon: Icons.style_outlined,
            title: l10n.deckEmptyTitle,
            body: l10n.deckEmptyBody,
            actionLabel: l10n.retry,
            onAction: () async {
              await ref.read(deckProvider.notifier).reload();
              _controller.currentIndex = 0;
            },
          );
        }
        return Column(
          children: [
            if (remaining != null)
              Padding(
                padding: const EdgeInsets.only(top: AppSpacing.sm),
                child: Text(
                  remaining < 0
                      ? l10n.swipesUnlimited
                      : l10n.swipesLeft(remaining),
                  style: AppTypography.caption,
                ),
              ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(
                    horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
                child: SwipableStack(
                  controller: _controller,
                  itemCount: deck.length,
                  detectableSwipeDirections: const {
                    SwipeDirection.left,
                    SwipeDirection.right,
                    SwipeDirection.up,
                  },
                  horizontalSwipeThreshold: 0.38,
                  verticalSwipeThreshold: 0.32,
                  swipeAnchor: SwipeAnchor.bottom,
                  stackClipBehaviour: Clip.none,
                  onSwipeCompleted: (index, direction) =>
                      _onSwiped(deck, index, direction),
                  overlayBuilder: (context, properties) {
                    final opacity = properties.swipeProgress.clamp(0.0, 1.0);
                    return switch (properties.direction) {
                      SwipeDirection.right => SwipeOverlayStamp(
                          label: l10n.like.toUpperCase(),
                          color: AppColors.primary,
                          opacity: opacity,
                          alignment: Alignment.topLeft,
                          angle: -0.2),
                      SwipeDirection.left => SwipeOverlayStamp(
                          label: l10n.nope.toUpperCase(),
                          color: AppColors.nope,
                          opacity: opacity,
                          alignment: Alignment.topRight,
                          angle: 0.2),
                      SwipeDirection.up => SwipeOverlayStamp(
                          label: l10n.poke.toUpperCase(),
                          color: AppColors.poke,
                          opacity: opacity,
                          alignment: Alignment.center,
                          angle: -0.1),
                      _ => const SizedBox.shrink(),
                    };
                  },
                  builder: (context, properties) {
                    if (properties.index >= deck.length) {
                      return const SizedBox.shrink();
                    }
                    final profile = deck[properties.index];
                    return GestureDetector(
                      onLongPress: () => context.push(Routes.user(profile.id)),
                      child: DeckCard(
                        profile: profile,
                        photoUrlBuilder: ref
                            .read(discoveryRepositoryProvider)
                            .publicPhotoUrl,
                        onPoke: () => _controller.next(
                            swipeDirection: SwipeDirection.up),
                      ),
                    );
                  },
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(bottom: AppSpacing.lg),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconCircleButton(
                    icon: Icons.replay,
                    size: 48,
                    color: AppColors.warning,
                    semanticLabel: l10n.rewind,
                    onPressed: _rewind,
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  IconCircleButton(
                    icon: Icons.close,
                    color: AppColors.nope,
                    semanticLabel: l10n.pass,
                    onPressed: () => _controller.next(
                        swipeDirection: SwipeDirection.left),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  IconCircleButton(
                    icon: Icons.front_hand,
                    size: 68,
                    color: AppColors.onPrimary,
                    background: AppColors.poke,
                    semanticLabel: l10n.poke,
                    onPressed: () =>
                        _controller.next(swipeDirection: SwipeDirection.up),
                  ),
                  const SizedBox(width: AppSpacing.lg),
                  IconCircleButton(
                    icon: Icons.favorite,
                    color: AppColors.primary,
                    semanticLabel: l10n.like,
                    onPressed: () => _controller.next(
                        swipeDirection: SwipeDirection.right),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}

class _DeckSkeleton extends StatelessWidget {
  const _DeckSkeleton();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(AppSpacing.lg),
      child: Column(
        children: [
          const Expanded(
            child: Skeleton(
                width: double.infinity,
                height: double.infinity,
                radius: AppRadius.card),
          ),
          const SizedBox(height: AppSpacing.lg),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: const [
              Skeleton.circle(size: 56),
              SizedBox(width: AppSpacing.lg),
              Skeleton.circle(size: 68),
              SizedBox(width: AppSpacing.lg),
              Skeleton.circle(size: 56),
            ],
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }
}
