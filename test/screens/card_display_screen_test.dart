// ABOUTME: Tests for CardDisplayScreen full-screen barcode display.
// ABOUTME: Verifies brightness lifecycle, tap dismiss, and card info display.

import 'dart:io';

import 'package:card_stash/models/card.dart';
import 'package:card_stash/screens/card_display_screen.dart';
import 'package:card_stash/services/brightness_service.dart';
import 'package:card_stash/services/storage_service.dart';
import 'package:card_stash/widgets/barcode_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import 'package:card_stash/hive_registrar.g.dart';

class FakeBrightnessControl implements ScreenBrightnessControl {
  double? applicationBrightnessValue;
  bool wasReset = false;

  @override
  Future<double> get systemBrightness async => 0.5;

  @override
  Future<double> get applicationBrightness async =>
      applicationBrightnessValue ?? 0.5;

  @override
  Future<void> setApplicationScreenBrightness(double brightness) async {
    applicationBrightnessValue = brightness;
  }

  @override
  Future<void> resetApplicationScreenBrightness() async {
    wasReset = true;
    applicationBrightnessValue = null;
  }
}

late Directory _tempDir;
var _boxCounter = 0;

LoyaltyCard _makeCard({
  String id = 'test-1',
  String name = 'Tesco Clubcard',
  String cardNumber = '1234567890',
  BarcodeType barcodeType = BarcodeType.code128,
  String? notes,
  String? issuer,
  DateTime? expiryDate,
  int usageCount = 0,
}) {
  return LoyaltyCard(
    id: id,
    name: name,
    issuer: issuer,
    cardNumber: cardNumber,
    barcodeType: barcodeType,
    colourValue: Colors.blue.toARGB32(),
    createdAt: DateTime(2026, 1, 1),
    usageCount: usageCount,
    notes: notes,
    expiryDate: expiryDate,
  );
}

void main() {
  late Box<LoyaltyCard> box;
  late FakeBrightnessControl fakeBrightness;

  setUpAll(() async {
    _tempDir = await Directory.systemTemp.createTemp('card_display_test_');
    Hive.init(_tempDir.path);
    Hive.registerAdapters();
  });

  setUp(() async {
    _boxCounter++;
    box = await Hive.openBox<LoyaltyCard>('display_test_$_boxCounter');
    fakeBrightness = FakeBrightnessControl();
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

  /// Puts a card in the box via runAsync (to avoid FakeAsync deadlock on Hive
  /// I/O) and pumps the screen.
  Future<void> pumpCardScreen(
    WidgetTester tester, {
    required LoyaltyCard card,
    required FakeBrightnessControl brightness,
  }) async {
    await tester.runAsync(() => box.put(card.id, card));
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(StorageService.fromBox(box)),
          brightnessServiceProvider.overrideWithValue(
            BrightnessService(brightnessControl: brightness),
          ),
        ],
        child: MaterialApp(home: CardDisplayScreen(cardId: card.id)),
      ),
    );
  }

  group('card info display', () {
    testWidgets('shows card name', (tester) async {
      await pumpCardScreen(
        tester,
        card: _makeCard(),
        brightness: fakeBrightness,
      );
      expect(find.text('Tesco Clubcard'), findsOneWidget);
    });

    testWidgets('shows issuer when present', (tester) async {
      await pumpCardScreen(
        tester,
        card: _makeCard(issuer: 'Tesco'),
        brightness: fakeBrightness,
      );
      expect(find.text('Tesco'), findsOneWidget);
    });

    testWidgets('shows BarcodeView', (tester) async {
      await pumpCardScreen(
        tester,
        card: _makeCard(),
        brightness: fakeBrightness,
      );
      expect(find.byType(BarcodeView), findsOneWidget);
    });

    testWidgets('shows card number', (tester) async {
      await pumpCardScreen(
        tester,
        card: _makeCard(),
        brightness: fakeBrightness,
      );
      expect(find.text('1234567890'), findsWidgets);
    });

    testWidgets('shows notes when present', (tester) async {
      await pumpCardScreen(
        tester,
        card: _makeCard(notes: 'Joint account'),
        brightness: fakeBrightness,
      );
      expect(find.text('Joint account'), findsOneWidget);
    });

    testWidgets('does not show notes section when null', (tester) async {
      await pumpCardScreen(
        tester,
        card: _makeCard(),
        brightness: fakeBrightness,
      );
      expect(find.text('Notes'), findsNothing);
    });

    testWidgets('shows expiry date when set', (tester) async {
      await pumpCardScreen(
        tester,
        card: _makeCard(expiryDate: DateTime(2027, 6, 15)),
        brightness: fakeBrightness,
      );
      expect(find.textContaining('15 Jun 2027'), findsOneWidget);
    });

    testWidgets('shows displayOnly card without barcode widget', (
      tester,
    ) async {
      await pumpCardScreen(
        tester,
        card: _makeCard(barcodeType: BarcodeType.displayOnly),
        brightness: fakeBrightness,
      );
      expect(find.byType(BarcodeView), findsOneWidget);
      expect(find.text('1234567890'), findsWidgets);
    });
  });

  group('brightness lifecycle', () {
    testWidgets('sets max brightness on open', (tester) async {
      await pumpCardScreen(
        tester,
        card: _makeCard(),
        brightness: fakeBrightness,
      );
      expect(fakeBrightness.applicationBrightnessValue, 1.0);
    });

    testWidgets('restores brightness when navigating back', (tester) async {
      final card = _makeCard();
      await tester.runAsync(() => box.put(card.id, card));

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storageServiceProvider.overrideWithValue(
              StorageService.fromBox(box),
            ),
            brightnessServiceProvider.overrideWithValue(
              BrightnessService(brightnessControl: fakeBrightness),
            ),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CardDisplayScreen(cardId: card.id),
                      ),
                    );
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();
      expect(fakeBrightness.applicationBrightnessValue, 1.0);

      Navigator.of(tester.element(find.byType(CardDisplayScreen))).pop();
      await tester.pumpAndSettle();
      expect(fakeBrightness.wasReset, isTrue);
    });
  });

  group('tap to dismiss', () {
    testWidgets('tap on screen triggers navigation back', (tester) async {
      final card = _makeCard();
      await tester.runAsync(() => box.put(card.id, card));
      var didPop = false;

      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storageServiceProvider.overrideWithValue(
              StorageService.fromBox(box),
            ),
            brightnessServiceProvider.overrideWithValue(
              BrightnessService(brightnessControl: fakeBrightness),
            ),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (context) => Scaffold(
                body: ElevatedButton(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => CardDisplayScreen(cardId: card.id),
                      ),
                    );
                    didPop = true;
                  },
                  child: const Text('Open'),
                ),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.byType(CardDisplayScreen));
      await tester.pumpAndSettle();

      expect(didPop, isTrue);
    });
  });

  group('card not found', () {
    testWidgets('shows error when card ID does not exist', (tester) async {
      // Do not put any card in the box.
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storageServiceProvider.overrideWithValue(
              StorageService.fromBox(box),
            ),
            brightnessServiceProvider.overrideWithValue(
              BrightnessService(brightnessControl: fakeBrightness),
            ),
          ],
          child: const MaterialApp(
            home: CardDisplayScreen(cardId: 'nonexistent'),
          ),
        ),
      );
      expect(find.textContaining('not found'), findsOneWidget);
    });
  });
}
