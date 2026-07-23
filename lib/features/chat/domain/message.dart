enum MessageKind { text, voice, image, file }

MessageKind messageKindFrom(String raw) => switch (raw) {
      'voice' => MessageKind.voice,
      'image' => MessageKind.image,
      'file' => MessageKind.file,
      _ => MessageKind.text,
    };

class ChatMessage {
  const ChatMessage({
    required this.id,
    required this.conversationId,
    required this.senderId,
    required this.kind,
    required this.content,
    this.durationMs,
    this.flagged = false,
    required this.createdAt,
    this.pending = false,
    this.failed = false,
    this.localId,
  });

  final int id;
  final String conversationId;
  final String senderId;
  final MessageKind kind;

  /// Text body, or storage path for media kinds.
  final String content;
  final int? durationMs;
  final bool flagged;
  final DateTime createdAt;

  /// Optimistic-send bookkeeping (client only).
  final bool pending;
  final bool failed;
  final String? localId;

  factory ChatMessage.fromJson(Map<String, dynamic> json) => ChatMessage(
        id: (json['id'] as num).toInt(),
        conversationId: json['conversation_id'] as String,
        senderId: json['sender_id'] as String,
        kind: messageKindFrom(json['kind'] as String? ?? 'text'),
        content: json['content'] as String? ?? '',
        durationMs: (json['duration_ms'] as num?)?.toInt(),
        flagged: json['flagged'] as bool? ?? false,
        createdAt: DateTime.parse(json['created_at'] as String),
      );

  ChatMessage copyWith({bool? pending, bool? failed, int? id}) => ChatMessage(
        id: id ?? this.id,
        conversationId: conversationId,
        senderId: senderId,
        kind: kind,
        content: content,
        durationMs: durationMs,
        flagged: flagged,
        createdAt: createdAt,
        pending: pending ?? this.pending,
        failed: failed ?? this.failed,
        localId: localId,
      );
}

/// One row in the Matches / Chats list (from `my_conversations` RPC).
class ConversationSummary {
  const ConversationSummary({
    required this.conversationId,
    required this.matchId,
    required this.otherUserId,
    required this.otherFirstName,
    required this.otherLastName,
    required this.otherVerified,
    this.otherLastSeen,
    this.otherPhotoPath,
    this.lastMessageKind,
    this.lastMessageContent,
    this.lastMessageSender,
    required this.lastMessageAt,
    this.myLastReadAt,
    required this.unreadCount,
  });

  final String conversationId;
  final String matchId;
  final String otherUserId;
  final String otherFirstName;
  final String otherLastName;
  final bool otherVerified;
  final DateTime? otherLastSeen;
  final String? otherPhotoPath;
  final String? lastMessageKind;
  final String? lastMessageContent;
  final String? lastMessageSender;
  final DateTime lastMessageAt;
  final DateTime? myLastReadAt;
  final int unreadCount;

  bool get otherOnline =>
      otherLastSeen != null &&
      DateTime.now().toUtc().difference(otherLastSeen!.toUtc()).inMinutes < 2;

  factory ConversationSummary.fromJson(Map<String, dynamic> json) =>
      ConversationSummary(
        conversationId: json['conversation_id'] as String,
        matchId: json['match_id'] as String,
        otherUserId: json['other_user_id'] as String,
        otherFirstName: json['other_first_name'] as String? ?? '',
        otherLastName: json['other_last_name'] as String? ?? '',
        otherVerified: json['other_verified'] as bool? ?? false,
        otherLastSeen: json['other_last_seen'] == null
            ? null
            : DateTime.parse(json['other_last_seen'] as String),
        otherPhotoPath: json['other_photo_path'] as String?,
        lastMessageKind: json['last_message_kind'] as String?,
        lastMessageContent: json['last_message_content'] as String?,
        lastMessageSender: json['last_message_sender'] as String?,
        lastMessageAt: DateTime.parse(json['last_message_at'] as String),
        myLastReadAt: json['my_last_read_at'] == null
            ? null
            : DateTime.parse(json['my_last_read_at'] as String),
        unreadCount: (json['unread_count'] as num?)?.toInt() ?? 0,
      );
}
