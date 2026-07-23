// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'locale_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$appLocaleHash() => r'eba4bf41901c6c382d7818cb35d4aaf8a2d0aa8f';

/// Selected locale; null = follow device locale (EN fallback handled by
/// localeListResolutionCallback in app.dart).
///
/// Copied from [AppLocale].
@ProviderFor(AppLocale)
final appLocaleProvider = NotifierProvider<AppLocale, Locale?>.internal(
  AppLocale.new,
  name: r'appLocaleProvider',
  debugGetCreateSourceHash: const bool.fromEnvironment('dart.vm.product')
      ? null
      : _$appLocaleHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

typedef _$AppLocale = Notifier<Locale?>;
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
