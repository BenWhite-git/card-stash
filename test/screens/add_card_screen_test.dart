// ABOUTME: Widget tests for AddCardScreen manual entry mode.
// ABOUTME: Tests payment card rejection, form validation, and card saving.

import 'dart:io';

import 'package:card_stash/models/card.dart';
import 'package:card_stash/screens/add_card_screen.dart';
import 'package:card_stash/providers/notification_provider.dart';
import 'package:card_stash/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import '../helpers/stub_notification_service.dart';

import 'package:card_stash/hive_registrar.g.dart';

late Directory _tempDir;
var _boxCounter = 0;

Widget _buildTestApp(Box<LoyaltyCard> box) {
  final storageService = StorageService.fromBox(box);
  return ProviderScope(
    overrides: [
      storageServiceProvider.overrideWithValue(storageService),
      notificationServiceProvider.overrideWithValue(StubNotificationService()),
    ],
    child: MaterialApp(
      home: Navigator(
        onGenerateRoute: (settings) => MaterialPageRoute(
          builder: (context) => const AddCardScreen(initialScanMode: false),
        ),
      ),
    ),
  );
}

void main() {
  late Box<LoyaltyCard> box;

  setUpAll(() async {
    _tempDir = await Directory.systemTemp.createTemp('add_card_test_');
    Hive.init(_tempDir.path);
    Hive.registerAdapters();
  });

  setUp(() async {
    _boxCounter++;
    box = await Hive.openBox<LoyaltyCard>('test_add_$_boxCounter');
  });

  tearDown(() async {
    await box.deleteFromDisk();
  });

  tearDownAll(() async {
    await Hive.close();
    if (_tempDir.existsSync()) {
      _tempDir.deleteSync(recursive: true);
    }
  });

  group('AddCardScreen', () {
    testWidgets('manual mode shows all form fields', (tester) async {
      await tester.pumpWidget(_buildTestApp(box));
      await tester.pumpAndSettle();

      expect(find.text('Card name'), findsOneWidget);
      expect(find.text('Card number'), findsOneWidget);
      expect(find.text('Barcode type'), findsOneWidget);
      expect(find.text('Colour'), findsOneWidget);
      expect(find.text('Scan'), findsOneWidget);
    });

    testWidgets('shows payment card rejection for Visa number', (tester) async {
      await tester.pumpWidget(_buildTestApp(box));
      await tester.pumpAndSettle();

      final numberField = find.byType(TextField).at(1);
      await tester.enterText(numberField, '4539578763621486');
      await tester.pumpAndSettle();

      expect(
        find.textContaining('This looks like a payment card'),
        findsOneWidget,
      );
    });

    testWidgets('shows payment card rejection for Mastercard', (tester) async {
      await tester.pumpWidget(_buildTestApp(box));
      await tester.pumpAndSettle();

      final numberField = find.byType(TextField).at(1);
      await tester.enterText(numberField, '5425233430109903');
      await tester.pumpAndSettle();

      expect(
        find.textContaining('This looks like a payment card'),
        findsOneWidget,
      );
    });

    testWidgets('shows payment card rejection for Amex', (tester) async {
      await tester.pumpWidget(_buildTestApp(box));
      await tester.pumpAndSettle();

      final numberField = find.byType(TextField).at(1);
      await tester.enterText(numberField, '374245455400126');
      await tester.pumpAndSettle();

      expect(
        find.textContaining('This looks like a payment card'),
        findsOneWidget,
      );
    });

    testWidgets('no rejection for loyalty card number', (tester) async {
      await tester.pumpWidget(_buildTestApp(box));
      await tester.pumpAndSettle();

      final numberField = find.byType(TextField).at(1);
      await tester.enterText(numberField, '1234567890');
      await tester.pumpAndSettle();

      expect(
        find.textContaining('This looks like a payment card'),
        findsNothing,
      );
    });

    testWidgets('save button disabled with empty fields', (tester) async {
      await tester.pumpWidget(_buildTestApp(box));
      await tester.pumpAndSettle();

      final saveButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Save card'),
      );
      expect(saveButton.onPressed, isNull);
    });

    testWidgets('save button disabled when payment card detected', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTestApp(box));
      await tester.pumpAndSettle();

      final nameField = find.byType(TextField).at(0);
      await tester.enterText(nameField, 'Test Card');

      final numberField = find.byType(TextField).at(1);
      await tester.enterText(numberField, '4539578763621486');
      await tester.pumpAndSettle();

      final saveButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Save card'),
      );
      expect(saveButton.onPressed, isNull);
    });

    testWidgets('saves card on valid entry', (tester) async {
      await tester.pumpWidget(_buildTestApp(box));
      await tester.pumpAndSettle();

      final nameField = find.byType(TextField).at(0);
      await tester.enterText(nameField, 'Tesco Clubcard');

      final numberField = find.byType(TextField).at(1);
      await tester.enterText(numberField, '1234567890');
      await tester.pumpAndSettle();

      final saveButton = find.widgetWithText(ElevatedButton, 'Save card');
      await tester.ensureVisible(saveButton);
      await tester.pumpAndSettle();

      await tester.runAsync(() async {
        await tester.tap(saveButton);
        // Allow the async _saveCard to complete.
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();

      expect(box.values.length, 1);
      expect(box.values.first.name, 'Tesco Clubcard');
      expect(box.values.first.cardNumber, '1234567890');
    });

    testWidgets('barcode type chips are displayed', (tester) async {
      await tester.pumpWidget(_buildTestApp(box));
      await tester.pumpAndSettle();

      expect(find.text('QR Code'), findsOneWidget);
      expect(find.text('Code 128'), findsOneWidget);
      expect(find.text('EAN-13'), findsOneWidget);
      expect(find.text('Display Only'), findsOneWidget);
    });

    testWidgets('selecting barcode type chip persists to saved card', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTestApp(box));
      await tester.pumpAndSettle();

      await tester.tap(find.text('QR Code'));
      await tester.pumpAndSettle();

      final nameField = find.byType(TextField).at(0);
      await tester.enterText(nameField, 'QR Card');
      final numberField = find.byType(TextField).at(1);
      await tester.enterText(numberField, 'ABC123');
      await tester.pumpAndSettle();

      final saveButton = find.widgetWithText(ElevatedButton, 'Save card');
      await tester.ensureVisible(saveButton);
      await tester.pumpAndSettle();

      await tester.runAsync(() async {
        await tester.tap(saveButton);
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();

      expect(box.values.first.barcodeType, BarcodeType.qrCode);
    });

    testWidgets('saved card has default code128 barcode type', (tester) async {
      await tester.pumpWidget(_buildTestApp(box));
      await tester.pumpAndSettle();

      final nameField = find.byType(TextField).at(0);
      await tester.enterText(nameField, 'Default Card');
      final numberField = find.byType(TextField).at(1);
      await tester.enterText(numberField, '9876543210');
      await tester.pumpAndSettle();

      final saveButton = find.widgetWithText(ElevatedButton, 'Save card');
      await tester.ensureVisible(saveButton);
      await tester.pumpAndSettle();

      await tester.runAsync(() async {
        await tester.tap(saveButton);
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pumpAndSettle();

      expect(box.values.first.barcodeType, BarcodeType.code128);
    });

    testWidgets('rejection clears when card number is changed to valid', (
      tester,
    ) async {
      await tester.pumpWidget(_buildTestApp(box));
      await tester.pumpAndSettle();

      final numberField = find.byType(TextField).at(1);
      await tester.enterText(numberField, '4539578763621486');
      await tester.pumpAndSettle();

      expect(
        find.textContaining('This looks like a payment card'),
        findsOneWidget,
      );

      await tester.enterText(numberField, '1234567890');
      await tester.pumpAndSettle();

      expect(
        find.textContaining('This looks like a payment card'),
        findsNothing,
      );
    });
  });
}
