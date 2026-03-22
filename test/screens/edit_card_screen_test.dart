// ABOUTME: Widget tests for EditCardScreen.
// ABOUTME: Tests form pre-population, field editing, save persistence, and delete.

import 'dart:io';

import 'package:card_stash/models/card.dart';
import 'package:card_stash/screens/edit_card_screen.dart';
import 'package:card_stash/providers/notification_provider.dart';
import 'package:card_stash/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import 'package:card_stash/hive_registrar.g.dart';

import '../helpers/stub_notification_service.dart';

late Directory _tempDir;
var _boxCounter = 0;

LoyaltyCard _makeCard({
  String id = 'card-1',
  String name = 'Tesco Clubcard',
  String cardNumber = '1234567890',
  BarcodeType barcodeType = BarcodeType.code128,
  int colourValue = 0xFF3B82F6,
  String? notes,
  DateTime? expiryDate,
  String? logoPath,
  int usageCount = 0,
  DateTime? lastUsed,
  bool isFavourite = false,
}) {
  return LoyaltyCard(
    id: id,
    name: name,
    cardNumber: cardNumber,
    barcodeType: barcodeType,
    colourValue: colourValue,
    createdAt: DateTime(2026, 1, 1),
    notes: notes,
    expiryDate: expiryDate,
    logoPath: logoPath,
    usageCount: usageCount,
    lastUsed: lastUsed,
    isFavourite: isFavourite,
  );
}

