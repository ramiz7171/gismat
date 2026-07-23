import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/config/env.dart';
import '../../profile/data/profile_repository.dart';
import '../../profile/domain/profile.dart';
import '../data/auth_repository.dart';

part 'session_providers.g.dart';

@Riverpod(keepAlive: true)
SupabaseClient supabaseClient(Ref ref) => Supabase.instance.client;

@Riverpod(keepAlive: true)
AuthRepository authRepository(Ref ref) =>
    AuthRepository(ref.watch(supabaseClientProvider));

@Riverpod(keepAlive: true)
ProfileRepository profileRepository(Ref ref) =>
    ProfileRepository(ref.watch(supabaseClientProvider));

@Riverpod(keepAlive: true)
Stream<AuthState> authStateChanges(Ref ref) =>
    ref.watch(supabaseClientProvider).auth.onAuthStateChange;

/// The signed-in user, kept in sync with auth events.
@Riverpod(keepAlive: true)
User? currentUser(Ref ref) {
  ref.watch(authStateChangesProvider);
  return ref.watch(supabaseClientProvider).auth.currentUser;
}

/// Own profile row (null until onboarding creates it).
@Riverpod(keepAlive: true)
class MyProfile extends _$MyProfile {
  @override
  Future<Profile?> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return null;
    return ref.read(profileRepositoryProvider).fetchMyProfile();
  }

  Future<void> reload() async {
    ref.invalidateSelf();
    await future;
  }
}

/// Own photos, ordered by position.
@Riverpod(keepAlive: true)
class MyPhotos extends _$MyPhotos {
  @override
  Future<List<ProfilePhoto>> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return const [];
    return ref.read(profileRepositoryProvider).fetchMyPhotos();
  }

  Future<void> reload() async {
    ref.invalidateSelf();
    await future;
  }
}

/// Tier limits straight from the database — the app never hardcodes them.
@Riverpod(keepAlive: true)
Future<List<TierLimit>> tierLimits(Ref ref) =>
    ref.watch(profileRepositoryProvider).fetchTierLimits();

enum GateStatus { loading, unauthenticated, needsOnboarding, ready }

/// Single source of truth for routing decisions.
@Riverpod(keepAlive: true)
class AuthGate extends _$AuthGate {
  @override
  Future<GateStatus> build() async {
    final user = ref.watch(currentUserProvider);
    if (user == null) return GateStatus.unauthenticated;
    final profile = await ref.watch(myProfileProvider.future);
    if (profile == null) return GateStatus.needsOnboarding;
    final photos = await ref.watch(myPhotosProvider.future);
    if (photos.length < AppConstants.minPhotos) {
      return GateStatus.needsOnboarding;
    }
    return GateStatus.ready;
  }
}
