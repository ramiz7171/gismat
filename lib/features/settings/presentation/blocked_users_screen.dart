import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/error/error_l10n.dart';
import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/common.dart';
import 'settings_providers.dart';

class BlockedUsersScreen extends ConsumerWidget {
  const BlockedUsersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final blocked = ref.watch(blockedUsersProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.blockedUsers)),
      body: SafeArea(
        child: blocked.when(
          loading: () => ListView.builder(
            itemCount: 3,
            itemBuilder: (_, _) => const ListTile(
              minVerticalPadding: AppSpacing.md,
              leading: Skeleton.circle(size: 44),
              title: Skeleton(width: 140),
              trailing: Skeleton(width: 64, height: 32, radius: AppRadius.button),
            ),
          ),
          error: (e, _) => Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(l10n.errorLoadFailed,
                    style: AppTypography.body
                        .copyWith(color: AppColors.textSecondary),
                    textAlign: TextAlign.center),
                const SizedBox(height: AppSpacing.md),
                TextButton(
                  onPressed: () => ref.invalidate(blockedUsersProvider),
                  child: Text(l10n.retry),
                ),
              ],
            ),
          ),
          data: (rows) {
            if (rows.isEmpty) {
              return EmptyState(icon: Icons.block, title: l10n.noBlockedUsers);
            }
            return ListView.separated(
              itemCount: rows.length,
              separatorBuilder: (_, _) =>
                  const Divider(height: 1, color: AppColors.divider),
              itemBuilder: (_, index) {
                final row = rows[index];
                final profile = row['profiles'] as Map<String, dynamic>?;
                final firstName = profile?['first_name'] as String? ?? '';
                final lastName = profile?['last_name'] as String? ?? '';
                final name = '$firstName $lastName'.trim();
                return ListTile(
                  minVerticalPadding: AppSpacing.md,
                  leading: const GismatAvatar(size: 44),
                  title: Text(name.isEmpty ? '—' : name,
                      style: AppTypography.bodyLarge,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  trailing: TextButton(
                    onPressed: () => _unblock(
                        context, ref, row['blocked_id'] as String),
                    child: Text(l10n.unblock),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }

  Future<void> _unblock(
      BuildContext context, WidgetRef ref, String userId) async {
    try {
      await ref.read(safetyRepositoryProvider).unblockUser(userId);
      ref.invalidate(blockedUsersProvider);
    } catch (e) {
      if (context.mounted) showAppError(context, e);
    }
  }
}
