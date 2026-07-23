import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/app_exception.dart';
import '../domain/discovery_profile.dart';

/// Discovery / Nearby / Poke data access. All writes go through
/// SECURITY DEFINER RPCs — the daily quota can't be bypassed client-side.
class DiscoveryRepository {
  DiscoveryRepository(this._client);

  final SupabaseClient _client;

  static const _cacheKey = 'discovery_cache_v1';

  Future<List<DiscoveryProfile>> fetchNearby({
    required double radiusKm,
    int maxResults = 50,
  }) async {
    try {
      final rows = await _client.rpc<dynamic>('nearby_profiles', params: {
        'radius_km': radiusKm,
        'max_results': maxResults,
      });
      final list = (rows as List)
          .map((r) => DiscoveryProfile.fromJson(r as Map<String, dynamic>))
          .toList();
      _cacheBatch(list);
      return list;
    } catch (e) {
      throw mapError(e);
    }
  }

  /// Offline resilience: last successful batch, served when fetch fails.
  Future<List<DiscoveryProfile>> cachedBatch() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_cacheKey);
      if (raw == null) return const [];
      return (jsonDecode(raw) as List)
          .map((r) => DiscoveryProfile.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _cacheBatch(List<DiscoveryProfile> profiles) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
          _cacheKey,
          jsonEncode([
            for (final p in profiles)
              {
                'id': p.id,
                'first_name': p.firstName,
                'last_name': p.lastName,
                'age': p.age,
                'bio': p.bio,
                'gender': p.gender,
                'is_verified': p.isVerified,
                'last_seen': p.lastSeen?.toIso8601String(),
                'distance_m': p.distanceM,
                'photo_paths': p.photoPaths,
              }
          ]));
    } catch (_) {
      // cache is best-effort
    }
  }

  Future<SwipeResult> recordSwipe({
    required String targetUserId,
    required bool like,
  }) async {
    try {
      final res = await _client.rpc<dynamic>('record_swipe', params: {
        'target_user': targetUserId,
        'swipe_direction': like ? 'like' : 'pass',
      });
      return SwipeResult.fromJson((res as Map).cast<String, dynamic>());
    } catch (e) {
      throw mapError(e);
    }
  }

  Future<SwipeResult> swipesRemaining() async {
    try {
      final res = await _client.rpc<dynamic>('swipes_remaining');
      return SwipeResult.fromJson((res as Map).cast<String, dynamic>());
    } catch (e) {
      throw mapError(e);
    }
  }

  /// Returns the user id of the un-swiped profile, or null.
  Future<String?> rewindLastSwipe() async {
    try {
      final res = await _client.rpc<dynamic>('rewind_last_swipe');
      final map = (res as Map).cast<String, dynamic>();
      return map['rewound'] == true ? map['user_id'] as String? : null;
    } catch (e) {
      throw mapError(e);
    }
  }

  Future<PokeResult> sendPoke(String targetUserId) async {
    try {
      final res = await _client
          .rpc<dynamic>('send_poke', params: {'target_user': targetUserId});
      return PokeResult.fromJson((res as Map).cast<String, dynamic>());
    } catch (e) {
      throw mapError(e);
    }
  }

  Future<List<ReceivedPoke>> pokesReceived() async {
    try {
      final rows = await _client.rpc<dynamic>('pokes_received');
      return (rows as List)
          .map((r) => ReceivedPoke.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw mapError(e);
    }
  }

  String publicPhotoUrl(String storagePath) =>
      _client.storage.from('profile-photos').getPublicUrl(storagePath);
}
