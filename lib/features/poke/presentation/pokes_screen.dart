import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/error/error_l10n.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/common.dart';
import '../../discovery/presentation/discovery_providers.dart';
import '../../discovery/presentation/match_celebration.dart';

/// Received pokes with "Poke back" (reciprocal poke = match).
class PokesScreen extends ConsumerWidget {
  const PokesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final pokes = ref.watch(receivedPokesProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.pokesTitle)),
      body: pokes.when(
        loading: () => ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: const [
            _PokeRowSkeleton(),
            _PokeRowSkeleton(),
            _PokeRowSkeleton(),
          ],
        ),
        error: (e, _) => EmptyState(
          icon: Icons.error_outline,
          title: l10n.errorLoadFailed,
          actionLabel: l10n.retry,
          onAction: () => ref.invalidate(receivedPokesProvider),
        ),
        data: (list) {
          if (list.isEmpty) {
            return EmptyState(
                icon: Icons.front_hand_outlined, title: l10n.pokesEmpty);
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(receivedPokesProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSpacing.lg),
              itemCount: list.length,
              separatorBuilder: (_, _) =>
                  const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, i) {
                final poke = list[i];
                final url = poke.photoPath == null
                    ? null
                    : ref
                        .read(discoveryRepositoryProvider)
                        .publicPhotoUrl(poke.photoPath!);
                return ListTile(
                  onTap: () => context.push(Routes.user(poke.pokerId)),
                  shape: RoundedRectangleBorder(
                      borderRadius:
                          BorderRadius.circular(AppSpacing.lg)),
                  tileColor: AppColors.surface,
                  leading:
                      GismatAvatar(url: url, verified: poke.isVerified),
                  title: Text('${poke.firstName}, ${poke.age}',
                      style: AppTypography.h3),
                  subtitle: Text(
                      '${l10n.pokedYou(poke.firstName)} · ${timeago.format(poke.pokedAt)}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTypography.caption),
                  trailing: poke.pokedBack
                      ? const Icon(Icons.check_circle,
                          color: AppColors.success)
                      : TextButton(
                          style: TextButton.styleFrom(
                              foregroundColor: AppColors.poke),
                          onPressed: () async {
                            try {
                              final result = await ref
                                  .read(discoveryRepositoryProvider)
                                  .sendPoke(poke.pokerId);
                              ref.invalidate(receivedPokesProvider);
                              if (!context.mounted) return;
                              if (result.matched &&
                                  result.conversationId != null) {
                                await showMatchCelebration(context,
                                    otherName: poke.firstName,
                                    conversationId:
                                        result.conversationId!);
                              }
                            } catch (e) {
                              if (context.mounted) {
                                showAppError(context, e);
                              }
                            }
                          },
                          child: Text(l10n.pokeBack),
                        ),
                );
              },
            ),
          );
        },
      ),
    );
  }
}

class _PokeRowSkeleton extends StatelessWidget {
  const _PokeRowSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Skeleton.circle(size: 52),
          SizedBox(width: AppSpacing.md),
          Expanded(child: Skeleton(height: 40, radius: 12)),
        ],
      ),
    );
  }
}