void main() {
  late Box<LoyaltyCard> box;

  setUpAll(() async {
    _tempDir = await Directory.systemTemp.createTemp('edit_card_test_');
    Hive.init(_tempDir.path);
    Hive.registerAdapters();
  });

  setUp(() async {
    _boxCounter++;
    box = await Hive.openBox<LoyaltyCard>('test_edit_$_boxCounter');
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

  Future<void> pumpEditScreen(
    WidgetTester tester, {
    required LoyaltyCard card,
  }) async {
    // Use a tall surface so all form fields are visible without scrolling.
    tester.view.physicalSize = const Size(800, 1600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(() => tester.view.resetPhysicalSize());
    addTearDown(() => tester.view.resetDevicePixelRatio());

    await tester.runAsync(() async {
      await box.put(card.id, card);
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(StorageService.fromBox(box)),
          notificationServiceProvider.overrideWithValue(
            StubNotificationService(),
          ),
        ],
        child: MaterialApp(
          home: Navigator(
            onGenerateRoute: (settings) => MaterialPageRoute(
              builder: (context) => EditCardScreen(cardId: card.id),
            ),
          ),
        ),
      ),
    );
  }

  group('EditCardScreen', () {
    testWidgets('shows all form fields', (tester) async {
      await pumpEditScreen(tester, card: _makeCard());

      expect(find.text('Edit Card'), findsOneWidget);
      expect(find.text('Card name'), findsOneWidget);
      expect(find.text('Card number'), findsOneWidget);
      expect(find.text('Barcode type'), findsOneWidget);
      expect(find.text('Colour'), findsOneWidget);
      expect(find.text('Logo (optional)'), findsOneWidget);
      expect(find.text('Expiry date (optional)'), findsOneWidget);
      expect(find.text('Notes (optional)'), findsOneWidget);
      expect(find.text('Save changes'), findsOneWidget);
      expect(find.text('Delete card'), findsOneWidget);
    });

    testWidgets('pre-populates name from existing card', (tester) async {
      await pumpEditScreen(tester, card: _makeCard(name: 'Tesco Clubcard'));

      expect(find.text('Tesco Clubcard'), findsOneWidget);
    });

    testWidgets('pre-populates notes from existing card', (tester) async {
      await pumpEditScreen(tester, card: _makeCard(notes: 'My notes'));

      expect(find.text('My notes'), findsOneWidget);
    });

    testWidgets('card number is editable', (tester) async {
      await pumpEditScreen(tester, card: _makeCard(cardNumber: '9876543210'));

      expect(find.text('9876543210'), findsOneWidget);

      // Card number should be in an editable TextField.
      final textFields = tester.widgetList<TextField>(find.byType(TextField));
      final hasCardNumber = textFields.any(
        (f) => f.controller?.text == '9876543210',
      );
      expect(hasCardNumber, isTrue);
    });

    testWidgets('saves updated card number to Hive', (tester) async {
      await pumpEditScreen(tester, card: _makeCard(cardNumber: '1234567890'));

      // Card number is the second TextField (after name).
      final numberField = find.byType(TextField).at(1);
      await tester.enterText(numberField, '0000011111');
      await tester.pump();

      final saveButton = find.widgetWithText(ElevatedButton, 'Save changes');
      await tester.ensureVisible(saveButton);
      await tester.pump();

      await tester.runAsync(() async {
        await tester.tap(saveButton);
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();

      final saved = box.get('card-1')!;
      expect(saved.cardNumber, '0000011111');
    });

    testWidgets('save disabled when card number is empty', (tester) async {
      await pumpEditScreen(tester, card: _makeCard());

      // Clear the card number field (second TextField).
      final numberField = find.byType(TextField).at(1);
      await tester.enterText(numberField, '');
      await tester.pump();

      final saveButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Save changes'),
      );
      expect(saveButton.onPressed, isNull);
    });

    testWidgets('save button disabled when name is empty', (tester) async {
      await pumpEditScreen(tester, card: _makeCard());

      // Clear the name field.
      final nameField = find.byType(TextField).first;
      await tester.enterText(nameField, '');
      await tester.pump();

      final saveButton = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Save changes'),
      );
      expect(saveButton.onPressed, isNull);
    });

    testWidgets('saves updated name to Hive', (tester) async {
      await pumpEditScreen(tester, card: _makeCard(name: 'Old Name'));

      final nameField = find.byType(TextField).first;
      await tester.enterText(nameField, 'New Name');
      await tester.pump();

      final saveButton = find.widgetWithText(ElevatedButton, 'Save changes');
      await tester.ensureVisible(saveButton);
      await tester.pump();

      await tester.runAsync(() async {
        await tester.tap(saveButton);
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();

      final saved = box.get('card-1')!;
      expect(saved.name, 'New Name');
    });

    testWidgets('saves updated notes to Hive', (tester) async {
      await pumpEditScreen(tester, card: _makeCard());

      // Notes is the third TextField (after name and card number).
      final notesField = find.byType(TextField).at(2);
      await tester.enterText(notesField, 'Updated notes');
      await tester.pump();

      final saveButton = find.widgetWithText(ElevatedButton, 'Save changes');
      await tester.ensureVisible(saveButton);
      await tester.pump();

      await tester.runAsync(() async {
        await tester.tap(saveButton);
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();

      final saved = box.get('card-1')!;
      expect(saved.notes, 'Updated notes');
    });

    testWidgets('saves changed barcode type', (tester) async {
      await pumpEditScreen(
        tester,
        card: _makeCard(barcodeType: BarcodeType.code128),
      );

      await tester.tap(find.text('QR Code'));
      await tester.pump();

      final saveButton = find.widgetWithText(ElevatedButton, 'Save changes');
      await tester.ensureVisible(saveButton);
      await tester.pump();

      await tester.runAsync(() async {
        await tester.tap(saveButton);
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();

      final saved = box.get('card-1')!;
      expect(saved.barcodeType, BarcodeType.qrCode);
    });

    testWidgets('preserves immutable fields on save', (tester) async {
      await pumpEditScreen(
        tester,
        card: _makeCard(
          cardNumber: 'LOYALTY123',
          usageCount: 5,
          lastUsed: DateTime(2026, 3, 1),
          isFavourite: true,
        ),
      );

      final saveButton = find.widgetWithText(ElevatedButton, 'Save changes');

      await tester.runAsync(() async {
        await tester.tap(saveButton);
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();

      final saved = box.get('card-1')!;
      expect(saved.cardNumber, 'LOYALTY123');
      expect(saved.usageCount, 5);
      expect(saved.lastUsed, DateTime(2026, 3, 1));
      expect(saved.isFavourite, true);
      expect(saved.createdAt, DateTime(2026, 1, 1));
    });

    testWidgets('shows card not found for invalid ID', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storageServiceProvider.overrideWithValue(
              StorageService.fromBox(box),
            ),
            notificationServiceProvider.overrideWithValue(
              StubNotificationService(),
            ),
          ],
          child: MaterialApp(
            home: Navigator(
              onGenerateRoute: (settings) => MaterialPageRoute(
                builder: (context) =>
                    const EditCardScreen(cardId: 'nonexistent'),
              ),
            ),
          ),
        ),
      );

      expect(find.text('Card not found.'), findsOneWidget);
    });

    testWidgets('shows delete confirmation dialog', (tester) async {
      await pumpEditScreen(tester, card: _makeCard(name: 'My Card'));

      await tester.tap(find.widgetWithText(OutlinedButton, 'Delete card'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Delete card?'), findsOneWidget);
      expect(
        find.textContaining('Are you sure you want to delete "My Card"'),
        findsOneWidget,
      );
      expect(find.text('Cancel'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('cancel in delete dialog does not delete', (tester) async {
      await pumpEditScreen(tester, card: _makeCard());

      await tester.tap(find.widgetWithText(OutlinedButton, 'Delete card'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('Cancel'));
      await tester.pump();

      expect(box.containsKey('card-1'), isTrue);
    });

    testWidgets('barcode type chips are displayed and pre-selected', (
      tester,
    ) async {
      await pumpEditScreen(
        tester,
        card: _makeCard(barcodeType: BarcodeType.ean13),
      );

      expect(find.text('QR Code'), findsOneWidget);
      expect(find.text('Code 128'), findsOneWidget);
      expect(find.text('EAN-13'), findsOneWidget);
      expect(find.text('Display Only'), findsOneWidget);

      // EAN-13 chip should be selected.
      final ean13Chip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'EAN-13'),
      );
      expect(ean13Chip.selected, isTrue);
    });

    testWidgets('clears notes to null when text emptied', (tester) async {
      await pumpEditScreen(tester, card: _makeCard(notes: 'Old notes'));

      // Notes is the third TextField (after name and card number).
      final notesField = find.byType(TextField).at(2);
      await tester.enterText(notesField, '');
      await tester.pump();

      final saveButton = find.widgetWithText(ElevatedButton, 'Save changes');
      await tester.ensureVisible(saveButton);
      await tester.pump();

      await tester.runAsync(() async {
        await tester.tap(saveButton);
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();

      final saved = box.get('card-1')!;
      expect(saved.notes, isNull);
    });

    testWidgets(
      'shows duplicate warning when changing number to match another card',
      (tester) async {
        // Add a second card to the box.
        await tester.runAsync(() async {
          await box.put(
            'card-2',
            LoyaltyCard(
              id: 'card-2',
              name: 'Boots Card',
              cardNumber: '9999988888',
              barcodeType: BarcodeType.code128,
              colourValue: 0xFF3B82F6,
              createdAt: DateTime(2026, 1, 1),
            ),
          );
        });

        await pumpEditScreen(tester, card: _makeCard(cardNumber: '1234567890'));

        // Change card number to match the other card.
        final numberField = find.byType(TextField).at(1);
        await tester.enterText(numberField, '9999988888');
        await tester.pump();

        final saveButton = find.widgetWithText(ElevatedButton, 'Save changes');
        await tester.ensureVisible(saveButton);
        await tester.pump();

        await tester.tap(saveButton);
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 300));

        expect(find.text('Duplicate card number'), findsOneWidget);
        expect(find.textContaining('Boots Card'), findsOneWidget);
      },
    );

    testWidgets('no duplicate warning when keeping own card number', (
      tester,
    ) async {
      await pumpEditScreen(tester, card: _makeCard(cardNumber: '1234567890'));

      // Don't change the card number - just change the name.
      final nameField = find.byType(TextField).at(0);
      await tester.enterText(nameField, 'Updated Name');
      await tester.pump();

      final saveButton = find.widgetWithText(ElevatedButton, 'Save changes');
      await tester.ensureVisible(saveButton);
      await tester.pump();

      await tester.runAsync(() async {
        await tester.tap(saveButton);
        await Future<void>.delayed(const Duration(milliseconds: 100));
      });
      await tester.pump();

      // Should save without dialog since number didn't change.
      expect(find.text('Duplicate card number'), findsNothing);
      final saved = box.get('card-1')!;
      expect(saved.name, 'Updated Name');
    });
  });
}
