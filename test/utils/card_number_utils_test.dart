// ABOUTME: Tests for card number normalisation utility.
// ABOUTME: Verifies spaces, hyphens, and mixed formatting are stripped.

import 'package:card_stash/utils/card_number_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('normaliseCardNumber', () {
    test('returns plain number unchanged', () {
      expect(normaliseCardNumber('1234567890'), '1234567890');
    });

    test('strips spaces', () {
      expect(normaliseCardNumber('1234 5678 9012'), '123456789012');
    });

    test('strips hyphens', () {
      expect(normaliseCardNumber('1234-5678-9012'), '123456789012');
    });

    test('strips mixed spaces and hyphens', () {
      expect(normaliseCardNumber('1234 - 5678-9012 3456'), '1234567890123456');
    });

    test('handles empty string', () {
      expect(normaliseCardNumber(''), '');
    });

    test('strips tabs and newlines', () {
      expect(normaliseCardNumber('1234\t5678\n9012'), '123456789012');
    });
  });
}
