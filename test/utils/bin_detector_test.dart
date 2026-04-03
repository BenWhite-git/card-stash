// ABOUTME: Unit tests for BinDetector.
// ABOUTME: Verifies detection of Visa, Mastercard, Amex, Maestro, Discover BIN ranges.

import 'package:card_stash/utils/bin_detector.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BinDetector', () {
    group('Visa', () {
      test('detects Visa starting with 4', () {
        expect(BinDetector.detect('4539578763621486'), CardScheme.visa);
      });

      test('detects Visa 13-digit', () {
        expect(BinDetector.detect('4222222222225'), CardScheme.visa);
      });
    });

    group('Mastercard', () {
      test('detects Mastercard starting with 51', () {
        expect(BinDetector.detect('5100000000000008'), CardScheme.mastercard);
      });

      test('detects Mastercard starting with 55', () {
        expect(BinDetector.detect('5500000000000004'), CardScheme.mastercard);
      });

      test('detects Mastercard starting with 2221', () {
        expect(BinDetector.detect('2221000000000009'), CardScheme.mastercard);
      });

      test('detects Mastercard starting with 2720', () {
        expect(BinDetector.detect('2720000000000005'), CardScheme.mastercard);
      });

      test('does not match 2220 (below range)', () {
        expect(
          BinDetector.detect('2220000000000000'),
          isNot(CardScheme.mastercard),
        );
      });

      test('does not match 2721 (above range)', () {
        expect(
          BinDetector.detect('2721000000000000'),
          isNot(CardScheme.mastercard),
        );
      });

      test('does not match 50 prefix', () {
        expect(
          BinDetector.detect('5000000000000000'),
          isNot(CardScheme.mastercard),
        );
      });

      test('does not match 56 prefix', () {
        expect(
          BinDetector.detect('5600000000000000'),
          isNot(CardScheme.mastercard),
        );
      });
    });

    group('Amex', () {
      test('detects Amex starting with 34', () {
        expect(BinDetector.detect('340000000000009'), CardScheme.amex);
      });

      test('detects Amex starting with 37', () {
        expect(BinDetector.detect('370000000000002'), CardScheme.amex);
      });

      test('does not match 35 prefix', () {
        expect(BinDetector.detect('3500000000000000'), isNot(CardScheme.amex));
      });
    });

    group('Maestro', () {
      test('detects Maestro starting with 6304', () {
        expect(BinDetector.detect('6304000000000000'), CardScheme.maestro);
      });

      test('detects Maestro starting with 6759', () {
        expect(BinDetector.detect('6759000000000000'), CardScheme.maestro);
      });

      test('detects Maestro starting with 6761', () {
        expect(BinDetector.detect('6761000000000000'), CardScheme.maestro);
      });
    });

    group('Discover', () {
      test('detects Discover starting with 6011', () {
        expect(BinDetector.detect('6011000000000004'), CardScheme.discover);
      });

      test('detects Discover starting with 65', () {
        expect(BinDetector.detect('6500000000000002'), CardScheme.discover);
      });
    });

    group('non-payment cards', () {
      test('returns null for loyalty card number', () {
        expect(BinDetector.detect('1234567890'), isNull);
      });

      test('returns null for short number with payment BIN prefix', () {
        // 513131615 starts with 51 (Mastercard range) and passes Luhn,
        // but at 9 digits it is a loyalty card, not a payment card.
        expect(BinDetector.detect('513131615'), isNull);
      });

      test('returns null for short number', () {
        expect(BinDetector.detect('123'), isNull);
      });

      test('returns null for empty string', () {
        expect(BinDetector.detect(''), isNull);
      });

      test('strips spaces before detection', () {
        expect(BinDetector.detect('4539 5787 6362 1486'), CardScheme.visa);
      });

      test('strips hyphens before detection', () {
        expect(BinDetector.detect('4539-5787-6362-1486'), CardScheme.visa);
      });

      test('returns null for number starting with 3 but not 34/37', () {
        expect(BinDetector.detect('3000000000000000'), isNull);
      });

      test('returns null for number starting with 1', () {
        expect(BinDetector.detect('1234567890123456'), isNull);
      });
    });

    group('isPaymentCard', () {
      test('returns true for valid payment card number', () {
        expect(BinDetector.isPaymentCard('4539578763621486'), isTrue);
      });

      test('returns false for non-payment number', () {
        expect(BinDetector.isPaymentCard('1234567890'), isFalse);
      });
    });
  });
}
