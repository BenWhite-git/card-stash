// ABOUTME: Verifies the card list the home screen watches reloads after an import.
// ABOUTME: Uses a real Hive box so the import's writes are visible to the provider.

import 'dart:io';

import 'package:card_stash/hive_registrar.g.dart';
import 'package:card_stash/models/card.dart';
import 'package:card_stash/providers/card_provider.dart';
import 'package:card_stash/providers/notification_provider.dart';
import 'package:card_stash/screens/import_screen.dart';
import 'package:card_stash/services/file_picker_service.dart';
import 'package:card_stash/services/import_service.dart';
import 'package:card_stash/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import '../helpers/stub_import_service.dart';
import '../helpers/stub_notification_service.dart';

class FakeFilePickerService implements FilePickerService {
  @override
  Future<String?> pickCardstashFile() async => '/tmp/test.cardstash';
}

late Directory _tempDir;

void main() {
  late Box<LoyaltyCard> box;
  late StubImportService stubImport;

  setUpAll(() async {
    _tempDir = await Directory.systemTemp.createTemp('import_reload_test_');
    Hive.init(_tempDir.path);
    Hive.registerAdapters();
  });

  setUp(() async {
    box = await Hive.openBox<LoyaltyCard>('import_reload_test');
    stubImport = StubImportService(
      resultToReturn: const ImportResult(
        totalCards: 1,
        importedCards: 1,
        skippedDuplicates: 0,
        skippedPaymentCards: 0,
      ),
    );
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

  Widget buildImportScreen() {
    return ProviderScope(
      overrides: [
        importServiceProvider.overrideWithValue(stubImport),
        filePickerServiceProvider.overrideWithValue(FakeFilePickerService()),
        storageServiceProvider.overrideWithValue(StorageService.fromBox(box)),
        notificationServiceProvider.overrideWithValue(
          StubNotificationService(),
        ),
      ],
      child: const MaterialApp(home: ImportScreen()),
    );
  }

  testWidgets('card list reloads from the box after a successful import', (
    tester,
  ) async {
    stubImport.onImport = () => box.put(
      'imported-1',
      LoyaltyCard(
        id: 'imported-1',
        name: 'Boots Advantage',
        cardNumber: '9876543210',
        barcodeType: BarcodeType.code128,
        colourValue: Colors.teal.toARGB32(),
        createdAt: DateTime(2026, 1, 1),
      ),
    );
    await tester.pumpWidget(buildImportScreen());

    // The home screen has already built the list by the time anyone imports.
    final container = ProviderScope.containerOf(
      tester.element(find.byType(ImportScreen)),
    );
    expect(container.read(cardListProvider), isEmpty);

    await tester.tap(find.textContaining('Select file'));
    await tester.runAsync(() => Future<void>.delayed(Duration.zero));
    await tester.pump();
    await tester.enterText(find.byType(TextField), 'mypassphrase');
    await tester.pump();

    // The stub writes to Hive, which is real I/O, so run the import in
    // real time.
    await tester.runAsync(() async {
      await tester.tap(find.widgetWithText(ElevatedButton, 'Import'));
      await Future<void>.delayed(const Duration(milliseconds: 20));
    });
    await tester.pump();

    expect(find.textContaining('1 cards imported'), findsOneWidget);
    expect(container.read(cardListProvider).map((c) => c.name), [
      'Boots Advantage',
    ]);
  });
}
