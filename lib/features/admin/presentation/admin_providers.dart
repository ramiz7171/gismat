import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/presentation/session_providers.dart';
import '../../profile/domain/profile.dart';
import '../data/admin_repository.dart';

part 'admin_providers.g.dart';

@riverpod
AdminRepository adminRepository(Ref ref) =>
    AdminRepository(ref.watch(supabaseClientProvider));

/// Open reports (newest first).
@riverpod
Future<List<Map<String, dynamic>>> adminReports(Ref ref) =>
    ref.watch(adminRepositoryProvider).fetchReports();

/// Profiles with a pending verification selfie.
@riverpod
Future<List<Map<String, dynamic>>> adminVerifications(Ref ref) =>
    ref.watch(adminRepositoryProvider).fetchPendingVerifications();

/// Headline counters for the Stats tab.
@riverpod
Future<Map<String, int>> adminStats(Ref ref) =>
    ref.watch(adminRepositoryProvider).fetchStats();

/// Debounced user search (family by query string).
@riverpod
Future<List<Profile>> adminUserSearch(Ref ref, String query) =>
    ref.watch(adminRepositoryProvider).searchUsers(query);
