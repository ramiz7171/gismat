/// Environment configuration.
///
/// Secrets are injected with `--dart-define` (see .env.example). The Supabase
/// URL and anon key are safe-to-ship public values and default to the live
/// GISMAT project so `flutter run` works out of the box.
abstract final class Env {
  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://mkfvjvclsmgowalfscsc.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'sb_publishable_wMRvGFlReNXKm8YHW7kxbw_0cqQwHa-',
  );

  /// Publishable key only — the secret key lives in Supabase Edge Function
  /// secrets and never ships in the app.
  static const String stripePublishableKey =
      String.fromEnvironment('STRIPE_PUBLISHABLE_KEY');
}

/// App-wide constants that are not tier-dependent (tier limits are
/// data-driven from the `tier_limits` table — never hardcoded).
abstract final class AppConstants {
  static const int minPhotos = 3;
  static const double defaultRadiusKm = 2;
  static const double minRadiusKm = 1;
  static const double maxRadiusKm = 100;
  static const int minAge = 18;
  static const int discoveryBatchSize = 30;
  static const Duration presenceHeartbeat = Duration(seconds: 30);
}
