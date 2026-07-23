// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'discovery_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$discoveryRepositoryHash() =>
    r'7669546ea8f48e1f96deac435ed775f49958a318';

/// See also [discoveryRepository].
@ProviderFor(discoveryRepository)
final discoveryRepositoryProvider = Provider<DiscoveryRepository>.internal(
  discoveryRepository,
  name: r'discoveryRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$discoveryRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef DiscoveryRepositoryRef = ProviderRef<DiscoveryRepository>;
String _$nearbyProfilesHash() => r'9cdfa2e2c0837e36a018834ac2f6539281f4bed1';

/// Nearby results for the current radius.
///
/// Copied from [nearbyProfiles].
@ProviderFor(nearbyProfiles)
final nearbyProfilesProvider =
    AutoDisposeFutureProvider<List<DiscoveryProfile>>.internal(
      nearbyProfiles,
      name: r'nearbyProfilesProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$nearbyProfilesHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef NearbyProfilesRef =
    AutoDisposeFutureProviderRef<List<DiscoveryProfile>>;
String _$receivedPokesHash() => r'8671b3aa25fd4652dfba5a1b4711559c557696c5';

/// Pokes I've received.
///
/// Copied from [receivedPokes].
@ProviderFor(receivedPokes)
final receivedPokesProvider =
    AutoDisposeFutureProvider<List<ReceivedPoke>>.internal(
      receivedPokes,
      name: r'receivedPokesProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$receivedPokesHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ReceivedPokesRef = AutoDisposeFutureProviderRef<List<ReceivedPoke>>;
String _$swipesRemainingHash() => r'0166bc6687bf07ef9091a4f83e1299cdaae22e50';

/// Remaining swipes today (-1 = unlimited). Kept in sync by [Deck.swipe].
///
/// Copied from [SwipesRemaining].
@ProviderFor(SwipesRemaining)
final swipesRemainingProvider =
    AsyncNotifierProvider<SwipesRemaining, int>.internal(
      SwipesRemaining.new,
      name: r'swipesRemainingProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$swipesRemainingHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$SwipesRemaining = AsyncNotifier<int>;
String _$deckHash() => r'e472e7e1fde37e0718ebcaa886d51edfad863102';

/// The discovery deck. Uses the nearby RPC with a wide radius; swiped
/// profiles never reappear (server-side exclusion). Falls back to the last
/// cached batch when offline.
///
/// Copied from [Deck].
@ProviderFor(Deck)
final deckProvider =
    AsyncNotifierProvider<Deck, List<DiscoveryProfile>>.internal(
      Deck.new,
      name: r'deckProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$deckHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$Deck = AsyncNotifier<List<DiscoveryProfile>>;
String _$nearbyRadiusHash() => r'7f4101bedef18888ebf586163f48ee9d8605a3cf';

/// Nearby radius (km) persisted across sessions.
///
/// Copied from [NearbyRadius].
@ProviderFor(NearbyRadius)
final nearbyRadiusProvider = NotifierProvider<NearbyRadius, double>.internal(
  NearbyRadius.new,
  name: r'nearbyRadiusProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$nearbyRadiusHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$NearbyRadius = Notifier<double>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
