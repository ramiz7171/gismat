import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/app_exception.dart';
import '../../profile/domain/profile.dart';

/// Moderation/administration data access. All calls are RLS-guarded server
/// side (admin-only policies); errors are normalized through [mapError].
class AdminRepository {
  AdminRepository(this._client);

  final SupabaseClient _client;

  /// Searches profiles by first/last name (ILIKE). Empty query returns the
  /// latest 50 signups.
  Future<List<Profile>> searchUsers(String query) async {
    try {
      final q = query.trim();
      final List<dynamic> rows;
      if (q.isEmpty) {
        rows = await _client
            .from('profiles')
            .select()
            .order('created_at', ascending: false)
            .limit(50);
      } else {
        rows = await _client
            .from('profiles')
            .select()
            .or('first_name.ilike.%$q%,last_name.ilike.%$q%')
            .order('created_at', ascending: false)
            .limit(50);
      }
      return rows
          .map((r) => Profile.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw mapError(e);
    }
  }

  Future<void> setBanned(String userId, bool banned) async {
    try {
      await _client
          .from('profiles')
          .update({'is_banned': banned}).eq('id', userId);
    } catch (e) {
      throw mapError(e);
    }
  }

  /// Open reports, newest first, with reporter/reported names joined in.
  Future<List<Map<String, dynamic>>> fetchReports() async {
    try {
      final rows = await _client
          .from('reports')
          .select(
              '*, reporter:reporter_id(first_name,last_name), reported:reported_id(first_name,last_name)')
          .eq('status', 'open')
          .order('created_at', ascending: false);
      return (rows as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw mapError(e);
    }
  }

  /// [status] is one of: 'reviewed' | 'actioned' | 'dismissed'.
  Future<void> setReportStatus(String reportId, String status) async {
    try {
      await _client
          .from('reports')
          .update({'status': status}).eq('id', reportId);
    } catch (e) {
      throw mapError(e);
    }
  }

  Future<List<Map<String, dynamic>>> fetchPendingVerifications() async {
    try {
      final rows = await _client
          .from('profiles')
          .select('id, first_name, last_name, verification_photo_path')
          .eq('verification_status', 'pending');
      return (rows as List).cast<Map<String, dynamic>>();
    } catch (e) {
      throw mapError(e);
    }
  }

  Future<void> resolveVerification(String userId,
      {required bool approve}) async {
    try {
      await _client.from('profiles').update({
        'verification_status': approve ? 'approved' : 'rejected',
        'is_verified': approve,
      }).eq('id', userId);
    } catch (e) {
      throw mapError(e);
    }
  }

  /// Head-count requests: users / matches / messages / open reports.
  Future<Map<String, int>> fetchStats() async {
    try {
      final users = await _client.from('profiles').count(CountOption.exact);
      final matches = await _client.from('matches').count(CountOption.exact);
      final messages = await _client.from('messages').count(CountOption.exact);
      final openReports = await _client
          .from('reports')
          .select('id')
          .eq('status', 'open')
          .count(CountOption.exact);
      return {
        'users': users,
        'matches': matches,
        'messages': messages,
        'openReports': openReports.count,
      };
    } catch (e) {
      throw mapError(e);
    }
  }
}
