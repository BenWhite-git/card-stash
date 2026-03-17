// ABOUTME: Widget tests for the Alerts screen (NotificationsScreen).
// ABOUTME: Verifies expiry list sorting, empty state, and badge display.

import 'dart:io';

import 'package:card_stash/hive_registrar.g.dart';
import 'package:card_stash/models/card.dart';
import 'package:card_stash/providers/notification_provider.dart';
import 'package:card_stash/screens/notifications_screen.dart';
import 'package:card_stash/services/storage_service.dart';
import 'package:card_stash/widgets/expiry_badge.dart';
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
  DateTime? expiryDate,
}) {
  return LoyaltyCard(
    id: id,
    name: name,
    cardNumber: '1234567890',
    barcodeType: BarcodeType.code128,
    colourValue: Colors.blue.toARGB32(),
    createdAt: DateTime(2026, 1, 1),
    expiryDate: expiryDate,
  );
}

void main() {
  late Box<LoyaltyCard> box;

  setUpAll(() async {
    _tempDir = await Directory.systemTemp.createTemp('card_stash_alerts_');
    Hive.init(_tempDir.path);
    Hive.registerAdapters();
  });

  setUp(() async {
    _boxCounter++;
    box = await Hive.openBox<LoyaltyCard>('test_alerts_$_boxCounter');
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

  Future<void> pumpAlertsScreen(
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
        child: const MaterialApp(home: NotificationsScreen()),
      ),
    );
  }

  group('NotificationsScreen', () {
    testWidgets('shows empty state when no cards have expiry dates', (
      tester,
    ) async {
      await pumpAlertsScreen(
        tester,
        cards: [_makeCard(id: '1', name: 'No Expiry')],
      );
      expect(find.text('No cards with expiry dates'), findsOneWidget);
    });

    testWidgets('shows empty state when no cards exist', (tester) async {
      await pumpAlertsScreen(tester);
      expect(find.text('No cards with expiry dates'), findsOneWidget);
    });

    testWidgets('shows cards with expiry dates sorted by soonest first', (
      tester,
    ) async {
      final soonExpiry = DateTime.now().add(const Duration(days: 5));
      final laterExpiry = DateTime.now().add(const Duration(days: 20));

      await pumpAlertsScreen(
        tester,
        cards: [
          _makeCard(id: '1', name: 'Later Card', expiryDate: laterExpiry),
          _makeCard(id: '2', name: 'Soon Card', expiryDate: soonExpiry),
          _makeCard(id: '3', name: 'No Expiry Card'),
        ],
      );

      // Both expiry cards should be visible, no-expiry card should not.
      expect(find.text('Soon Card'), findsOneWidget);
      expect(find.text('Later Card'), findsOneWidget);
      expect(find.text('No Expiry Card'), findsNothing);

      // Soon Card should appear before Later Card.
      final soonPos = tester.getTopLeft(find.text('Soon Card')).dy;
      final laterPos = tester.getTopLeft(find.text('Later Card')).dy;
      expect(soonPos, lessThan(laterPos));
    });

    testWidgets('shows ExpiryBadge for cards within 30 days', (tester) async {
      final soonExpiry = DateTime.now().add(const Duration(days: 5));
      await pumpAlertsScreen(
        tester,
        cards: [_makeCard(id: '1', name: 'Expiring', expiryDate: soonExpiry)],
      );
      expect(find.byType(ExpiryBadge), findsOneWidget);
    });

    testWidgets('shows Alerts heading', (tester) async {
      await pumpAlertsScreen(tester);
      expect(find.text('Alerts'), findsOneWidget);
    });
  });
}
