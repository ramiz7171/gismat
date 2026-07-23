import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../auth/presentation/session_providers.dart';
import '../data/safety_repository.dart';

part 'settings_providers.g.dart';

@Riverpod(keepAlive: true)
SafetyRepository safetyRepository(Ref ref) =>
    SafetyRepository(ref.watch(supabaseClientProvider));

const _blurKey = 'blur_explicit';
const _notificationsKey = 'notifications_enabled';

/// Whether possibly explicit images are blurred until tapped. Default: on.
@Riverpod(keepAlive: true)
class BlurExplicitImages extends _$BlurExplicitImages {
  @override
  bool build() {
    _restore();
    return true;
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getBool(_blurKey);
    if (value != null) state = value;
  }

  Future<void> set(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_blurKey, value);
  }
}

/// Local push-notification preference. Default: on.
@Riverpod(keepAlive: true)
class NotificationsEnabled extends _$NotificationsEnabled {
  @override
  bool build() {
    _restore();
    return true;
  }

  Future<void> _restore() async {
    final prefs = await SharedPreferences.getInstance();
    final value = prefs.getBool(_notificationsKey);
    if (value != null) state = value;
  }

  Future<void> set(bool value) async {
    state = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_notificationsKey, value);
  }
}

/// Blocked users joined with their profile names.
@riverpod
Future<List<Map<String, dynamic>>> blockedUsers(Ref ref) =>
    ref.watch(safetyRepositoryProvider).fetchBlockedUsers();
