/// Pure validation helpers (unit-tested in test/validators_test.dart).
abstract final class Validators {
  static final RegExp _email =
      RegExp(r"^[\w.!#$%&'*+/=?^`{|}~-]+@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)+$");

  static bool isValidEmail(String value) => _email.hasMatch(value.trim());

  static bool isValidPassword(String value) => value.length >= 8;

  static bool isAdult(DateTime dob, {DateTime? now}) {
    final today = now ?? DateTime.now();
    var age = today.year - dob.year;
    if (today.month < dob.month ||
        (today.month == dob.month && today.day < dob.day)) {
      age--;
    }
    return age >= 18;
  }

  static bool isNonEmpty(String? value) => value != null && value.trim().isNotEmpty;
}
