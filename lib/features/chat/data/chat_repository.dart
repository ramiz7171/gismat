import 'dart:io';

import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/app_exception.dart';
import '../domain/message.dart';

class ChatRepository {
  ChatRepository(this._client);

  final SupabaseClient _client;

  String get uid => _client.auth.currentUser!.id;

  // ---- Conversations ---------------------------------------------------

  Future<List<ConversationSummary>> fetchConversations() async {
    try {
      final rows = await _client.rpc<dynamic>('my_conversations');
      return (rows as List)
          .map((r) => ConversationSummary.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw mapError(e);
    }
  }

  Future<void> markRead(String conversationId) async {
    try {
      await _client.rpc<void>('mark_conversation_read',
          params: {'conv_id': conversationId});
    } catch (_) {
      // read-state is best-effort
    }
  }

  /// The other participant's last_read_at (for read receipts), realtime.
  Stream<DateTime?> otherReadAtStream(String conversationId) {
    return _client
        .from('conversation_participants')
        .stream(primaryKey: ['conversation_id', 'user_id'])
        .eq('conversation_id', conversationId)
        .map((rows) {
          for (final row in rows) {
            if (row['user_id'] != uid && row['last_read_at'] != null) {
              return DateTime.parse(row['last_read_at'] as String);
            }
          }
          return null;
        });
  }

  // ---- Messages --------------------------------------------------------

  Stream<List<ChatMessage>> messagesStream(String conversationId) {
    return _client
        .from('messages')
        .stream(primaryKey: ['id'])
        .eq('conversation_id', conversationId)
        .order('created_at', ascending: false)
        .limit(200)
        .map((rows) => rows.map(ChatMessage.fromJson).toList());
  }

  Future<void> sendText(String conversationId, String text) async {
    try {
      await _client.from('messages').insert({
        'conversation_id': conversationId,
        'sender_id': uid,
        'kind': 'text',
        'content': text,
      });
    } catch (e) {
      throw mapError(e);
    }
  }

  Future<void> sendVoice(String conversationId, File file,
      {required int durationMs}) async {
    try {
      final path =
          '$conversationId/${DateTime.now().millisecondsSinceEpoch}.m4a';
      await _client.storage.from('voice-messages').upload(path, file,
          fileOptions: const FileOptions(contentType: 'audio/mp4'));
      await _client.from('messages').insert({
        'conversation_id': conversationId,
        'sender_id': uid,
        'kind': 'voice',
        'content': path,
        'duration_ms': durationMs,
      });
    } catch (e) {
      throw mapError(e);
    }
  }

  Future<void> sendAttachment(String conversationId, File file,
      {required bool isImage}) async {
    try {
      final ext = file.path.split('.').last.toLowerCase();
      final path =
          '$conversationId/${DateTime.now().millisecondsSinceEpoch}.$ext';
      await _client.storage.from('chat-attachments').upload(path, file);
      await _client.from('messages').insert({
        'conversation_id': conversationId,
        'sender_id': uid,
        'kind': isImage ? 'image' : 'file',
        'content': path,
      });
    } catch (e) {
      throw mapError(e);
    }
  }

  /// Signed URL for private chat media (1 h validity).
  Future<String> signedMediaUrl(MessageKind kind, String path) async {
    try {
      final bucket =
          kind == MessageKind.voice ? 'voice-messages' : 'chat-attachments';
      return await _client.storage.from(bucket).createSignedUrl(path, 3600);
    } catch (e) {
      throw mapError(e);
    }
  }

  // ---- Presence & typing ----------------------------------------------

  /// Joins the conversation realtime room: presence (online) + typing
  /// broadcasts. Returns the channel; callers must unsubscribe on dispose.
  RealtimeChannel joinRoom(
    String conversationId, {
    required void Function(bool otherTyping) onTyping,
    required void Function(bool otherOnline) onPresence,
  }) {
    final channel = _client.channel(
      'room:$conversationId',
      opts: const RealtimeChannelConfig(self: false),
    );
    channel
      ..onBroadcast(
          event: 'typing',
          callback: (payload) {
            if (payload['user_id'] != uid) {
              onTyping(payload['typing'] == true);
            }
          })
      ..onPresenceSync((_) {
        final states = channel.presenceState();
        final others = states.any((s) =>
            s.presences.any((p) => p.payload['user_id'] != uid));
        onPresence(others);
      })
      ..subscribe((status, _) async {
        if (status == RealtimeSubscribeStatus.subscribed) {
          await channel.track({'user_id': uid});
        }
      });
    return channel;
  }

  Future<void> sendTyping(RealtimeChannel channel, bool typing) async {
    try {
      await channel.sendBroadcastMessage(
          event: 'typing', payload: {'user_id': uid, 'typing': typing});
    } catch (_) {}
  }

  Future<void> leaveRoom(RealtimeChannel channel) async {
    try {
      await channel.unsubscribe();
    } catch (_) {}
  }
}
