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
import '../domain/app_notification.dart';
import 'notification_providers.dart';

/// In-app notification center: pokes, matches, messages, system notices.
class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context);
    final feed = ref.watch(notificationsFeedProvider);
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.notificationsTitle),
        actions: [
          TextButton(
            onPressed: () =>
                ref.read(notificationActionsProvider.notifier).markAllRead(),
            child: Text(l10n.markAllRead),
          ),
        ],
      ),
      body: feed.when(
        loading: () => _skeletons(),
        error: (e, _) => EmptyState(
            icon: Icons.notifications_none, title: l10n.errorLoadFailed),
        data: (items) {
          if (items.isEmpty) {
            return EmptyState(
                icon: Icons.notifications_none,
                title: l10n.notificationsEmpty);
          }
          // Feed arrives ordered ascending — show newest first.
          final sorted = items.reversed.toList();
          return ListView.separated(
            itemCount: sorted.length,
            separatorBuilder: (_, _) =>
                const Divider(height: 1, color: AppColors.divider),
            itemBuilder: (context, index) =>
                _NotificationRow(notification: sorted[index]),
          );
        },
      ),
    );
  }

  Widget _skeletons() {
    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(AppSpacing.lg),
      itemCount: 4,
      itemBuilder: (_, _) => const Padding(
        padding: EdgeInsets.only(bottom: AppSpacing.lg),
        child: Row(
          children: [
            Skeleton.circle(size: 44),
            SizedBox(width: AppSpacing.md),
            Expanded(child: Skeleton(height: 44, radius: 12)),
          ],
        ),
      ),
    );
  }
}

class _NotificationRow extends ConsumerWidget {
  const _NotificationRow({required this.notification});

  final AppNotification notification;

  (IconData, Color) get _iconSpec => switch (notification.type) {
        'poke' => (Icons.front_hand, AppColors.poke),
        'match' => (Icons.favorite, AppColors.primary),
        'message' => (Icons.chat_bubble, AppColors.primary),
        _ => (Icons.info_outline, AppColors.textSecondary),
      };

  void _onTap(BuildContext context, WidgetRef ref) {
    ref.read(notificationActionsProvider.notifier).markRead(notification.id);
    final conversationId = notification.conversationId;
    if (conversationId != null) {
      context.push(Routes.chat(conversationId));
    } else if (notification.type == 'poke') {
      context.push(Routes.pokes);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final (icon, color) = _iconSpec;
    final unread = !notification.read;
    return Material(
      color: unread ? AppColors.cyan50 : Colors.transparent,
      child: InkWell(
        onTap: () => _onTap(context, ref),
        child: Padding(
          padding: const EdgeInsets.symmetric(
              horizontal: AppSpacing.lg, vertical: AppSpacing.md),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, size: 22, color: color),
              ),
              const SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      notification.title,
                      style: unread
                          ? AppTypography.body
                              .copyWith(fontWeight: FontWeight.w600)
                          : AppTypography.body,
                    ),
                    if (notification.body.isNotEmpty) ...[
                      const SizedBox(height: 2),
                      Text(
                        notification.body,
                        style: AppTypography.body
                            .copyWith(color: AppColors.textSecondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                    const SizedBox(height: 2),
                    Text(timeago.format(notification.createdAt),
                        style: AppTypography.caption),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
