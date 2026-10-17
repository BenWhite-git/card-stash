// ABOUTME: Lays out every main screen at 200% text scale on a phone-sized surface.
// ABOUTME: Any RenderFlex overflow is reported as a test failure.

import 'dart:io';

import 'package:card_stash/hive_registrar.g.dart';
import 'package:card_stash/models/card.dart';
import 'package:card_stash/providers/first_launch_provider.dart';
import 'package:card_stash/providers/notification_provider.dart';
import 'package:card_stash/screens/add_card_screen.dart';
import 'package:card_stash/screens/card_display_screen.dart';
import 'package:card_stash/screens/edit_card_screen.dart';
import 'package:card_stash/screens/home_screen.dart';
import 'package:card_stash/screens/notifications_screen.dart';
import 'package:card_stash/screens/settings_screen.dart';
import 'package:card_stash/services/brightness_service.dart';
import 'package:card_stash/services/storage_service.dart';
import 'package:card_stash/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/stub_notification_service.dart';

class _FakeBrightnessControl implements ScreenBrightnessControl {
  @override
  Future<double> get systemBrightness async => 0.5;
  @override
  Future<double> get applicationBrightness async => 0.5;
  @override
  Future<void> setApplicationScreenBrightness(double brightness) async {}
  @override
  Future<void> resetApplicationScreenBrightness() async {}
}

late Directory _tempDir;
var _boxCounter = 0;

LoyaltyCard _card(String id, {DateTime? expiryDate, bool favourite = false}) {
  return LoyaltyCard(
    id: id,
    name: 'A deliberately long loyalty card name number $id',
    issuer: 'An equally long issuing organisation name',
    cardNumber: '6340 1234 5678 9012 3456',
    barcodeType: BarcodeType.code128,
    colourValue: Colors.blue.toARGB32(),
    createdAt: DateTime(2026, 1, 1),
    isFavourite: favourite,
    notes: 'Some notes long enough to wrap onto more than one line at scale.',
    expiryDate: expiryDate,
  );
}

void main() {
  late Box<LoyaltyCard> box;
  late SharedPreferences prefs;

  setUpAll(() async {
    _tempDir = await Directory.systemTemp.createTemp('text_scale_test_');
    Hive.init(_tempDir.path);
    Hive.registerAdapters();
  });

  setUp(() async {
    _boxCounter++;
    box = await Hive.openBox<LoyaltyCard>('text_scale_$_boxCounter');
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
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

  /// Pumps [screen] at 200% text scale on a 390x844 logical surface, with
  /// Hive writes and the pump itself run in real time so screens that write
  /// in initState do not deadlock.
  Future<void> pumpAtLargeText(
    WidgetTester tester,
    Widget screen, {
    List<LoyaltyCard> cards = const [],
  }) async {
    tester.view.physicalSize = const Size(390, 844);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.runAsync(() async {
      for (final card in cards) {
        await box.put(card.id, card);
      }
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            storageServiceProvider.overrideWithValue(
              StorageService.fromBox(box),
            ),
            notificationServiceProvider.overrideWithValue(
              StubNotificationService(),
            ),
            sharedPreferencesProvider.overrideWithValue(prefs),
            brightnessServiceProvider.overrideWithValue(
              BrightnessService(brightnessControl: _FakeBrightnessControl()),
            ),
          ],
          child: MaterialApp(
            theme: buildLightTheme(),
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(
                context,
              ).copyWith(textScaler: const TextScaler.linear(2.0)),
              child: child!,
            ),
            home: screen,
          ),
        ),
      );
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
    await tester.pump();
  }

  group('200% text scale has no overflow on', () {
    testWidgets('HomeScreen with cards and backup banner', (tester) async {
      await pumpAtLargeText(
        tester,
        const HomeScreen(),
        cards: [
          _card('1', favourite: true, expiryDate: DateTime(2030, 1, 1)),
          _card('2', expiryDate: DateTime.now().add(const Duration(days: 3))),
          _card('3'),
        ],
      );
      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('CardDisplayScreen', (tester) async {
      await pumpAtLargeText(
        tester,
        const CardDisplayScreen(cardId: '1'),
        cards: [_card('1', expiryDate: DateTime(2030, 1, 1))],
      );
      expect(find.byType(CardDisplayScreen), findsOneWidget);
    });

    testWidgets('AddCardScreen', (tester) async {
      await pumpAtLargeText(
        tester,
        const AddCardScreen(initialScanMode: false),
      );
      expect(find.byType(AddCardScreen), findsOneWidget);
    });

    testWidgets('EditCardScreen', (tester) async {
      await pumpAtLargeText(
        tester,
        const EditCardScreen(cardId: '1'),
        cards: [_card('1', expiryDate: DateTime(2030, 1, 1))],
      );
      expect(find.byType(EditCardScreen), findsOneWidget);
    });

    testWidgets('SettingsScreen', (tester) async {
      await pumpAtLargeText(tester, const SettingsScreen());
      expect(find.byType(SettingsScreen), findsOneWidget);
    });

    testWidgets('NotificationsScreen', (tester) async {
      await pumpAtLargeText(
        tester,
        const NotificationsScreen(),
        cards: [
          _card('1', expiryDate: DateTime.now().add(const Duration(days: 3))),
          _card('2', expiryDate: DateTime(2030, 1, 1)),
        ],
      );
      expect(find.byType(NotificationsScreen), findsOneWidget);
    });
  });
}
