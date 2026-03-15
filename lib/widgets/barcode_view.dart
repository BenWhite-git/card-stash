// ABOUTME: Barcode rendering widget using barcode_widget package.
// ABOUTME: Renders at maximum safe width preserving quiet zones.

import 'package:barcode/barcode.dart' as bc;
import 'package:barcode_widget/barcode_widget.dart' hide BarcodeType;
import 'package:flutter/material.dart';

import '../models/card.dart';

/// Maps the app's BarcodeType enum to the barcode_widget package's Barcode class.
bc.Barcode _mapBarcodeType(BarcodeType type) {
  return switch (type) {
    BarcodeType.qrCode => bc.Barcode.qrCode(),
    BarcodeType.code128 => bc.Barcode.code128(),
    BarcodeType.code39 => bc.Barcode.code39(),
    BarcodeType.ean13 => bc.Barcode.ean13(),
    BarcodeType.ean8 => bc.Barcode.ean8(),
    BarcodeType.dataMatrix => bc.Barcode.dataMatrix(),
    BarcodeType.pdf417 => bc.Barcode.pdf417(),
    BarcodeType.aztec => bc.Barcode.aztec(),
    BarcodeType.displayOnly => throw StateError(
      'displayOnly has no barcode representation',
    ),
  };
}

/// Whether the barcode type renders as a 2D matrix (square aspect ratio).
bool _is2D(BarcodeType type) {
  return type == BarcodeType.qrCode ||
      type == BarcodeType.dataMatrix ||
      type == BarcodeType.aztec;
}

/// Renders a barcode with the card number displayed below as fallback text.
///
/// For displayOnly type, shows only the card number in large text.
/// For all other types, renders the barcode at maximum safe width with
/// quiet zones preserved, plus the card number beneath.
class BarcodeView extends StatelessWidget {
  final String cardNumber;
  final BarcodeType barcodeType;

  const BarcodeView({
    super.key,
    required this.cardNumber,
    required this.barcodeType,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Barcode for card number $cardNumber',
      child: barcodeType == BarcodeType.displayOnly
          ? _buildDisplayOnly()
          : _buildBarcode(),
    );
  }

  Widget _buildDisplayOnly() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          cardNumber,
          style: const TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 28,
            fontWeight: FontWeight.w600,
            letterSpacing: 2,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildBarcode() {
    final is2D = _is2D(barcodeType);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Barcode at maximum safe width. No extra padding/margin that would
        // compress quiet zones - barcode_widget handles those internally.
        SizedBox(
          height: is2D ? 200 : 120,
          child: BarcodeWidget(
            barcode: _mapBarcodeType(barcodeType),
            data: cardNumber,
            drawText: false,
            color: Colors.black,
            backgroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 16),
        // Card number as manual fallback if scanner fails.
        Text(
          cardNumber,
          style: const TextStyle(
            fontFamily: 'JetBrains Mono',
            fontSize: 20,
            fontWeight: FontWeight.w500,
            letterSpacing: 1.5,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }
}
