// ABOUTME: Unit tests for BarcodeTypeHelper.
// ABOUTME: Verifies mapping from ML Kit BarcodeFormat to BarcodeType enum.

import 'package:card_stash/models/card.dart' show BarcodeType;
import 'package:card_stash/utils/barcode_type_helper.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart'
    hide BarcodeType;

void main() {
  group('BarcodeTypeHelper', () {
    test('maps QR code format', () {
      expect(
        BarcodeTypeHelper.fromScannerFormat(BarcodeFormat.qrCode),
        BarcodeType.qrCode,
      );
    });

    test('maps Code 128 format', () {
      expect(
        BarcodeTypeHelper.fromScannerFormat(BarcodeFormat.code128),
        BarcodeType.code128,
      );
    });

    test('maps Code 39 format', () {
      expect(
        BarcodeTypeHelper.fromScannerFormat(BarcodeFormat.code39),
        BarcodeType.code39,
      );
    });

    test('maps EAN-13 format', () {
      expect(
        BarcodeTypeHelper.fromScannerFormat(BarcodeFormat.ean13),
        BarcodeType.ean13,
      );
    });

    test('maps EAN-8 format', () {
      expect(
        BarcodeTypeHelper.fromScannerFormat(BarcodeFormat.ean8),
        BarcodeType.ean8,
      );
    });

    test('maps Data Matrix format', () {
      expect(
        BarcodeTypeHelper.fromScannerFormat(BarcodeFormat.dataMatrix),
        BarcodeType.dataMatrix,
      );
    });

    test('maps PDF417 format', () {
      expect(
        BarcodeTypeHelper.fromScannerFormat(BarcodeFormat.pdf417),
        BarcodeType.pdf417,
      );
    });

    test('maps Aztec format', () {
      expect(
        BarcodeTypeHelper.fromScannerFormat(BarcodeFormat.aztec),
        BarcodeType.aztec,
      );
    });

    test('defaults to code128 for unknown format', () {
      expect(
        BarcodeTypeHelper.fromScannerFormat(BarcodeFormat.unknown),
        BarcodeType.code128,
      );
    });

    test('defaults to code128 for UPC-A format', () {
      expect(
        BarcodeTypeHelper.fromScannerFormat(BarcodeFormat.upca),
        BarcodeType.code128,
      );
    });

    test('defaults to code128 for UPC-E format', () {
      expect(
        BarcodeTypeHelper.fromScannerFormat(BarcodeFormat.upce),
        BarcodeType.code128,
      );
    });
  });
}
