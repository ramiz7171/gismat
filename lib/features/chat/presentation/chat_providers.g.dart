// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chat_providers.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$chatRepositoryHash() => r'065908b1363f12683733b88a74c59e856e4fdb0b';

/// See also [chatRepository].
@ProviderFor(chatRepository)
final chatRepositoryProvider = Provider<ChatRepository>.internal(
  chatRepository,
  name: r'chatRepositoryProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$chatRepositoryHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ChatRepositoryRef = ProviderRef<ChatRepository>;
String _$conversationsHash() => r'63bfcd5b6e4c51060f3dc87a1b17d77bbbab6a87';

/// The Matches / Chats list.
///
/// Copied from [conversations].
@ProviderFor(conversations)
final conversationsProvider =
    AutoDisposeFutureProvider<List<ConversationSummary>>.internal(
      conversations,
      name: r'conversationsProvider',
      debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
          ? null
          : _$conversationsHash,
      dependencies: null,
      allTransitiveDependencies: null,
    );

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef ConversationsRef =
    AutoDisposeFutureProviderRef<List<ConversationSummary>>;
String _$conversationMessagesHash() =>
    r'c425d71bc9f2e2da56667a5402ccec84dc130521';

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

/// Realtime message stream for one conversation (newest first — matches the
/// reversed ListView).
///
/// Copied from [conversationMessages].
@ProviderFor(conversationMessages)
const conversationMessagesProvider = ConversationMessagesFamily();

/// Realtime message stream for one conversation (newest first — matches the
/// reversed ListView).
///
/// Copied from [conversationMessages].
class ConversationMessagesFamily extends Family<AsyncValue<List<ChatMessage>>> {
  /// Realtime message stream for one conversation (newest first — matches the
  /// reversed ListView).
  ///
  /// Copied from [conversationMessages].
  const ConversationMessagesFamily();

  /// Realtime message stream for one conversation (newest first — matches the
  /// reversed ListView).
  ///
  /// Copied from [conversationMessages].
  ConversationMessagesProvider call(String conversationId) {
    return ConversationMessagesProvider(conversationId);
  }

  @override
  ConversationMessagesProvider getProviderOverride(
    covariant ConversationMessagesProvider provider,
  ) {
    return call(provider.conversationId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'conversationMessagesProvider';
}

/// Realtime message stream for one conversation (newest first — matches the
/// reversed ListView).
///
/// Copied from [conversationMessages].
class ConversationMessagesProvider
    extends AutoDisposeStreamProvider<List<ChatMessage>> {
  /// Realtime message stream for one conversation (newest first — matches the
  /// reversed ListView).
  ///
  /// Copied from [conversationMessages].
  ConversationMessagesProvider(String conversationId)
    : this._internal(
        (ref) => conversationMessages(
          ref as ConversationMessagesRef,
          conversationId,
        ),
        from: conversationMessagesProvider,
        name: r'conversationMessagesProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$conversationMessagesHash,
        dependencies: ConversationMessagesFamily._dependencies,
        allTransitiveDependencies:
            ConversationMessagesFamily._allTransitiveDependencies,
        conversationId: conversationId,
      );

  ConversationMessagesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.conversationId,
  }) : super.internal();

  final String conversationId;

  @override
  Override overrideWith(
    Stream<List<ChatMessage>> Function(ConversationMessagesRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ConversationMessagesProvider._internal(
        (ref) => create(ref as ConversationMessagesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        conversationId: conversationId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<List<ChatMessage>> createElement() {
    return _ConversationMessagesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ConversationMessagesProvider &&
        other.conversationId == conversationId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, conversationId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ConversationMessagesRef
    on AutoDisposeStreamProviderRef<List<ChatMessage>> {
  /// The parameter `conversationId` of this provider.
  String get conversationId;
}

class _ConversationMessagesProviderElement
    extends AutoDisposeStreamProviderElement<List<ChatMessage>>
    with ConversationMessagesRef {
  _ConversationMessagesProviderElement(super.provider);

  @override
  String get conversationId =>
      (origin as ConversationMessagesProvider).conversationId;
}

String _$otherReadAtHash() => r'1127aea326946a7971ef7fe7eb8941ef36dca50b';

/// Other participant's read cursor for receipts.
///
/// Copied from [otherReadAt].
@ProviderFor(otherReadAt)
const otherReadAtProvider = OtherReadAtFamily();

/// Other participant's read cursor for receipts.
///
/// Copied from [otherReadAt].
class OtherReadAtFamily extends Family<AsyncValue<DateTime?>> {
  /// Other participant's read cursor for receipts.
  ///
  /// Copied from [otherReadAt].
  const OtherReadAtFamily();

  /// Other participant's read cursor for receipts.
  ///
  /// Copied from [otherReadAt].
  OtherReadAtProvider call(String conversationId) {
    return OtherReadAtProvider(conversationId);
  }

  @override
  OtherReadAtProvider getProviderOverride(
    covariant OtherReadAtProvider provider,
  ) {
    return call(provider.conversationId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'otherReadAtProvider';
}

/// Other participant's read cursor for receipts.
///
/// Copied from [otherReadAt].
class OtherReadAtProvider extends AutoDisposeStreamProvider<DateTime?> {
  /// Other participant's read cursor for receipts.
  ///
  /// Copied from [otherReadAt].
  OtherReadAtProvider(String conversationId)
    : this._internal(
        (ref) => otherReadAt(ref as OtherReadAtRef, conversationId),
        from: otherReadAtProvider,
        name: r'otherReadAtProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$otherReadAtHash,
        dependencies: OtherReadAtFamily._dependencies,
        allTransitiveDependencies: OtherReadAtFamily._allTransitiveDependencies,
        conversationId: conversationId,
      );

  OtherReadAtProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.conversationId,
  }) : super.internal();

  final String conversationId;

  @override
  Override overrideWith(
    Stream<DateTime?> Function(OtherReadAtRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: OtherReadAtProvider._internal(
        (ref) => create(ref as OtherReadAtRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        conversationId: conversationId,
      ),
    );
  }

  @override
  AutoDisposeStreamProviderElement<DateTime?> createElement() {
    return _OtherReadAtProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is OtherReadAtProvider &&
        other.conversationId == conversationId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, conversationId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin OtherReadAtRef on AutoDisposeStreamProviderRef<DateTime?> {
  /// The parameter `conversationId` of this provider.
  String get conversationId;
}

class _OtherReadAtProviderElement
    extends AutoDisposeStreamProviderElement<DateTime?>
    with OtherReadAtRef {
  _OtherReadAtProviderElement(super.provider);

  @override
  String get conversationId => (origin as OtherReadAtProvider).conversationId;
}

String _$conversationSummaryHash() =>
    r'8c5afa20ce653db2c3ce7d118d2cfc9cc0f2fa5b';

/// Header info for the chat screen (from the conversations list).
///
/// Copied from [conversationSummary].
@ProviderFor(conversationSummary)
const conversationSummaryProvider = ConversationSummaryFamily();

/// Header info for the chat screen (from the conversations list).
///
/// Copied from [conversationSummary].
class ConversationSummaryFamily
    extends Family<AsyncValue<ConversationSummary?>> {
  /// Header info for the chat screen (from the conversations list).
  ///
  /// Copied from [conversationSummary].
  const ConversationSummaryFamily();

  /// Header info for the chat screen (from the conversations list).
  ///
  /// Copied from [conversationSummary].
  ConversationSummaryProvider call(String conversationId) {
    return ConversationSummaryProvider(conversationId);
  }

  @override
  ConversationSummaryProvider getProviderOverride(
    covariant ConversationSummaryProvider provider,
  ) {
    return call(provider.conversationId);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'conversationSummaryProvider';
}

/// Header info for the chat screen (from the conversations list).
///
/// Copied from [conversationSummary].
class ConversationSummaryProvider
    extends AutoDisposeFutureProvider<ConversationSummary?> {
  /// Header info for the chat screen (from the conversations list).
  ///
  /// Copied from [conversationSummary].
  ConversationSummaryProvider(String conversationId)
    : this._internal(
        (ref) =>
            conversationSummary(ref as ConversationSummaryRef, conversationId),
        from: conversationSummaryProvider,
        name: r'conversationSummaryProvider',
        debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
            ? null
            : _$conversationSummaryHash,
        dependencies: ConversationSummaryFamily._dependencies,
        allTransitiveDependencies:
            ConversationSummaryFamily._allTransitiveDependencies,
        conversationId: conversationId,
      );

  ConversationSummaryProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.conversationId,
  }) : super.internal();

  final String conversationId;

  @override
  Override overrideWith(
    FutureOr<ConversationSummary?> Function(ConversationSummaryRef provider)
    create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ConversationSummaryProvider._internal(
        (ref) => create(ref as ConversationSummaryRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        conversationId: conversationId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<ConversationSummary?> createElement() {
    return _ConversationSummaryProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ConversationSummaryProvider &&
        other.conversationId == conversationId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, conversationId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ConversationSummaryRef
    on AutoDisposeFutureProviderRef<ConversationSummary?> {
  /// The parameter `conversationId` of this provider.
  String get conversationId;
}

class _ConversationSummaryProviderElement
    extends AutoDisposeFutureProviderElement<ConversationSummary?>
    with ConversationSummaryRef {
  _ConversationSummaryProviderElement(super.provider);

  @override
  String get conversationId =>
      (origin as ConversationSummaryProvider).conversationId;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
