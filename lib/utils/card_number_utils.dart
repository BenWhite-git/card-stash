// ABOUTME: Utility for normalising card numbers before comparison.
// ABOUTME: Strips whitespace and hyphens so formatting differences are ignored.

/// Normalise a card number by stripping whitespace and hyphens.
String normaliseCardNumber(String number) {
  return number.replaceAll(RegExp(r'[\s\-]'), '');
}
