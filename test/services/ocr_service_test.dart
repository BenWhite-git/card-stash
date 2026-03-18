// ABOUTME: Unit tests for OcrService.parseText() text extraction heuristics.
// ABOUTME: Tests card number, expiry date, and issuer hint parsing from raw OCR text.

import 'package:flutter_test/flutter_test.dart';
import 'package:card_stash/services/ocr_service.dart';

void main() {
  group('OcrService.parseText', () {
    group('card number extraction', () {
      test('extracts number from spaced digit sequence', () {
        final result = OcrService.parseText('1234 5678 9012 3456');
        expect(result, isNotNull);
        expect(result!.cardNumber, '1234567890123456');
      });

      test('extracts number with Card: prefix', () {
        final result = OcrService.parseText('Card: 123456789012');
        expect(result, isNotNull);
        expect(result!.cardNumber, '123456789012');
      });

      test('picks longest sequence when multiple present', () {
        final result = OcrService.parseText(
          'ID 12345678\nCard 1234567890123456',
        );
        expect(result, isNotNull);
        expect(result!.cardNumber, '1234567890123456');
      });

      test('ignores sequences shorter than 8 digits', () {
        final result = OcrService.parseText('Code 1234567');
        expect(result, isNull);
      });

      test('returns null cardNumber when no digit sequences found', () {
        final result = OcrService.parseText('No numbers here');
        expect(result, isNotNull);
        expect(result!.cardNumber, isNull);
      });

      test('strips hyphens from number', () {
        final result = OcrService.parseText('1234-5678-9012-3456');
        expect(result, isNotNull);
        expect(result!.cardNumber, '1234567890123456');
      });
    });

    group('expiry date extraction', () {
      test('parses EXP MM/YY', () {
        final result = OcrService.parseText('12345678\nEXP 12/25');
        expect(result, isNotNull);
        expect(result!.expiryDate, DateTime(2025, 12, 1));
      });

      test('parses VALID THRU MM/YYYY', () {
        final result = OcrService.parseText('12345678\nVALID THRU 03/2027');
        expect(result, isNotNull);
        expect(result!.expiryDate, DateTime(2027, 3, 1));
      });

      test('parses standalone MM/YY', () {
        final result = OcrService.parseText('12345678\n12/25');
        expect(result, isNotNull);
        expect(result!.expiryDate, DateTime(2025, 12, 1));
      });

      test('returns null expiry when no date pattern found', () {
        final result = OcrService.parseText('12345678');
        expect(result, isNotNull);
        expect(result!.expiryDate, isNull);
      });

      test('ignores invalid month 13', () {
        final result = OcrService.parseText('12345678\nEXP 13/25');
        expect(result, isNotNull);
        expect(result!.expiryDate, isNull);
      });

      test('ignores month 00', () {
        final result = OcrService.parseText('12345678\nEXP 00/25');
        expect(result, isNotNull);
        expect(result!.expiryDate, isNull);
      });
    });

    group('issuer hint extraction', () {
      test('extracts issuer name from text block', () {
        final result = OcrService.parseText('Tesco Clubcard\n1234567890');
        expect(result, isNotNull);
        expect(result!.issuerHint, 'Tesco Clubcard');
      });

      test('filters noise words', () {
        final result = OcrService.parseText('MEMBER CARD\n1234567890');
        expect(result, isNotNull);
        expect(result!.issuerHint, isNull);
      });

      test('returns null for noise-only text', () {
        final result = OcrService.parseText('LOYALTY REWARDS\n1234567890');
        expect(result, isNotNull);
        expect(result!.issuerHint, isNull);
      });

      test('extracts name ignoring noise words in other lines', () {
        final result = OcrService.parseText(
          'Costa Coffee\nMEMBER NUMBER\n1234567890',
        );
        expect(result, isNotNull);
        expect(result!.issuerHint, 'Costa Coffee');
      });
    });

    group('edge cases', () {
      test('returns null for empty string', () {
        expect(OcrService.parseText(''), isNull);
      });

      test('returns null for whitespace only', () {
        expect(OcrService.parseText('   \n  \n  '), isNull);
      });

      test('extracts all three fields from mixed content', () {
        final result = OcrService.parseText(
          'Boots Advantage\nCard Number\n6341 2345 6789 0123\nEXP 06/26',
        );
        expect(result, isNotNull);
        expect(result!.cardNumber, '6341234567890123');
        expect(result.expiryDate, DateTime(2026, 6, 1));
        expect(result.issuerHint, 'Boots Advantage');
      });
    });
  });
}
