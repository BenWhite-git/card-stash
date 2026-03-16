// ABOUTME: Wrapper around mobile_scanner for barcode scanning.
// ABOUTME: Returns card number and detected BarcodeType from camera input.

import '../models/card.dart' show BarcodeType;
import '../utils/barcode_type_helper.dart';
import 'package:mobile_scanner/mobile_scanner.dart' hide BarcodeType;

class ScanResult {
  final String cardNumber;
  final BarcodeType barcodeType;

  const ScanResult({required this.cardNumber, required this.barcodeType});
}

class ScannerService {
  ScannerService._();

  static ScanResult? extractResult(BarcodeCapture capture) {
    final barcodes = capture.barcodes;
    if (barcodes.isEmpty) return null;

    final barcode = barcodes.first;
    final rawValue = barcode.rawValue;
    if (rawValue == null || rawValue.isEmpty) return null;

    final barcodeType = BarcodeTypeHelper.fromScannerFormat(barcode.format);
    return ScanResult(cardNumber: rawValue, barcodeType: barcodeType);
  }
}
