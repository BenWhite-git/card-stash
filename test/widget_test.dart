// ABOUTME: Smoke test for the Card Stash app.
// ABOUTME: Verifies the app launches and renders without errors.

import 'dart:io';

import 'package:card_stash/hive_registrar.g.dart';
import 'package:card_stash/main.dart';
import 'package:card_stash/models/card.dart';
import 'package:card_stash/providers/first_launch_provider.dart';
import 'package:card_stash/providers/notification_provider.dart';
import 'package:card_stash/services/storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'helpers/stub_notification_service.dart';

void main() {
  late Box<LoyaltyCard> box;
  late SharedPreferences prefs;

  setUpAll(() async {
    final tempDir = await Directory.systemTemp.createTemp('cs_smoke_');
    Hive.init(tempDir.path);
    Hive.registerAdapters();
    box = await Hive.openBox<LoyaltyCard>('smoke_test');
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  testWidgets('App renders Card Stash heading', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(StorageService.fromBox(box)),
          notificationServiceProvider.overrideWithValue(
            StubNotificationService(),
          ),
          sharedPreferencesProvider.overrideWithValue(prefs),
        ],
        child: const CardStashApp(),
      ),
    );
    await tester.pump();

    expect(find.text('Card Stash'), findsOneWidget);
  });
}
