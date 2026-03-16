// ABOUTME: Payment card BIN (Bank Identification Number) range detector.
// ABOUTME: Matches Visa, Mastercard, Amex, Maestro, Discover prefixes.

enum CardScheme { visa, mastercard, amex, maestro, discover }

class BinDetector {
  BinDetector._();

  static CardScheme? detect(String number) {
    final digits = number.replaceAll(RegExp(r'[\s\-]'), '');
    if (digits.length < 4) return null;

    // Amex: 34, 37
    if (digits.startsWith('34') || digits.startsWith('37')) {
      return CardScheme.amex;
    }

    // Visa: starts with 4
    if (digits.startsWith('4')) {
      return CardScheme.visa;
    }

    // Mastercard: 51-55 or 2221-2720
    final first2 = int.tryParse(digits.substring(0, 2)) ?? 0;
    if (first2 >= 51 && first2 <= 55) {
      return CardScheme.mastercard;
    }
    if (digits.length >= 4) {
      final first4 = int.tryParse(digits.substring(0, 4)) ?? 0;
      if (first4 >= 2221 && first4 <= 2720) {
        return CardScheme.mastercard;
      }
    }

    // Maestro: 6304, 6759, 6761
    if (digits.startsWith('6304') ||
        digits.startsWith('6759') ||
        digits.startsWith('6761')) {
      return CardScheme.maestro;
    }

    // Discover: 6011, 65
    if (digits.startsWith('6011') || digits.startsWith('65')) {
      return CardScheme.discover;
    }

    return null;
  }

  static bool isPaymentCard(String number) => detect(number) != null;
}
