import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:shimmer/shimmer.dart';

import '../theme/app_colors.dart';
import '../theme/app_spacing.dart';
import '../theme/app_typography.dart';

/// Shimmer skeleton block used by every loading state.
class Skeleton extends StatelessWidget {
  const Skeleton({super.key, this.width, this.height = 16, this.radius = 8});
  const Skeleton.circle({super.key, required double size})
      : width = size, height = size, radius = 999;

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: AppColors.cyan50,
      highlightColor: AppColors.surface,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: AppColors.cyan50,
          borderRadius: BorderRadius.circular(radius),
        ),
      ),
    );
  }
}

/// Friendly cyan empty state with icon + message + optional CTA.
class EmptyState extends StatelessWidget {
  const EmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.body,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final String title;
  final String? body;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.of(context).disableAnimations;
    Widget content = Padding(
      padding: const EdgeInsets.all(AppSpacing.xxl),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 96,
            height: 96,
            decoration: const BoxDecoration(
                color: AppColors.cyan50, shape: BoxShape.circle),
            child: Icon(icon, size: 44, color: AppColors.primaryDark),
          ),
          const SizedBox(height: AppSpacing.xl),
          Text(title, style: AppTypography.h3, textAlign: TextAlign.center),
          if (body != null) ...[
            const SizedBox(height: AppSpacing.sm),
            Text(body!,
                style: AppTypography.body
                    .copyWith(color: AppColors.textSecondary),
                textAlign: TextAlign.center),
          ],
          if (actionLabel != null) ...[
            const SizedBox(height: AppSpacing.xl),
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
          ],
        ],
      ),
    );
    if (!reduceMotion) {
      content = content
          .animate()
          .fadeIn(duration: 300.ms, curve: Curves.easeOutCubic)
          .slideY(begin: 0.05, end: 0);
    }
    return Center(child: content);
  }
}

/// Avatar with optional online dot and verified badge.
class GismatAvatar extends StatelessWidget {
  const GismatAvatar({
    super.key,
    this.url,
    this.size = 52,
    this.online = false,
    this.verified = false,
  });

  final String? url;
  final double size;
  final bool online;
  final bool verified;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipOval(
          child: url == null
              ? Container(
                  width: size,
                  height: size,
                  color: AppColors.cyan100,
                  child: Icon(Icons.person,
                      size: size * 0.55, color: AppColors.primaryDark),
                )
              : CachedNetworkImage(
                  imageUrl: url!,
                  width: size,
                  height: size,
                  fit: BoxFit.cover,
                  placeholder: (_, _) => Skeleton.circle(size: size),
                  errorWidget: (_, _, _) => Container(
                      width: size,
                      height: size,
                      color: AppColors.cyan100,
                      child: Icon(Icons.person,
                          size: size * 0.55, color: AppColors.primaryDark)),
                ),
        ),
        if (online)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.26,
              height: size * 0.26,
              decoration: BoxDecoration(
                color: AppColors.online,
                shape: BoxShape.circle,
                border: Border.all(color: AppColors.surface, width: 2),
              ),
            ),
          ),
        if (verified)
          const Positioned(
            right: -2,
            top: -2,
            child: VerifiedBadge(size: 18),
          ),
      ],
    );
  }
}

class VerifiedBadge extends StatelessWidget {
  const VerifiedBadge({super.key, this.size = 20});
  final double size;

  @override
  Widget build(BuildContext context) {
    return Icon(Icons.verified, color: AppColors.primary, size: size,
        semanticLabel: 'Verified');
  }
}

/// Bucketed-distance chip shown on cards ("≈1.2 km").
class DistanceChip extends StatelessWidget {
  const DistanceChip({super.key, required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md, vertical: AppSpacing.xs),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(AppRadius.chip),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.near_me, size: 14, color: AppColors.onPrimary),
          const SizedBox(width: AppSpacing.xs),
          Text(label,
              style:
                  AppTypography.caption.copyWith(color: AppColors.onPrimary)),
        ],
      ),
    );
  }
}
