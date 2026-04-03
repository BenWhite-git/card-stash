// ABOUTME: Extracts card number and barcode type from ML Kit barcode results.
// ABOUTME: Returns ScanResult from detected barcodes for use in camera and gallery flows.

import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart'
    hide BarcodeType;

import '../models/card.dart' show BarcodeType;
import '../utils/barcode_type_helper.dart';

class ScanResult {
  final String cardNumber;
  final BarcodeType barcodeType;

  const ScanResult({required this.cardNumber, required this.barcodeType});
}

class ScannerService {
  ScannerService._();

  static ScanResult? extractResult(List<Barcode> barcodes) {
    if (barcodes.isEmpty) return null;

    final barcode = barcodes.first;
    final rawValue = barcode.rawValue;
    if (rawValue == null || rawValue.isEmpty) return null;

    final barcodeType = BarcodeTypeHelper.fromScannerFormat(barcode.format);
    return ScanResult(cardNumber: rawValue, barcodeType: barcodeType);
  }
}
