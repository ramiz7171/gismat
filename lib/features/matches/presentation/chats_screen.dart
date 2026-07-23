import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:timeago/timeago.dart' as timeago;

import '../../../core/l10n/generated/app_localizations.dart';
import '../../../core/router/routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/theme/app_typography.dart';
import '../../../core/widgets/common.dart';
import '../../auth/presentation/session_providers.dart';
import '../../chat/domain/message.dart';
import '../../chat/presentation/chat_providers.dart';

/// Matches / conversations list: avatar + online dot, name, last message
/// preview, unread badge, relative timestamp.
class ChatsScreen extends ConsumerWidget {
  const ChatsScreen({super.key});

  String _preview(BuildContext context, ConversationSummary c) {
    final l10n = AppLocalizations.of(context);
    return switch (c.lastMessageKind) {
      null => l10n.newMatch,
      'voice' => '🎤 ${l10n.voiceMessage}',
      'image' => '📷 ${l10n.photoMessage}',
      'file' => '📎 ${l10n.fileMessage}',
      _ => c.lastMessageContent ?? '',
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final conversations = ref.watch(conversationsProvider);

    return conversations.when(
      loading: () => ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: const [
          _RowSkeleton(),
          _RowSkeleton(),
          _RowSkeleton(),
          _RowSkeleton(),
        ],
      ),
      error: (e, _) => EmptyState(
        icon: Icons.wifi_off,
        title: l10n.errorLoadFailed,
        actionLabel: l10n.retry,
        onAction: () => ref.invalidate(conversationsProvider),
      ),
      data: (list) {
        if (list.isEmpty) {
          return EmptyState(
              icon: Icons.chat_bubble_outline, title: l10n.matchesEmpty);
        }
        return RefreshIndicator(
          onRefresh: () async => ref.invalidate(conversationsProvider),
          child: ListView.separated(
            padding: const EdgeInsets.all(AppSpacing.lg),
            itemCount: list.length,
            separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.xs),
            itemBuilder: (context, i) {
              final c = list[i];
              final url = c.otherPhotoPath == null
                  ? null
                  : ref
                      .read(profileRepositoryProvider)
                      .publicPhotoUrl(c.otherPhotoPath!);
              final unread = c.unreadCount > 0;
              return ListTile(
                onTap: () async {
                  await context.push(Routes.chat(c.conversationId));
                  ref.invalidate(conversationsProvider);
                },
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppSpacing.lg)),
                tileColor: unread ? AppColors.cyan50 : AppColors.surface,
                leading: GismatAvatar(
                    url: url,
                    online: c.otherOnline,
                    verified: c.otherVerified),
                title: Text(c.otherFirstName,
                    style: AppTypography.h3.copyWith(
                        fontWeight:
                            unread ? FontWeight.w700 : FontWeight.w600)),
                subtitle: Text(
                  _preview(context, c),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTypography.body.copyWith(
                      color: unread
                          ? AppColors.textPrimary
                          : AppColors.textSecondary,
                      fontWeight:
                          unread ? FontWeight.w600 : FontWeight.w400),
                ),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(timeago.format(c.lastMessageAt),
                        style: AppTypography.caption),
                    const SizedBox(height: AppSpacing.xs),
                    if (unread)
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 2),
                        decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle),
                        child: Text('${c.unreadCount}',
                            style: AppTypography.caption
                                .copyWith(color: AppColors.onPrimary)),
                      )
                    else
                      const SizedBox(height: 16),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _RowSkeleton extends StatelessWidget {
  const _RowSkeleton();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
      child: Row(
        children: [
          Skeleton.circle(size: 52),
          SizedBox(width: AppSpacing.md),
          Expanded(child: Skeleton(height: 44, radius: 12)),
        ],
      ),
    );
  }
}
