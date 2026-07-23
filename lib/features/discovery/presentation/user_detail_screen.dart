import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../../core/error/error_l10n.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/buttons.dart';
import '../../../core/widgets/common.dart';
import '../../auth/presentation/session_providers.dart';
import '../../profile/domain/profile.dart';
import '../../settings/presentation/report_sheet.dart';
import 'discovery_providers.dart';
import 'match_celebration.dart';

part 'user_detail_screen.g.dart';

@riverpod
Future<(Profile?, List<ProfilePhoto>)> userDetail(Ref ref, String userId) async {
  final repo = ref.watch(profileRepositoryProvider);
  final profile = await repo.fetchProfile(userId);
  final photos = await repo.fetchPhotos(userId);
  return (profile, photos);
}

/// Other-user profile: photo carousel, name/age, bio, verified badge,
/// actions Like / Poke / Report / Block.
class UserDetailScreen extends ConsumerWidget {
  const UserDetailScreen({super.key, required this.userId});

  final String userId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final detail = ref.watch(userDetailProvider(userId));

    return Scaffold(
      appBar: AppBar(
        actions: [
          detail.maybeWhen(
            data: (d) => d.$1 == null
                ? const SizedBox.shrink()
                : PopupMenuButton<String>(
                    onSelected: (value) async {
                      final profile = d.$1!;
                      switch (value) {
                        case 'report':
                          await showReportSheet(context, ref,
                              userId: profile.id,
                              userName: profile.firstName);
                        case 'block':
                          final blocked = await confirmBlock(context, ref,
                              userId: profile.id,
                              userName: profile.firstName);
                          if (blocked && context.mounted) context.pop();
                      }
                    },
                    itemBuilder: (context) => [
                      PopupMenuItem(
                          value: 'report', child: Text(l10n.report)),
                      PopupMenuItem(value: 'block', child: Text(l10n.block)),
                    ],
                  ),
            orElse: () => const SizedBox.shrink(),
          ),
        ],
      ),
      body: detail.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => EmptyState(
            icon: Icons.error_outline,
            title: l10n.errorLoadFailed,
            actionLabel: l10n.retry,
            onAction: () => ref.invalidate(userDetailProvider(userId))),
        data: (d) {
          final profile = d.$1;
          final photos = d.$2;
          if (profile == null) {
            return EmptyState(
                icon: Icons.person_off_outlined, title: l10n.errorGeneric);
          }
          final urls = [
            for (final p in photos)
              ref.read(profileRepositoryProvider).publicPhotoUrl(p.storagePath)
          ];
          return ListView(
            padding: const EdgeInsets.all(AppSpacing.lg),
            children: [
              if (urls.isNotEmpty)
                SizedBox(
                  height: 420,
                  child: PageView.builder(
                    itemCount: urls.length,
                    itemBuilder: (_, i) => Padding(
                      padding:
                          const EdgeInsets.only(right: AppSpacing.sm),
                      child: ClipRRect(
                        borderRadius:
                            BorderRadius.circular(AppRadius.card),
                        child: CachedNetworkImage(
                            imageUrl: urls[i],
                            fit: BoxFit.cover,
                            placeholder: (_, _) => const Skeleton(
                                width: double.infinity,
                                height: 420,
                                radius: AppRadius.card)),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: Text('${profile.firstName} ${profile.lastName}, ${profile.age}',
                        style: AppTypography.h1),
                  ),
                  if (profile.isVerified) const VerifiedBadge(size: 26),
                ],
              ),
              if (profile.bio != null && profile.bio!.isNotEmpty) ...[
                const SizedBox(height: AppSpacing.md),
                Text(profile.bio!,
                    style: AppTypography.bodyLarge
                        .copyWith(color: AppColors.textSecondary)),
              ],
              const SizedBox(height: AppSpacing.xxl),
              Row(
                children: [
                  Expanded(
                    child: SecondaryButton(
                      label: l10n.like,
                      icon: Icons.favorite_outline,
                      onPressed: () async {
                        try {
                          await ref
                              .read(discoveryRepositoryProvider)
                              .recordSwipe(
                                  targetUserId: profile.id, like: true);
                          if (context.mounted) context.pop();
                        } catch (e) {
                          if (context.mounted) showAppError(context, e);
                        }
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              PrimaryButton(
                label: l10n.poke,
                icon: Icons.front_hand,
                onPressed: () async {
                  try {
                    final result = await ref
                        .read(discoveryRepositoryProvider)
                        .sendPoke(profile.id);
                    if (!context.mounted) return;
                    if (result.matched && result.conversationId != null) {
                      await showMatchCelebration(context,
                          otherName: profile.firstName,
                          conversationId: result.conversationId!);
                    } else {
                      showAppSnackbar(l10n.pokeSent);
                    }
                  } catch (e) {
                    if (context.mounted) showAppError(context, e);
                  }
                },
              ),
              const SizedBox(height: AppSpacing.xl),
            ],
          );
        },
      ),
    );
  }
}
