// ABOUTME: Smoke test for the Card Stash app.
// ABOUTME: Verifies the app launches and renders without errors.

import 'dart:io';

import 'package:card_stash/hive_registrar.g.dart';
import 'package:card_stash/main.dart';
import 'package:card_stash/models/card.dart';
import 'package:card_stash/services/storage_service.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

void main() {
  late Box<LoyaltyCard> box;

  setUpAll(() async {
    final tempDir = await Directory.systemTemp.createTemp('cs_smoke_');
    Hive.init(tempDir.path);
    Hive.registerAdapters();
    box = await Hive.openBox<LoyaltyCard>('smoke_test');
  });

  testWidgets('App renders Card Stash heading', (WidgetTester tester) async {
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          storageServiceProvider.overrideWithValue(StorageService.fromBox(box)),
        ],
        child: const CardStashApp(),
      ),
    );
    await tester.pump();

    expect(find.text('Card Stash'), findsOneWidget);
  });
}
