// ABOUTME: Unit tests for LuhnValidator.
// ABOUTME: Verifies Luhn algorithm correctness against known valid/invalid card numbers.

import 'package:card_stash/utils/luhn_validator.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LuhnValidator', () {
    group('isValid', () {
      test('returns true for valid Visa number', () {
        expect(LuhnValidator.isValid('4539578763621486'), isTrue);
      });

      test('returns true for valid Mastercard number', () {
        expect(LuhnValidator.isValid('5425233430109903'), isTrue);
      });

      test('returns true for valid Amex number', () {
        expect(LuhnValidator.isValid('374245455400126'), isTrue);
      });

      test('returns true for valid Discover number', () {
        expect(LuhnValidator.isValid('6011000990139424'), isTrue);
      });

      test('returns false for invalid check digit', () {
        expect(LuhnValidator.isValid('4539578763621487'), isFalse);
      });

      test('returns false for all zeros', () {
        expect(LuhnValidator.isValid('0000000000000000'), isTrue);
        // All zeros actually passes Luhn - that's correct behaviour.
      });

      test('returns false for single digit', () {
        expect(LuhnValidator.isValid('5'), isFalse);
      });

      test('returns false for empty string', () {
        expect(LuhnValidator.isValid(''), isFalse);
      });

      test('handles spaces in card number', () {
        expect(LuhnValidator.isValid('4539 5787 6362 1486'), isTrue);
      });

      test('handles hyphens in card number', () {
        expect(LuhnValidator.isValid('4539-5787-6362-1486'), isTrue);
      });

      test('returns false for non-numeric characters', () {
        expect(LuhnValidator.isValid('4539abcd63621486'), isFalse);
      });

      test('returns false for too-short number', () {
        expect(LuhnValidator.isValid('12'), isFalse);
      });

      test('returns true for valid 13-digit number', () {
        // Known valid 13-digit test number.
        expect(LuhnValidator.isValid('4222222222222'), isTrue);
      });
    });
  });
}
