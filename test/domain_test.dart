import 'package:flutter_test/flutter_test.dart';
import 'package:gismat/features/chat/domain/message.dart';
import 'package:gismat/features/discovery/domain/discovery_profile.dart';
import 'package:gismat/features/profile/domain/profile.dart';

void main() {
  test('TierLimit.fromJson maps null daily limit to unlimited', () {
    final basic = TierLimit.fromJson(
        {'tier': 'basic', 'daily_swipe_limit': 8, 'max_photos': 3});
    final max = TierLimit.fromJson(
        {'tier': 'max', 'daily_swipe_limit': null, 'max_photos': 10});
    expect(basic.dailySwipeLimit, 8);
    expect(basic.maxPhotos, 3);
    expect(max.dailySwipeLimit, isNull);
  });

  test('Profile.fromJson parses and computes age', () {
    final p = Profile.fromJson({
      'id': 'u1',
      'first_name': 'Aygün',
      'last_name': 'Məmmədova',
      'date_of_birth': '2000-01-15',
      'gender': 'female',
      'interested_in': ['male'],
      'tier': 'pro',
      'is_admin': false,
      'is_verified': true,
      'is_snoozed': false,
      'verification_status': 'approved',
    });
    expect(p.fullName, 'Aygün Məmmədova');
    expect(p.tier, 'pro');
    expect(p.isVerified, isTrue);
    expect(p.age, greaterThanOrEqualTo(26));
  });

  test('SwipeResult defaults', () {
    final r = SwipeResult.fromJson({'remaining': 5, 'tier': 'basic'});
    expect(r.remaining, 5);
    final unlimited = SwipeResult.fromJson({'tier': 'max'});
    expect(unlimited.remaining, -1);
  });

  test('PokeResult parses match payload', () {
    final matched = PokeResult.fromJson(
        {'matched': true, 'conversation_id': 'c1'});
    expect(matched.matched, isTrue);
    expect(matched.conversationId, 'c1');
    final not = PokeResult.fromJson({'matched': false});
    expect(not.matched, isFalse);
    expect(not.conversationId, isNull);
  });

  test('ChatMessage.fromJson maps kinds', () {
    final m = ChatMessage.fromJson({
      'id': 7,
      'conversation_id': 'c1',
      'sender_id': 'u1',
      'kind': 'voice',
      'content': 'c1/x.m4a',
      'duration_ms': 4200,
      'created_at': '2026-07-23T10:00:00Z',
    });
    expect(m.kind, MessageKind.voice);
    expect(m.durationMs, 4200);
    expect(m.pending, isFalse);
  });

  test('DiscoveryProfile online window is 2 minutes', () {
    final online = DiscoveryProfile.fromJson({
      'id': 'u1',
      'first_name': 'A',
      'last_name': 'B',
      'age': 20,
      'is_verified': false,
      'last_seen':
          DateTime.now().toUtc().subtract(const Duration(seconds: 30)).toIso8601String(),
      'distance_m': 1200.0,
      'photo_paths': ['u1/a.jpg'],
    });
    expect(online.isOnline, isTrue);

    final offline = DiscoveryProfile.fromJson({
      'id': 'u2',
      'first_name': 'C',
      'last_name': 'D',
      'age': 30,
      'is_verified': false,
      'last_seen': DateTime.now()
          .toUtc()
          .subtract(const Duration(hours: 3))
          .toIso8601String(),
      'distance_m': 500.0,
      'photo_paths': [],
    });
    expect(offline.isOnline, isFalse);
  });

  test('ConversationSummary unread + online mapping', () {
    final c = ConversationSummary.fromJson({
      'conversation_id': 'c1',
      'match_id': 'm1',
      'other_user_id': 'u2',
      'other_first_name': 'Leyla',
      'other_last_name': 'A',
      'other_verified': true,
      'other_last_seen': null,
      'other_photo_path': 'u2/p.jpg',
      'last_message_kind': 'text',
      'last_message_content': 'Salam!',
      'last_message_sender': 'u2',
      'last_message_at': '2026-07-23T09:00:00Z',
      'my_last_read_at': null,
      'unread_count': 3,
    });
    expect(c.unreadCount, 3);
    expect(c.otherOnline, isFalse);
    expect(c.otherFirstName, 'Leyla');
  });
}
