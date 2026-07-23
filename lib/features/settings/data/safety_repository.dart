import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/app_exception.dart';

/// Blocks + reports (reachable from cards, chat and match list in ≤2 taps).
class SafetyRepository {
  SafetyRepository(this._client);

  final SupabaseClient _client;

  String get _uid => _client.auth.currentUser!.id;

  Future<void> blockUser(String userId) async {
    try {
      await _client.from('blocks').upsert(
          {'blocker_id': _uid, 'blocked_id': userId},
          onConflict: 'blocker_id,blocked_id');
    } catch (e) {
      throw mapError(e);
    }
  }

  Future<void> unblockUser(String userId) async {
    try {
      await _client
          .from('blocks')
          .delete()
          .match({'blocker_id': _uid, 'blocked_id': userId});
    } catch (e) {
      throw mapError(e);
    }
  }

  /// Blocked users joined with their profile names.
  Future<List<Map<String, dynamic>>> fetchBlockedUsers() async {
    try {
      final rows = await _client
          .from('blocks')
          .select('blocked_id, created_at, profiles:blocked_id(first_name, last_name)')
          .eq('blocker_id', _uid);
      return (rows as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw mapError(e);
    }
  }

  Future<void> reportUser({
    required String userId,
    required String reason,
    String? details,
  }) async {
    try {
      await _client.from('reports').insert({
        'reporter_id': _uid,
        'reported_id': userId,
        'reason': reason,
        'details': details,
      });
    } catch (e) {
      throw mapError(e);
    }
  }

  Future<void> unmatch(String matchId) async {
    try {
      await _client.rpc<void>('unmatch', params: {'target_match': matchId});
    } catch (e) {
      throw mapError(e);
    }
  }
}
