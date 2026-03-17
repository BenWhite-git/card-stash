// ABOUTME: Widget tests for HomeScreen.
// ABOUTME: Verifies card sorting, search, empty state, sections, and actions.

import 'dart:io';

import 'package:card_stash/hive_registrar.g.dart';
import 'package:card_stash/models/card.dart';
import 'package:card_stash/screens/home_screen.dart';
import 'package:card_stash/providers/notification_provider.dart';
import 'package:card_stash/services/storage_service.dart';
import 'package:card_stash/widgets/card_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import '../helpers/stub_notification_service.dart';

late Directory _tempDir;
var _boxCounter = 0;

LoyaltyCard _makeCard({
  String id = '1',
  String name = 'Test Card',
  String? issuer,
  int usageCount = 0,
  bool isFavourite = false,
  String? notes,
  DateTime? expiryDate,
}) {
  return LoyaltyCard(
    id: id,
    name: name,
    issuer: issuer,
    cardNumber: '1234567890',
    barcodeType: BarcodeType.code128,
    colourValue: Colors.blue.toARGB32(),
    createdAt: DateTime(2026, 1, 1),
    usageCount: usageCount,
    isFavourite: isFavourite,
    notes: notes,
    expiryDate: expiryDate,
  );
}

void main() {
  late Box<LoyaltyCard> box;

  setUpAll(() async {
    _tempDir = await Directory.systemTemp.createTemp('card_stash_home_');
    Hive.init(_tempDir.path);
    Hive.registerAdapters();
  });

  setUp(() async {
    _boxCounter++;
    box = await Hive.openBox<LoyaltyCard>('test_home_$_boxCounter');
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

  Future<void> pumpHomeScreen(
    WidgetTester tester, {
    List<LoyaltyCard> cards = const [],
  }) async {
    await tester.runAsync(() async {
      for (final card in cards) {
        await box.put(card.id, card);
      }
    });
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(StorageService.fromBox(box)),
          notificationServiceProvider.overrideWithValue(
            StubNotificationService(),
          ),
        ],
        child: const MaterialApp(home: HomeScreen()),
      ),
    );
  }

  group('HomeScreen', () {
    testWidgets('shows empty state when no cards', (tester) async {
      await pumpHomeScreen(tester);
      expect(find.text('No cards yet'), findsOneWidget);
      expect(
        find.text('Tap the + button to add your first loyalty card.'),
        findsOneWidget,
      );
    });

    testWidgets('FAB is visible', (tester) async {
      await pumpHomeScreen(tester);
      expect(find.byType(FloatingActionButton), findsOneWidget);
    });

    testWidgets('displays card names', (tester) async {
      await pumpHomeScreen(
        tester,
        cards: [
          _makeCard(id: '1', name: 'Tesco Clubcard'),
          _makeCard(id: '2', name: 'Boots Advantage'),
        ],
      );
      expect(find.text('Tesco Clubcard'), findsOneWidget);
      expect(find.text('Boots Advantage'), findsOneWidget);
    });

    testWidgets('shows Pinned section for favourites', (tester) async {
      await pumpHomeScreen(
        tester,
        cards: [
          _makeCard(id: '1', name: 'Fav Card', isFavourite: true),
          _makeCard(id: '2', name: 'Normal Card'),
        ],
      );
      expect(find.text('PINNED'), findsOneWidget);
      expect(find.text('MOST USED'), findsOneWidget);
    });

    testWidgets('hides Pinned section when no favourites', (tester) async {
      await pumpHomeScreen(
        tester,
        cards: [_makeCard(id: '1', name: 'Normal Card')],
      );
      expect(find.text('PINNED'), findsNothing);
      expect(find.text('MOST USED'), findsOneWidget);
    });

    testWidgets('search filters cards by name', (tester) async {
      await pumpHomeScreen(
        tester,
        cards: [
          _makeCard(id: '1', name: 'Tesco Clubcard'),
          _makeCard(id: '2', name: 'Boots Advantage'),
        ],
      );
      await tester.enterText(find.byType(TextField), 'Tesco');
      await tester.pump();

      expect(find.text('Tesco Clubcard'), findsOneWidget);
      expect(find.text('Boots Advantage'), findsNothing);
    });

    testWidgets('search filters cards by issuer', (tester) async {
      await pumpHomeScreen(
        tester,
        cards: [
          _makeCard(id: '1', name: 'My Card', issuer: 'Nectar'),
          _makeCard(id: '2', name: 'Other Card', issuer: 'Costa'),
        ],
      );
      await tester.enterText(find.byType(TextField), 'Nectar');
      await tester.pump();

      expect(find.text('My Card'), findsOneWidget);
      expect(find.text('Other Card'), findsNothing);
    });

    testWidgets('shows no results message when search has no matches', (
      tester,
    ) async {
      await pumpHomeScreen(
        tester,
        cards: [_makeCard(id: '1', name: 'Tesco Clubcard')],
      );
      await tester.enterText(find.byType(TextField), 'zzzzz');
      await tester.pump();

      expect(find.textContaining('No cards match'), findsOneWidget);
    });

    testWidgets('cards sorted: favourites first, then by usage', (
      tester,
    ) async {
      await pumpHomeScreen(
        tester,
        cards: [
          _makeCard(id: 'a', name: 'Popular', usageCount: 100),
          _makeCard(id: 'b', name: 'Fav Low', usageCount: 1, isFavourite: true),
          _makeCard(id: 'c', name: 'Medium', usageCount: 50),
        ],
      );

      final favPos = tester.getTopLeft(find.text('Fav Low')).dy;
      final popularPos = tester.getTopLeft(find.text('Popular')).dy;
      final mediumPos = tester.getTopLeft(find.text('Medium')).dy;

      expect(favPos, lessThan(popularPos));
      expect(popularPos, lessThan(mediumPos));
    });

    testWidgets('long press shows action sheet', (tester) async {
      await pumpHomeScreen(tester, cards: [_makeCard()]);
      await tester.longPress(find.byType(CardTile));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Edit'), findsOneWidget);
      expect(find.text('Share'), findsOneWidget);
      expect(find.text('Add to favourites'), findsOneWidget);
      expect(find.text('Delete'), findsOneWidget);
    });

    testWidgets('action sheet shows "Remove from favourites" for favourites', (
      tester,
    ) async {
      await pumpHomeScreen(tester, cards: [_makeCard(isFavourite: true)]);
      await tester.longPress(find.byType(CardTile));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Remove from favourites'), findsOneWidget);
    });

    testWidgets('delete action shows confirmation dialog', (tester) async {
      await pumpHomeScreen(tester, cards: [_makeCard()]);
      await tester.longPress(find.byType(CardTile));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      await tester.tap(find.text('Delete'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.text('Delete card?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });
  });
}
