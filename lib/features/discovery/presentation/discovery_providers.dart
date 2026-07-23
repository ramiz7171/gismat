import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/config/env.dart';
import '../../auth/presentation/session_providers.dart';
import '../data/discovery_repository.dart';
import '../domain/discovery_profile.dart';

part 'discovery_providers.g.dart';

@Riverpod(keepAlive: true)
DiscoveryRepository discoveryRepository(Ref ref) =>
    DiscoveryRepository(ref.watch(supabaseClientProvider));

/// Remaining swipes today (-1 = unlimited). Kept in sync by [Deck.swipe].
@Riverpod(keepAlive: true)
class SwipesRemaining extends _$SwipesRemaining {
  @override
  Future<int> build() async {
    final result =
        await ref.watch(discoveryRepositoryProvider).swipesRemaining();
    return result.remaining;
  }

  void set(int value) => state = AsyncData(value);
}

/// The discovery deck. Uses the nearby RPC with a wide radius; swiped
/// profiles never reappear (server-side exclusion). Falls back to the last
/// cached batch when offline.
@Riverpod(keepAlive: true)
class Deck extends _$Deck {
  @override
  Future<List<DiscoveryProfile>> build() async {
    final repo = ref.watch(discoveryRepositoryProvider);
    try {
      return await repo.fetchNearby(
          radiusKm: AppConstants.maxRadiusKm,
          maxResults: AppConstants.discoveryBatchSize);
    } catch (_) {
      final cached = await repo.cachedBatch();
      if (cached.isNotEmpty) return cached;
      rethrow;
    }
  }

  /// Records the swipe server-side. Throws AppException(P0001 → paywall).
  Future<void> swipe(DiscoveryProfile profile, {required bool like}) async {
    final repo = ref.read(discoveryRepositoryProvider);
    final result =
        await repo.recordSwipe(targetUserId: profile.id, like: like);
    ref.read(swipesRemainingProvider.notifier).set(result.remaining);
    _remember(profile);
  }

  /// Pokes the profile; a poke also consumes the card visually but not the
  /// swipe quota. Returns match info.
  Future<PokeResult> poke(DiscoveryProfile profile) async {
    final repo = ref.read(discoveryRepositoryProvider);
    final result = await repo.sendPoke(profile.id);
    _remember(profile);
    return result;
  }

  final List<DiscoveryProfile> _recentlySwiped = [];

  void _remember(DiscoveryProfile p) {
    _recentlySwiped.add(p);
    if (_recentlySwiped.length > 20) _recentlySwiped.removeAt(0);
  }

  /// Premium rewind: undoes the last swipe server-side and returns the
  /// profile so the UI can put the card back.
  Future<DiscoveryProfile?> rewind() async {
    final repo = ref.read(discoveryRepositoryProvider);
    final userId = await repo.rewindLastSwipe();
    if (userId == null) return null;
    ref.invalidate(swipesRemainingProvider);
    final idx = _recentlySwiped.lastIndexWhere((p) => p.id == userId);
    if (idx == -1) return null;
    return _recentlySwiped.removeAt(idx);
  }

  Future<void> reload() async {
    ref.invalidateSelf();
    await future;
  }
}

/// Nearby radius (km) persisted across sessions.
@Riverpod(keepAlive: true)
class NearbyRadius extends _$NearbyRadius {
  static const _key = 'nearby_radius_km';

  @override
  double build() {
    _restore();
    return AppConstants.defaultRadiusKm;
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final v = prefs.getDouble(_key);
    if (v != null) state = v;
  }

  Future<void> set(double km) async {
    state = km.clamp(AppConstants.minRadiusKm, AppConstants.maxRadiusKm);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble(_key, state);
  }
}

/// Nearby results for the current radius.
@riverpod
Future<List<DiscoveryProfile>> nearbyProfiles(Ref ref) async {
  final radius = ref.watch(nearbyRadiusProvider);
  return ref
      .watch(discoveryRepositoryProvider)
      .fetchNearby(radiusKm: radius, maxResults: 100);
}

/// Pokes I've received.
@riverpod
Future<List<ReceivedPoke>> receivedPokes(Ref ref) =>
    ref.watch(discoveryRepositoryProvider).pokesReceived();
