import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../core/error/app_exception.dart';

/// Read-only access to the caller's subscription row plus Stripe session
/// creation via edge functions. Clients can NEVER write their own tier —
/// all writes happen in the `stripe-webhook` edge function with service_role.
class SubscriptionRepository {
  SubscriptionRepository(this._client);

  final SupabaseClient _client;

  String get _uid => _client.auth.currentUser!.id;

  /// The caller's `subscriptions` row, or null if none exists yet.
  Future<Map<String, dynamic>?> fetchMySubscription() async {
    try {
      final row = await _client
          .from('subscriptions')
          .select()
          .eq('user_id', _uid)
          .maybeSingle();
      return row;
    } catch (e) {
      throw mapError(e);
    }
  }

  /// Creates a Stripe Checkout session for `tier` ('pro' | 'max') and
  /// returns the hosted checkout URL.
  Future<String> createCheckoutSession(String tier) async {
    try {
      final response = await _client.functions.invoke(
        'create-checkout-session',
        body: {'tier': tier},
      );
      return (response.data as Map)['url'] as String;
    } catch (e) {
      throw mapError(e);
    }
  }

  /// Creates a Stripe billing-portal session and returns its URL.
  Future<String> createPortalSession() async {
    try {
      final response = await _client.functions.invoke('create-portal-session');
      return (response.data as Map)['url'] as String;
    } catch (e) {
      throw mapError(e);
    }
  }
}
