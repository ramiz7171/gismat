import 'package:flutter_test/flutter_test.dart';
import 'package:gismat/core/utils/validators.dart';

void main() {
  group('Validators.isValidEmail', () {
    test('accepts normal emails', () {
      expect(Validators.isValidEmail('user@example.com'), isTrue);
      expect(Validators.isValidEmail('a.b+c@sub.domain.az'), isTrue);
      expect(Validators.isValidEmail('  padded@mail.com  '), isTrue);
    });

    test('rejects invalid emails', () {
      expect(Validators.isValidEmail(''), isFalse);
      expect(Validators.isValidEmail('nope'), isFalse);
      expect(Validators.isValidEmail('a@b'), isFalse);
      expect(Validators.isValidEmail('a @b.com'), isFalse);
      expect(Validators.isValidEmail('@b.com'), isFalse);
    });
  });

  group('Validators.isValidPassword', () {
    test('requires 8+ chars', () {
      expect(Validators.isValidPassword('1234567'), isFalse);
      expect(Validators.isValidPassword('12345678'), isTrue);
    });
  });

  group('Validators.isAdult', () {
    final now = DateTime(2026, 7, 23);

    test('exactly 18 today is adult', () {
      expect(Validators.isAdult(DateTime(2008, 7, 23), now: now), isTrue);
    });

    test('18 tomorrow is not adult', () {
      expect(Validators.isAdult(DateTime(2008, 7, 24), now: now), isFalse);
    });

    test('clearly underage rejected', () {
      expect(Validators.isAdult(DateTime(2015, 1, 1), now: now), isFalse);
    });

    test('older ages accepted', () {
      expect(Validators.isAdult(DateTime(1990, 5, 5), now: now), isTrue);
    });
  });
}
