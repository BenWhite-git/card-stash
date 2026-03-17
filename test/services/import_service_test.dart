// ABOUTME: Unit tests for ImportService card import pipeline.
// ABOUTME: Tests round-trip, HMAC verification, merge, replace, and error cases.

import 'dart:convert';
import 'dart:io';

import 'package:card_stash/hive_registrar.g.dart';
import 'package:card_stash/models/card.dart';
import 'package:card_stash/services/export_service.dart';
import 'package:card_stash/services/import_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import '../helpers/stub_notification_service.dart';

void main() {
  late Directory tempDir;
  late Box<LoyaltyCard> exportBox;
  late Box<LoyaltyCard> importBox;
  late StubNotificationService stubNotifications;
  var boxCounter = 0;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('import_service_test_');
    Hive.init(tempDir.path);
    Hive.registerAdapters();
  });

  setUp(() async {
    boxCounter++;
    exportBox = await Hive.openBox<LoyaltyCard>('test_export_$boxCounter');
    importBox = await Hive.openBox<LoyaltyCard>('test_import_$boxCounter');
    stubNotifications = StubNotificationService();
  });

  tearDown(() async {
    await exportBox.deleteFromDisk();
    await importBox.deleteFromDisk();
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  LoyaltyCard makeCard({
    String id = 'card-1',
    String name = 'Tesco Clubcard',
    String? issuer = 'Tesco',
    String cardNumber = '1234567890',
    BarcodeType barcodeType = BarcodeType.ean13,
    int colourValue = 0xFF42A5F5,
    DateTime? expiryDate,
    String? notes,
    bool isFavourite = false,
  }) {
    return LoyaltyCard(
      id: id,
      name: name,
      issuer: issuer,
      cardNumber: cardNumber,
      barcodeType: barcodeType,
      colourValue: colourValue,
      expiryDate: expiryDate,
      createdAt: DateTime.utc(2026, 1, 1),
      notes: notes,
      isFavourite: isFavourite,
    );
  }

  /// Helper: export cards from exportBox and return the file path.
  Future<String> exportFile(String passphrase) async {
    final service = ExportService(exportBox);
    final file = await service.buildExportFile(passphrase);
    return file.path;
  }

  group('ImportService', () {
    group('replace all', () {
      test('imports all cards into empty box', () async {
        await exportBox.put('c1', makeCard(id: 'c1', name: 'Card One'));
        await exportBox.put('c2', makeCard(id: 'c2', name: 'Card Two'));
        final filePath = await exportFile('test-pass');
        final service = ImportService(importBox, stubNotifications);

        final result = await service.importCards(
          filePath,
          'test-pass',
          ImportMode.replaceAll,
        );

        expect(result.totalCards, 2);
        expect(result.importedCards, 2);
        expect(result.skippedDuplicates, 0);
        expect(importBox.length, 2);
      });

      test('clears existing cards before importing', () async {
        // Pre-populate import box.
        await importBox.put(
          'existing',
          makeCard(id: 'existing', name: 'Old Card'),
        );
        await exportBox.put('c1', makeCard(id: 'c1', name: 'New Card'));
        final filePath = await exportFile('test-pass');
        final service = ImportService(importBox, stubNotifications);

        final result = await service.importCards(
          filePath,
          'test-pass',
          ImportMode.replaceAll,
        );

        expect(result.importedCards, 1);
        expect(importBox.length, 1);
        expect(importBox.values.first.name, 'New Card');
      });

      test(
        'cancels notifications for existing cards before clearing',
        () async {
          final existingCard = LoyaltyCard(
            id: 'existing',
            name: 'Old Card',
            cardNumber: '999999',
            barcodeType: BarcodeType.ean13,
            colourValue: 0xFF42A5F5,
            createdAt: DateTime.utc(2026, 1, 1),
            expiryDate: DateTime.utc(2027, 1, 1),
            notificationIds: [100, 101],
          );
          await importBox.put('existing', existingCard);
          await exportBox.put('c1', makeCard(id: 'c1'));
          final filePath = await exportFile('test-pass');
          final service = ImportService(importBox, stubNotifications);

          await service.importCards(
            filePath,
            'test-pass',
            ImportMode.replaceAll,
          );

          expect(stubNotifications.calls, contains('cancel:existing'));
        },
      );
    });

    group('merge', () {
      test('adds non-duplicate cards', () async {
        await importBox.put(
          'existing',
          makeCard(id: 'existing', cardNumber: '111111'),
        );
        await exportBox.put(
          'new-card',
          makeCard(id: 'new-card', cardNumber: '222222'),
        );
        final filePath = await exportFile('test-pass');
        final service = ImportService(importBox, stubNotifications);

        final result = await service.importCards(
          filePath,
          'test-pass',
          ImportMode.merge,
        );

        expect(result.importedCards, 1);
        expect(result.skippedDuplicates, 0);
        expect(importBox.length, 2);
      });

      test('skips duplicates by normalised card number', () async {
        await importBox.put(
          'existing',
          makeCard(id: 'existing', cardNumber: '1234567890'),
        );
        await exportBox.put(
          'dupe',
          makeCard(id: 'dupe', cardNumber: '1234 5678 90'),
        );
        final filePath = await exportFile('test-pass');
        final service = ImportService(importBox, stubNotifications);

        final result = await service.importCards(
          filePath,
          'test-pass',
          ImportMode.merge,
        );

        expect(result.importedCards, 0);
        expect(result.skippedDuplicates, 1);
        expect(importBox.length, 1);
      });

      test('normalises hyphens in card numbers for duplicate check', () async {
        await importBox.put(
          'existing',
          makeCard(id: 'existing', cardNumber: '1234-5678-90'),
        );
        await exportBox.put(
          'dupe',
          makeCard(id: 'dupe', cardNumber: '1234567890'),
        );
        final filePath = await exportFile('test-pass');
        final service = ImportService(importBox, stubNotifications);

        final result = await service.importCards(
          filePath,
          'test-pass',
          ImportMode.merge,
        );

        expect(result.skippedDuplicates, 1);
        expect(importBox.length, 1);
      });

      test('generates new UUID when imported card ID collides', () async {
        await importBox.put(
          'same-id',
          makeCard(id: 'same-id', cardNumber: '111111'),
        );
        await exportBox.put(
          'same-id',
          makeCard(id: 'same-id', cardNumber: '222222'),
        );
        final filePath = await exportFile('test-pass');
        final service = ImportService(importBox, stubNotifications);

        final result = await service.importCards(
          filePath,
          'test-pass',
          ImportMode.merge,
        );

        expect(result.importedCards, 1);
        expect(importBox.length, 2);
        // Both cards should exist with different IDs.
        final ids = importBox.values.map((c) => c.id).toSet();
        expect(ids.length, 2);
      });
    });

    group('error handling', () {
      test('wrong passphrase throws ImportSignatureException', () async {
        await exportBox.put('c1', makeCard());
        final filePath = await exportFile('correct-pass');
        final service = ImportService(importBox, stubNotifications);

        expect(
          () => service.importCards(
            filePath,
            'wrong-pass',
            ImportMode.replaceAll,
          ),
          throwsA(isA<ImportSignatureException>()),
        );
      });

      test('tampered payload throws ImportSignatureException', () async {
        await exportBox.put('c1', makeCard());
        final filePath = await exportFile('test-pass');

        // Tamper with the payload.
        final file = File(filePath);
        final json =
            jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        json['payload'] = 'tampered${json['payload']}';
        await file.writeAsString(jsonEncode(json));

        final service = ImportService(importBox, stubNotifications);

        expect(
          () =>
              service.importCards(filePath, 'test-pass', ImportMode.replaceAll),
          throwsA(isA<ImportSignatureException>()),
        );
      });

      test('tampered signature throws ImportSignatureException', () async {
        await exportBox.put('c1', makeCard());
        final filePath = await exportFile('test-pass');

        // Tamper with the signature.
        final file = File(filePath);
        final json =
            jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        json['signature'] = 'ff' * 32;
        await file.writeAsString(jsonEncode(json));

        final service = ImportService(importBox, stubNotifications);

        expect(
          () =>
              service.importCards(filePath, 'test-pass', ImportMode.replaceAll),
          throwsA(isA<ImportSignatureException>()),
        );
      });

      test('malformed JSON throws ImportFormatException', () async {
        final tempFile = File('${tempDir.path}/bad.cardstash');
        await tempFile.writeAsString('not json at all');
        final service = ImportService(importBox, stubNotifications);

        expect(
          () => service.importCards(
            tempFile.path,
            'test-pass',
            ImportMode.replaceAll,
          ),
          throwsA(isA<ImportFormatException>()),
        );
      });

      test('missing fields throws ImportFormatException', () async {
        final tempFile = File('${tempDir.path}/incomplete.cardstash');
        await tempFile.writeAsString(jsonEncode({'version': 1}));
        final service = ImportService(importBox, stubNotifications);

        expect(
          () => service.importCards(
            tempFile.path,
            'test-pass',
            ImportMode.replaceAll,
          ),
          throwsA(isA<ImportFormatException>()),
        );
      });

      test('odd-length hex signature throws ImportFormatException', () async {
        await exportBox.put('c1', makeCard());
        final filePath = await exportFile('test-pass');

        // Tamper signature to be odd-length hex.
        final file = File(filePath);
        final json =
            jsonDecode(await file.readAsString()) as Map<String, dynamic>;
        json['signature'] = 'abc'; // 3 chars - odd length
        await file.writeAsString(jsonEncode(json));

        final service = ImportService(importBox, stubNotifications);

        expect(
          () =>
              service.importCards(filePath, 'test-pass', ImportMode.replaceAll),
          throwsA(isA<ImportFormatException>()),
        );
      });
    });

    group('round-trip', () {
      test('export then import preserves all card fields', () async {
        final original = LoyaltyCard(
          id: 'rt-1',
          name: 'Round Trip Card',
          issuer: 'Test Issuer',
          cardNumber: '9876543210',
          barcodeType: BarcodeType.qrCode,
          colourValue: 0xFFFF5722,
          expiryDate: DateTime.utc(2027, 12, 31),
          usageCount: 42,
          lastUsed: DateTime.utc(2026, 3, 15),
          createdAt: DateTime.utc(2025, 6, 1),
          notes: 'Test notes',
          isFavourite: true,
        );
        await exportBox.put(original.id, original);
        final filePath = await exportFile('round-trip');
        final service = ImportService(importBox, stubNotifications);

        await service.importCards(
          filePath,
          'round-trip',
          ImportMode.replaceAll,
        );

        final imported = importBox.values.first;
        expect(imported.name, original.name);
        expect(imported.issuer, original.issuer);
        expect(imported.cardNumber, original.cardNumber);
        expect(imported.barcodeType, original.barcodeType);
        expect(imported.colourValue, original.colourValue);
        expect(imported.expiryDate, original.expiryDate);
        expect(imported.usageCount, original.usageCount);
        expect(imported.lastUsed, original.lastUsed);
        expect(imported.createdAt, original.createdAt);
        expect(imported.notes, original.notes);
        expect(imported.isFavourite, original.isFavourite);
      });

      test('empty export imports zero cards', () async {
        final filePath = await exportFile('empty');
        final service = ImportService(importBox, stubNotifications);

        final result = await service.importCards(
          filePath,
          'empty',
          ImportMode.replaceAll,
        );

        expect(result.totalCards, 0);
        expect(result.importedCards, 0);
        expect(importBox.isEmpty, isTrue);
      });
    });
  });
}
