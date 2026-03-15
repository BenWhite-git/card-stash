// ABOUTME: Tests for BarcodeView widget barcode rendering.
// ABOUTME: Verifies correct barcode type mapping, card number display, and displayOnly mode.

import 'package:barcode_widget/barcode_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:card_stash/models/card.dart' as model;
import 'package:card_stash/widgets/barcode_view.dart';

void main() {
  Widget buildTestWidget(BarcodeView barcodeView) {
    return MaterialApp(
      home: Scaffold(body: Center(child: barcodeView)),
    );
  }

  group('barcode rendering', () {
    testWidgets('renders BarcodeWidget for code128 type', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const BarcodeView(
            cardNumber: 'ABC123',
            barcodeType: model.BarcodeType.code128,
          ),
        ),
      );

      expect(find.byType(BarcodeWidget), findsOneWidget);
    });

    testWidgets('renders BarcodeWidget for qrCode type', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const BarcodeView(
            cardNumber: '123456',
            barcodeType: model.BarcodeType.qrCode,
          ),
        ),
      );

      expect(find.byType(BarcodeWidget), findsOneWidget);
    });

    testWidgets('renders BarcodeWidget for ean13 type', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const BarcodeView(
            cardNumber: '5901234123457',
            barcodeType: model.BarcodeType.ean13,
          ),
        ),
      );

      expect(find.byType(BarcodeWidget), findsOneWidget);
    });

    testWidgets('renders BarcodeWidget for ean8 type', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const BarcodeView(
            cardNumber: '12345670',
            barcodeType: model.BarcodeType.ean8,
          ),
        ),
      );

      expect(find.byType(BarcodeWidget), findsOneWidget);
    });

    testWidgets('renders BarcodeWidget for code39 type', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const BarcodeView(
            cardNumber: 'HELLO',
            barcodeType: model.BarcodeType.code39,
          ),
        ),
      );

      expect(find.byType(BarcodeWidget), findsOneWidget);
    });

    testWidgets('renders BarcodeWidget for pdf417 type', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const BarcodeView(
            cardNumber: '123456',
            barcodeType: model.BarcodeType.pdf417,
          ),
        ),
      );

      expect(find.byType(BarcodeWidget), findsOneWidget);
    });

    testWidgets('renders BarcodeWidget for aztec type', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const BarcodeView(
            cardNumber: '123456',
            barcodeType: model.BarcodeType.aztec,
          ),
        ),
      );

      expect(find.byType(BarcodeWidget), findsOneWidget);
    });

    testWidgets('renders BarcodeWidget for dataMatrix type', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const BarcodeView(
            cardNumber: '123456',
            barcodeType: model.BarcodeType.dataMatrix,
          ),
        ),
      );

      expect(find.byType(BarcodeWidget), findsOneWidget);
    });
  });

  group('displayOnly mode', () {
    testWidgets('does not render BarcodeWidget', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const BarcodeView(
            cardNumber: '123456789',
            barcodeType: model.BarcodeType.displayOnly,
          ),
        ),
      );

      expect(find.byType(BarcodeWidget), findsNothing);
    });

    testWidgets('shows card number text', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const BarcodeView(
            cardNumber: '123456789',
            barcodeType: model.BarcodeType.displayOnly,
          ),
        ),
      );

      expect(find.text('123456789'), findsWidgets);
    });
  });

  group('card number fallback text', () {
    testWidgets('always shows card number below barcode', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const BarcodeView(
            cardNumber: 'ABC123',
            barcodeType: model.BarcodeType.code128,
          ),
        ),
      );

      // Card number should appear as fallback text.
      expect(find.text('ABC123'), findsWidgets);
    });
  });

  group('accessibility', () {
    testWidgets('has semantics label with card number', (tester) async {
      await tester.pumpWidget(
        buildTestWidget(
          const BarcodeView(
            cardNumber: 'ABC123',
            barcodeType: model.BarcodeType.code128,
          ),
        ),
      );

      final semantics = tester.getSemantics(find.byType(BarcodeView));
      expect(semantics.label, contains('ABC123'));
    });
  });
}
