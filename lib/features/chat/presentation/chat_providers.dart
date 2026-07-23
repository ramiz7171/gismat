import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/presentation/session_providers.dart';
import '../data/chat_repository.dart';
import '../domain/message.dart';

part 'chat_providers.g.dart';

@Riverpod(keepAlive: true)
ChatRepository chatRepository(Ref ref) =>
    ChatRepository(ref.watch(supabaseClientProvider));

/// The Matches / Chats list.
@riverpod
Future<List<ConversationSummary>> conversations(Ref ref) =>
    ref.watch(chatRepositoryProvider).fetchConversations();

/// Realtime message stream for one conversation (newest first — matches the
/// reversed ListView).
@riverpod
Stream<List<ChatMessage>> conversationMessages(Ref ref, String conversationId) =>
    ref.watch(chatRepositoryProvider).messagesStream(conversationId);

/// Other participant's read cursor for receipts.
@riverpod
Stream<DateTime?> otherReadAt(Ref ref, String conversationId) =>
    ref.watch(chatRepositoryProvider).otherReadAtStream(conversationId);

/// Header info for the chat screen (from the conversations list).
@riverpod
Future<ConversationSummary?> conversationSummary(
    Ref ref, String conversationId) async {
  final all = await ref.watch(conversationsProvider.future);
  for (final c in all) {
    if (c.conversationId == conversationId) return c;
  }
  return null;
}
