import 'package:flutter_test/flutter_test.dart';
import 'package:gismat/core/utils/formatters.dart';

void main() {
  group('Formatters.distanceKm (privacy bucketing)', () {
    test('never finer than 0.1 km', () {
      expect(Formatters.distanceKm(0), '0.1');
      expect(Formatters.distanceKm(40), '0.1');
    });

    test('one decimal under 10 km', () {
      expect(Formatters.distanceKm(1200), '1.2');
      expect(Formatters.distanceKm(9940), '9.9');
    });

    test('whole km above 10 km', () {
      expect(Formatters.distanceKm(15400), '15');
      expect(Formatters.distanceKm(99500), '100');
    });
  });

  group('Formatters.duration', () {
    test('formats mm:ss', () {
      expect(Formatters.duration(const Duration(seconds: 5)), '0:05');
      expect(Formatters.duration(const Duration(minutes: 1, seconds: 30)),
          '1:30');
      expect(Formatters.duration(const Duration(minutes: 10, seconds: 2)),
          '10:02');
    });
  });

  test('nameAge overlay format', () {
    expect(Formatters.nameAge('Aygün', 'Məmmədova', 26),
        'Aygün Məmmədova, 26');
  });
}
