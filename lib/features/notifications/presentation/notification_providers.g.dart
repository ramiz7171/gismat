// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notification_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$notificationsFeedHash() => r'b00498d005150cf7250194f24a93145d885ac106';

/// Live in-app notification feed (Supabase realtime stream, RLS-scoped).
///
/// Copied from [notificationsFeed].
@ProviderFor(notificationsFeed)
final notificationsFeedProvider =
    AutoDisposeStreamProvider<List<AppNotification>>.internal(
      notificationsFeed,
      name: r'notificationsFeedProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$notificationsFeedHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef NotificationsFeedRef =
    AutoDisposeStreamProviderRef<List<AppNotification>>;
String _$unreadNotificationCountHash() =>
    r'b9ebf2aa66b06c9330f8baff1b78bd0b43905c00';

/// See also [unreadNotificationCount].
@ProviderFor(unreadNotificationCount)
final unreadNotificationCountProvider = AutoDisposeProvider<int>.internal(
  unreadNotificationCount,
  name: r'unreadNotificationCountProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$unreadNotificationCountHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef UnreadNotificationCountRef = AutoDisposeProviderRef<int>;
String _$notificationActionsHash() =>
    r'dd65abb72ac3e32c484763a904c4cef7e97a447a';

/// Actions on notifications.
///
/// Copied from [NotificationActions].
@ProviderFor(NotificationActions)
final notificationActionsProvider =
    AutoDisposeNotifierProvider<NotificationActions, void>.internal(
      NotificationActions.new,
      name: r'notificationActionsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$notificationActionsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

typedef _$NotificationActions = AutoDisposeNotifier<void>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
