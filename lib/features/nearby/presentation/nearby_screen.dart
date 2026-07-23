import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_staggered_grid_view/flutter_staggered_grid_view.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/env.dart';
import '../../../core/error/error_l10n.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/widgets/common.dart';
import '../../auth/presentation/session_providers.dart';
import '../../discovery/presentation/discovery_providers.dart';

/// Nearby: radius slider (1–100 km, default 2), live count, distance-sorted
/// grid. Distances are privacy-bucketed server-side.
class NearbyScreen extends ConsumerStatefulWidget {
  const NearbyScreen({super.key});

  @override
  ConsumerState<NearbyScreen> createState() => _NearbyScreenState();
}

class _NearbyScreenState extends ConsumerState<NearbyScreen> {
  bool _refreshingLocation = false;

  Future<void> _refreshLocation() async {
    if (_refreshingLocation) return;
    setState(() => _refreshingLocation = true);
    try {
      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.deniedForever ||
          permission == LocationPermission.denied) {
        if (mounted) {
          final l10n = AppLocalizations.of(context);
          showAppSnackbar(l10n.locationDenied, isError: true);
        }
        return;
      }
      final pos = await Geolocator.getCurrentPosition(
          locationSettings:
              const LocationSettings(accuracy: LocationAccuracy.medium));
      await ref
          .read(profileRepositoryProvider)
          .updateLocation(lat: pos.latitude, lng: pos.longitude);
      ref.invalidate(nearbyProfilesProvider);
    } catch (e) {
      if (mounted) showAppError(context, e);
    } finally {
      if (mounted) setState(() => _refreshingLocation = false);
    }
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _refreshLocation());
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final radius = ref.watch(nearbyRadiusProvider);
    final results = ref.watch(nearbyProfilesProvider);
    final radiusLabel =
        radius < 10 ? radius.toStringAsFixed(0) : radius.round().toString();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
              AppSpacing.xl, AppSpacing.md, AppSpacing.xl, 0),
          child: Row(
            children: [
              Text(l10n.nearbyRadius, style: AppTypography.h3),
              const Spacer(),
              Text('$radiusLabel km',
                  style: AppTypography.h3
                      .copyWith(color: AppColors.primaryDark)),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.lg),
          child: Slider(
            value: radius.clamp(
                AppConstants.minRadiusKm, AppConstants.maxRadiusKm),
            min: AppConstants.minRadiusKm,
            max: AppConstants.maxRadiusKm,
            divisions: 99,
            label: '$radiusLabel km',
            semanticFormatterCallback: (v) => '${v.round()} km',
            onChanged: (v) =>
                ref.read(nearbyRadiusProvider.notifier).set(v),
          ),
        ),
        if (results.hasValue)
          Padding(
            padding:
                const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
            child: Text(
              l10n.nearbyCount(results.value!.length, radiusLabel),
              style: AppTypography.caption,
            ),
          ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: results.when(
            loading: () => GridView.count(
              padding: const EdgeInsets.all(AppSpacing.lg),
              crossAxisCount: 2,
              mainAxisSpacing: AppSpacing.md,
              crossAxisSpacing: AppSpacing.md,
              childAspectRatio: 0.72,
              children: const [
                Skeleton(height: 220, radius: AppRadius.card),
                Skeleton(height: 220, radius: AppRadius.card),
                Skeleton(height: 220, radius: AppRadius.card),
                Skeleton(height: 220, radius: AppRadius.card),
              ],
            ),
            error: (e, _) => EmptyState(
              icon: Icons.near_me_disabled_outlined,
              title: l10n.errorLoadFailed,
              actionLabel: l10n.retry,
              onAction: () => ref.invalidate(nearbyProfilesProvider),
            ),
            data: (profiles) {
              if (profiles.isEmpty) {
                return EmptyState(
                  icon: Icons.travel_explore,
                  title: l10n.nearbyEmpty(radiusLabel),
                  actionLabel: l10n.retry,
                  onAction: _refreshLocation,
                );
              }
              return RefreshIndicator(
                onRefresh: () async {
                  await _refreshLocation();
                  ref.invalidate(nearbyProfilesProvider);
                },
                child: MasonryGridView.count(
                  padding: const EdgeInsets.all(AppSpacing.lg),
                  crossAxisCount: 2,
                  mainAxisSpacing: AppSpacing.md,
                  crossAxisSpacing: AppSpacing.md,
                  itemCount: profiles.length,
                  itemBuilder: (context, i) {
                    final p = profiles[i];
                    final url = p.photoPaths.isEmpty
                        ? null
                        : ref
                            .read(discoveryRepositoryProvider)
                            .publicPhotoUrl(p.photoPaths.first);
                    return _NearbyTile(
                      name: p.firstName,
                      age: p.age,
                      distance: l10n
                          .kmAway(Formatters.distanceKm(p.distanceM)),
                      verified: p.isVerified,
                      online: p.isOnline,
                      imageUrl: url,
                      tall: i.isEven,
                      onTap: () => context.push(Routes.user(p.id)),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _NearbyTile extends StatelessWidget {
  const _NearbyTile({
    required this.name,
    required this.age,
    required this.distance,
    required this.verified,
    required this.online,
    required this.imageUrl,
    required this.tall,
    required this.onTap,
  });

  final String name;
  final int age;
  final String distance;
  final bool verified;
  final bool online;
  final String? imageUrl;
  final bool tall;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final height = tall ? 240.0 : 200.0;
    return Semantics(
      button: true,
      label: '$name, $age. $distance',
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppRadius.card),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.card),
          child: SizedBox(
            height: height,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (imageUrl == null)
                  Container(
                      color: AppColors.cyan100,
                      child: const Icon(Icons.person,
                          size: 64, color: AppColors.primaryDark))
                else
                  CachedNetworkImage(
                    imageUrl: imageUrl!,
                    fit: BoxFit.cover,
                    placeholder: (_, _) =>
                        Skeleton(height: height, radius: 0),
                  ),
                const DecoratedBox(
                    decoration:
                        BoxDecoration(gradient: AppColors.cardScrim)),
                Positioned(
                  left: AppSpacing.md,
                  right: AppSpacing.md,
                  bottom: AppSpacing.md,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (online)
                            Container(
                              width: 10,
                              height: 10,
                              margin: const EdgeInsets.only(
                                  right: AppSpacing.xs),
                              decoration: const BoxDecoration(
                                  color: AppColors.online,
                                  shape: BoxShape.circle),
                            ),
                          Expanded(
                            child: Text('$name, $age',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTypography.h3.copyWith(
                                    color: AppColors.onPrimary)),
                          ),
                          if (verified) const VerifiedBadge(size: 18),
                        ],
                      ),
                      Text(distance,
                          style: AppTypography.caption.copyWith(
                              color: AppColors.onPrimary
                                  .withValues(alpha: 0.85))),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
