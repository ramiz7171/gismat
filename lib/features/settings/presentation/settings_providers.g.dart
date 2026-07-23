// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'settings_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$safetyRepositoryHash() => r'eb0f077d1f3826a782aa2c60e1908a4d358d398a';

/// See also [safetyRepository].
@ProviderFor(safetyRepository)
final safetyRepositoryProvider = Provider<SafetyRepository>.internal(
  safetyRepository,
  name: r'safetyRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$safetyRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef SafetyRepositoryRef = ProviderRef<SafetyRepository>;
String _$blockedUsersHash() => r'ec50584d2d905bb93cae9c895c7493c032d59bbe';

/// Blocked users joined with their profile names.
///
/// Copied from [blockedUsers].
@ProviderFor(blockedUsers)
final blockedUsersProvider =
    AutoDisposeFutureProvider<List<Map<String, dynamic>>>.internal(
      blockedUsers,
      name: r'blockedUsersProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$blockedUsersHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef BlockedUsersRef =
    AutoDisposeFutureProviderRef<List<Map<String, dynamic>>>;
String _$blurExplicitImagesHash() =>
    r'12856bbc3a1af8acf8b75621cfb19df02fe2a256';

/// Whether possibly explicit images are blurred until tapped. Default: on.
///
/// Copied from [BlurExplicitImages].
@ProviderFor(BlurExplicitImages)
final blurExplicitImagesProvider =
    NotifierProvider<BlurExplicitImages, bool>.internal(
      BlurExplicitImages.new,
      name: r'blurExplicitImagesProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$blurExplicitImagesHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$BlurExplicitImages = Notifier<bool>;
String _$notificationsEnabledHash() =>
    r'26a9ae59a333ed64183ff8576d28d552538a3f99';

/// Local push-notification preference. Default: on.
///
/// Copied from [NotificationsEnabled].
@ProviderFor(NotificationsEnabled)
final notificationsEnabledProvider =
    NotifierProvider<NotificationsEnabled, bool>.internal(
      NotificationsEnabled.new,
      name: r'notificationsEnabledProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$notificationsEnabledHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$NotificationsEnabled = Notifier<bool>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
