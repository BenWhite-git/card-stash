// ABOUTME: Maps ML Kit barcode formats to BarcodeType enum.
// ABOUTME: Defaults to code128 for unrecognised formats.

import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart'
    hide BarcodeType;

import '../models/card.dart' as model;

class BarcodeTypeHelper {
  BarcodeTypeHelper._();

  static const _formatMap = <BarcodeFormat, model.BarcodeType>{
    BarcodeFormat.qrCode: model.BarcodeType.qrCode,
    BarcodeFormat.code128: model.BarcodeType.code128,
    BarcodeFormat.code39: model.BarcodeType.code39,
    BarcodeFormat.ean13: model.BarcodeType.ean13,
    BarcodeFormat.ean8: model.BarcodeType.ean8,
    BarcodeFormat.dataMatrix: model.BarcodeType.dataMatrix,
    BarcodeFormat.pdf417: model.BarcodeType.pdf417,
    BarcodeFormat.aztec: model.BarcodeType.aztec,
  };

  static model.BarcodeType fromScannerFormat(BarcodeFormat format) {
    return _formatMap[format] ?? model.BarcodeType.code128;
  }
}
