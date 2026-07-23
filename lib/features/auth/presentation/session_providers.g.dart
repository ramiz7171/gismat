// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'session_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$supabaseClientHash() => r'3db2a4c212c7f24cea9810e376225aa1a6cab012';

/// See also [supabaseClient].
@ProviderFor(supabaseClient)
final supabaseClientProvider = Provider<SupabaseClient>.internal(
  supabaseClient,
  name: r'supabaseClientProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$supabaseClientHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SupabaseClientRef = ProviderRef<SupabaseClient>;
String _$authRepositoryHash() => r'2f243b04dd88d4803e0fb0a51d03fefcc7e7d876';

/// See also [authRepository].
@ProviderFor(authRepository)
final authRepositoryProvider = Provider<AuthRepository>.internal(
  authRepository,
  name: r'authRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$authRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AuthRepositoryRef = ProviderRef<AuthRepository>;
String _$profileRepositoryHash() => r'ae38b14b12f65cba9317db127821ef29f957fd3f';

/// See also [profileRepository].
@ProviderFor(profileRepository)
final profileRepositoryProvider = Provider<ProfileRepository>.internal(
  profileRepository,
  name: r'profileRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$profileRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ProfileRepositoryRef = ProviderRef<ProfileRepository>;
String _$authStateChangesHash() => r'310af7ac668b2f2faabbc6d8fc00b2b768260eed';

/// See also [authStateChanges].
@ProviderFor(authStateChanges)
final authStateChangesProvider = StreamProvider<AuthState>.internal(
  authStateChanges,
  name: r'authStateChangesProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$authStateChangesHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AuthStateChangesRef = StreamProviderRef<AuthState>;
String _$currentUserHash() => r'18cf8d7a817a4acbffe7f9b1c912490aee4f8e93';

/// The signed-in user, kept in sync with auth events.
///
/// Copied from [currentUser].
@ProviderFor(currentUser)
final currentUserProvider = Provider<User?>.internal(
  currentUser,
  name: r'currentUserProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$currentUserHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef CurrentUserRef = ProviderRef<User?>;
String _$tierLimitsHash() => r'33e7634ed6807988cd3195968b4686aecaf18208';

/// Tier limits straight from the database — the app never hardcodes them.
///
/// Copied from [tierLimits].
@ProviderFor(tierLimits)
final tierLimitsProvider = FutureProvider<List<TierLimit>>.internal(
  tierLimits,
  name: r'tierLimitsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$tierLimitsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef TierLimitsRef = FutureProviderRef<List<TierLimit>>;
String _$myProfileHash() => r'6ddf771146c16ea7922998d52ef4350a156eb18f';

/// Own profile row (null until onboarding creates it).
///
/// Copied from [MyProfile].
@ProviderFor(MyProfile)
final myProfileProvider = AsyncNotifierProvider<MyProfile, Profile?>.internal(
  MyProfile.new,
  name: r'myProfileProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$myProfileHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$MyProfile = AsyncNotifier<Profile?>;
String _$myPhotosHash() => r'76c0755c453f6c43b2c515d9e6a769b4667d8a56';

/// Own photos, ordered by position.
///
/// Copied from [MyPhotos].
@ProviderFor(MyPhotos)
final myPhotosProvider =
    AsyncNotifierProvider<MyPhotos, List<ProfilePhoto>>.internal(
      MyPhotos.new,
      name: r'myPhotosProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$myPhotosHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$MyPhotos = AsyncNotifier<List<ProfilePhoto>>;
String _$authGateHash() => r'6b9e80e875904aec367a45438a8f6e0b696c5ef2';

/// Single source of truth for routing decisions.
///
/// Copied from [AuthGate].
@ProviderFor(AuthGate)
final authGateProvider = AsyncNotifierProvider<AuthGate, GateStatus>.internal(
  AuthGate.new,
  name: r'authGateProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$authGateHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AuthGate = AsyncNotifier<GateStatus>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
