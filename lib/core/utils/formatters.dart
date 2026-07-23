/// Formatting helpers (unit-tested).
abstract final class Formatters {
  /// Bucketed distance for privacy: never shows anything finer than 0.1 km.
  /// Input is the server-side value which is already rounded to 100 m.
  static String distanceKm(double meters) {
    final km = meters / 1000;
    if (km < 0.1) return '0.1';
    if (km < 10) return km.toStringAsFixed(1);
    return km.round().toString();
  }

  /// mm:ss for voice message durations.
  static String duration(Duration d) {
    final m = d.inMinutes.remainder(60).toString();
    final s = d.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$m:$s';
  }

  /// "Aygün Məmmədova, 26" card overlay.
  static String nameAge(String first, String last, int age) =>
      '$first $last, $age';
}
