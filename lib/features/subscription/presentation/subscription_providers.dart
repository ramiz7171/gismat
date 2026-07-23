import 'package:flutter_riverpod/flutter_riverpod.dart' show Ref;
import 'package:riverpod_annotation/riverpod_annotation.dart';

import '../../auth/presentation/session_providers.dart';
import '../data/subscription_repository.dart';

part 'subscription_providers.g.dart';

@riverpod
SubscriptionRepository subscriptionRepository(Ref ref) =>
    SubscriptionRepository(ref.watch(supabaseClientProvider));

/// The caller's `subscriptions` row (null until Stripe creates one).
@riverpod
Future<Map<String, dynamic>?> mySubscription(Ref ref) =>
    ref.watch(subscriptionRepositoryProvider).fetchMySubscription();
