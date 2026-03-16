// ABOUTME: Pure Dart implementation of the Luhn algorithm.
// ABOUTME: Used to detect payment card numbers for rejection.

class LuhnValidator {
  LuhnValidator._();

  static bool isValid(String number) {
    final digits = number.replaceAll(RegExp(r'[\s\-]'), '');

    if (digits.length < 8) return false;
    if (!RegExp(r'^\d+$').hasMatch(digits)) return false;

    var sum = 0;
    var alternate = false;

    for (var i = digits.length - 1; i >= 0; i--) {
      var n = int.parse(digits[i]);
      if (alternate) {
        n *= 2;
        if (n > 9) n -= 9;
      }
      sum += n;
      alternate = !alternate;
    }

    return sum % 10 == 0;
  }
}
