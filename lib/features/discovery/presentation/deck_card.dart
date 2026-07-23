import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common.dart';
import '../domain/discovery_profile.dart';

/// Full-bleed profile card: photo pager (tap left/right), bottom scrim,
/// "First Last, Age", verified badge, distance chip and photo dots.
class DeckCard extends StatefulWidget {
  const DeckCard({
    super.key,
    required this.profile,
    required this.photoUrlBuilder,
    this.onPoke,
  });

  final DiscoveryProfile profile;
  final String Function(String storagePath) photoUrlBuilder;
  final VoidCallback? onPoke;

  @override
  State<DeckCard> createState() => _DeckCardState();
}

class _DeckCardState extends State<DeckCard> {
  int _photoIndex = 0;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final p = widget.profile;
    final photos = p.photoPaths;

    return ClipRRect(
      borderRadius: BorderRadius.circular(AppRadius.card),
      child: Stack(
        fit: StackFit.expand,
        children: [
          if (photos.isEmpty)
            Container(
              color: AppColors.cyan100,
              child: const Icon(Icons.person,
                  size: 96, color: AppColors.primaryDark),
            )
          else
            CachedNetworkImage(
              imageUrl: widget.photoUrlBuilder(photos[_photoIndex]),
              fit: BoxFit.cover,
              fadeInDuration: const Duration(milliseconds: 150),
              placeholder: (_, _) =>
                  const Skeleton(width: double.infinity, height: double.infinity, radius: 0),
              errorWidget: (_, _, _) => Container(
                  color: AppColors.cyan100,
                  child: const Icon(Icons.broken_image_outlined,
                      size: 64, color: AppColors.primaryDark)),
            ),
          // Photo paging: tap left/right halves.
          if (photos.length > 1)
            Row(
              children: [
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () => setState(() => _photoIndex =
                        (_photoIndex - 1 + photos.length) % photos.length),
                  ),
                ),
                Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () => setState(
                        () => _photoIndex = (_photoIndex + 1) % photos.length),
                  ),
                ),
              ],
            ),
          const DecoratedBox(
              decoration: BoxDecoration(gradient: AppColors.cardScrim)),
          // Photo dots
          if (photos.length > 1)
            Positioned(
              top: AppSpacing.md,
              left: AppSpacing.lg,
              right: AppSpacing.lg,
              child: Row(
                children: [
                  for (var i = 0; i < photos.length; i++)
                    Expanded(
                      child: Container(
                        height: 3,
                        margin: const EdgeInsets.symmetric(horizontal: 2),
                        decoration: BoxDecoration(
                          color: i == _photoIndex
                              ? AppColors.onPrimary
                              : AppColors.onPrimary.withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          Positioned(
            left: AppSpacing.lg,
            right: AppSpacing.lg,
            bottom: AppSpacing.lg,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DistanceChip(
                    label:
                        l10n.kmAway(Formatters.distanceKm(p.distanceM))),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        Formatters.nameAge(p.firstName, p.lastName, p.age),
                        style: AppTypography.h1
                            .copyWith(color: AppColors.onPrimary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (p.isVerified)
                      const Padding(
                        padding: EdgeInsets.only(left: AppSpacing.sm),
                        child: VerifiedBadge(size: 24),
                      ),
                    if (widget.onPoke != null)
                      Padding(
                        padding: const EdgeInsets.only(left: AppSpacing.sm),
                        child: _PokeMiniButton(onTap: widget.onPoke!),
                      ),
                  ],
                ),
                if (p.bio != null && p.bio!.isNotEmpty) ...[
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    p.bio!,
                    style: AppTypography.body
                        .copyWith(color: AppColors.onPrimary.withValues(alpha: 0.85)),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PokeMiniButton extends StatelessWidget {
  const _PokeMiniButton({required this.onTap});
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: AppLocalizations.of(context).poke,
      child: Material(
        color: AppColors.poke,
        shape: const CircleBorder(),
        child: InkWell(
          onTap: onTap,
          customBorder: const CircleBorder(),
          child: const SizedBox(
            width: 44,
            height: 44,
            child:
                Icon(Icons.front_hand, color: AppColors.onPrimary, size: 22),
          ),
        ),
      ),
    );
  }
}

/// LIKE / NOPE / POKE overlay stamps that fade in with drag progress.
class SwipeOverlayStamp extends StatelessWidget {
  const SwipeOverlayStamp({
    super.key,
    required this.label,
    required this.color,
    required this.opacity,
    required this.alignment,
    required this.angle,
  });

  final String label;
  final Color color;
  final double opacity;
  final Alignment alignment;
  final double angle;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.all(AppSpacing.xl),
        child: Opacity(
          opacity: opacity.clamp(0, 1),
          child: Transform.rotate(
            angle: angle,
            child: Container(
              padding: const EdgeInsets.symmetric(
                  horizontal: AppSpacing.lg, vertical: AppSpacing.sm),
              decoration: BoxDecoration(
                border: Border.all(color: color, width: 4),
                borderRadius: BorderRadius.circular(AppSpacing.md),
              ),
              child: Text(
                label,
                style: AppTypography.display.copyWith(color: color),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
