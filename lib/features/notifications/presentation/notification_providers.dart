import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/presentation/session_providers.dart';
import '../domain/app_notification.dart';

part 'notification_providers.g.dart';

/// Live in-app notification feed (Supabase realtime stream, RLS-scoped).
@riverpod
Stream<List<AppNotification>> notificationsFeed(Ref ref) {
  final client = ref.watch(supabaseClientProvider);
  final user = ref.watch(currentUserProvider);
  if (user == null) return Stream.value(const []);
  return client
      .from('notifications')
      .stream(primaryKey: ['id'])
      .eq('recipient_id', user.id)
      .order('created_at')
      .limit(100)
      .map((rows) => rows.map(AppNotification.fromJson).toList());
}

@riverpod
int unreadNotificationCount(Ref ref) {
  final list = ref.watch(notificationsFeedProvider).valueOrNull ?? const <AppNotification>[];
  return list.where((n) => !n.read).length;
}

/// Actions on notifications.
@riverpod
class NotificationActions extends _$NotificationActions {
  @override
  void build() {}

  Future<void> markRead(String id) async {
    final client = ref.read(supabaseClientProvider);
    await client.from('notifications').update({'read': true}).eq('id', id);
  }

  Future<void> markAllRead() async {
    final client = ref.read(supabaseClientProvider);
    final user = ref.read(currentUserProvider);
    if (user == null) return;
    await client
        .from('notifications')
        .update({'read': true})
        .eq('recipient_id', user.id)
        .eq('read', false);
  }
}
