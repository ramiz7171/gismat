// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'admin_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$adminRepositoryHash() => r'f42e0fc6f874f95486cb55f9d2275c23399441fa';

/// See also [adminRepository].
@ProviderFor(adminRepository)
final adminRepositoryProvider = AutoDisposeProvider<AdminRepository>.internal(
  adminRepository,
  name: r'adminRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$adminRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AdminRepositoryRef = AutoDisposeProviderRef<AdminRepository>;
String _$adminReportsHash() => r'6ee6a4bbc3723a5d04f8f197f589feba6e75f79c';

/// Open reports (newest first).
///
/// Copied from [adminReports].
@ProviderFor(adminReports)
final adminReportsProvider =
    AutoDisposeFutureProvider<List<Map<String, dynamic>>>.internal(
      adminReports,
      name: r'adminReportsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$adminReportsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AdminReportsRef =
    AutoDisposeFutureProviderRef<List<Map<String, dynamic>>>;
String _$adminVerificationsHash() =>
    r'06defa00e21f77624b2f09df03111588c381fa63';

/// Profiles with a pending verification selfie.
///
/// Copied from [adminVerifications].
@ProviderFor(adminVerifications)
final adminVerificationsProvider =
    AutoDisposeFutureProvider<List<Map<String, dynamic>>>.internal(
      adminVerifications,
      name: r'adminVerificationsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$adminVerificationsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AdminVerificationsRef =
    AutoDisposeFutureProviderRef<List<Map<String, dynamic>>>;
String _$adminStatsHash() => r'bb6d9b437cd42434e7f4e85d2a7a8ee3578392f7';

/// Headline counters for the Stats tab.
///
/// Copied from [adminStats].
@ProviderFor(adminStats)
final adminStatsProvider = AutoDisposeFutureProvider<Map<String, int>>.internal(
  adminStats,
  name: r'adminStatsProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$adminStatsHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef AdminStatsRef = AutoDisposeFutureProviderRef<Map<String, int>>;
String _$adminUserSearchHash() => r'9a249d0236aa05e8b8944d47e6189ab6f201f564';

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

/// Debounced user search (family by query string).
///
/// Copied from [adminUserSearch].
@ProviderFor(adminUserSearch)
const adminUserSearchProvider = AdminUserSearchFamily();

/// Debounced user search (family by query string).
///
/// Copied from [adminUserSearch].
class AdminUserSearchFamily extends Family<AsyncValue<List<Profile>>> {
  /// Debounced user search (family by query string).
  ///
  /// Copied from [adminUserSearch].
  const AdminUserSearchFamily();

  /// Debounced user search (family by query string).
  ///
  /// Copied from [adminUserSearch].
  AdminUserSearchProvider call(String query) {
    return AdminUserSearchProvider(query);
  }

  @override
  AdminUserSearchProvider getProviderOverride(
    covariant AdminUserSearchProvider provider,
  ) {
    return call(provider.query);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'adminUserSearchProvider';
}

/// Debounced user search (family by query string).
///
/// Copied from [adminUserSearch].
class AdminUserSearchProvider extends AutoDisposeFutureProvider<List<Profile>> {
  /// Debounced user search (family by query string).
  ///
  /// Copied from [adminUserSearch].
  AdminUserSearchProvider(String query)
    : this._internal(
        (ref) => adminUserSearch(ref as AdminUserSearchRef, query),
        from: adminUserSearchProvider,
        name: r'adminUserSearchProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$adminUserSearchHash,
        dependencies: AdminUserSearchFamily._dependencies,
        allTransitiveDependencies:
            AdminUserSearchFamily._allTransitiveDependencies,
        query: query,
      );

  AdminUserSearchProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.query,
  }) : super.internal();

  final String query;

  @override
  Override overrideWith(
    FutureOr<List<Profile>> Function(AdminUserSearchRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: AdminUserSearchProvider._internal(
        (ref) => create(ref as AdminUserSearchRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        query: query,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<Profile>> createElement() {
    return _AdminUserSearchProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is AdminUserSearchProvider && other.query == query;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, query.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin AdminUserSearchRef on AutoDisposeFutureProviderRef<List<Profile>> {
  /// The parameter `query` of this provider.
  String get query;
}

class _AdminUserSearchProviderElement
    extends AutoDisposeFutureProviderElement<List<Profile>>
    with AdminUserSearchRef {
  _AdminUserSearchProviderElement(super.provider);

  @override
  String get query => (origin as AdminUserSearchProvider).query;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
