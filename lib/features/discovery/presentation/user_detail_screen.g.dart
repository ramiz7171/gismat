// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_detail_screen.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$userDetailHash() => r'd60918367a6683f90c1551c406523615f9d0706d';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [userDetail].
@ProviderFor(userDetail)
const userDetailProvider = UserDetailFamily();

/// See also [userDetail].
class UserDetailFamily
    extends Family<AsyncValue<(Profile?, List<ProfilePhoto>)>> {
  /// See also [userDetail].
  const UserDetailFamily();

  /// See also [userDetail].
  UserDetailProvider call(String userId) {
    return UserDetailProvider(userId);
  }

  @override
  UserDetailProvider getProviderOverride(
    covariant UserDetailProvider provider,
  ) {
    return call(provider.userId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'userDetailProvider';
}

/// See also [userDetail].
class UserDetailProvider
    extends AutoDisposeFutureProvider<(Profile?, List<ProfilePhoto>)> {
  /// See also [userDetail].
  UserDetailProvider(String userId)
    : this._internal(
        (ref) => userDetail(ref as UserDetailRef, userId),
        from: userDetailProvider,
        name: r'userDetailProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$userDetailHash,
        dependencies: UserDetailFamily._dependencies,
        allTransitiveDependencies: UserDetailFamily._allTransitiveDependencies,
        userId: userId,
      );

  UserDetailProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.userId,
  }) : super.internal();

  final String userId;

  @override
  Override overrideWith(
    FutureOr<(Profile?, List<ProfilePhoto>)> Function(UserDetailRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: UserDetailProvider._internal(
        (ref) => create(ref as UserDetailRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        userId: userId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<(Profile?, List<ProfilePhoto>)>
  createElement() {
    return _UserDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is UserDetailProvider && other.userId == userId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin UserDetailRef
    on AutoDisposeFutureProviderRef<(Profile?, List<ProfilePhoto>)> {
  /// The parameter `userId` of this provider.
  String get userId;
}

class _UserDetailProviderElement
    extends AutoDisposeFutureProviderElement<(Profile?, List<ProfilePhoto>)>
    with UserDetailRef {
  _UserDetailProviderElement(super.provider);

  @override
  String get userId => (origin as UserDetailProvider).userId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
