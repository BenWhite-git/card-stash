// ABOUTME: Unit tests for ExportService card export pipeline.
// ABOUTME: Tests serialisation, file structure, encryption, and empty box handling.

import 'dart:convert';
import 'dart:io';

import 'package:card_stash/models/card.dart';
import 'package:card_stash/models/export_manifest.dart';
import 'package:card_stash/services/export_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:card_stash/hive_registrar.g.dart';
import 'package:hive_ce/hive.dart';

void main() {
  late Directory tempDir;
  late Box<LoyaltyCard> box;
  var boxCounter = 0;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('export_service_test_');
    Hive.init(tempDir.path);
    Hive.registerAdapters();
  });

  setUp(() async {
    boxCounter++;
    box = await Hive.openBox<LoyaltyCard>('test_export_$boxCounter');
  });

  tearDown(() async {
    await box.deleteFromDisk();
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

  group('ExportService', () {
    test('buildExportFile creates a valid .cardstash file', () async {
      await box.put('card-1', makeCard());
      final service = ExportService(box);

      final file = await service.buildExportFile('test-passphrase');

      expect(file.existsSync(), isTrue);
      expect(file.path.endsWith('.cardstash'), isTrue);

      final contents =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      expect(contents['version'], 1);
      expect(contents['exported_at'], isNotEmpty);
      expect(contents['signature'], isNotEmpty);
      expect(contents['payload'], isNotEmpty);
      expect(contents['salt'], isNotEmpty);

      // Clean up temp file.
      await file.delete();
    });

    test('buildExportFile with multiple cards', () async {
      await box.put('card-1', makeCard(id: 'card-1', name: 'Card One'));
      await box.put('card-2', makeCard(id: 'card-2', name: 'Card Two'));
      await box.put(
        'card-3',
        makeCard(id: 'card-3', name: 'Card Three', isFavourite: true),
      );
      final service = ExportService(box);

      final file = await service.buildExportFile('multi-pass');

      expect(file.existsSync(), isTrue);
      final contents =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      final manifest = ExportManifest.fromJson(contents);
      expect(manifest.version, 1);

      await file.delete();
    });

    test('buildExportFile handles empty box', () async {
      final service = ExportService(box);

      final file = await service.buildExportFile('empty-pass');

      expect(file.existsSync(), isTrue);
      final contents =
          jsonDecode(await file.readAsString()) as Map<String, dynamic>;
      expect(contents['version'], 1);

      await file.delete();
    });

    test('cleanupExportFile deletes the temp file and directory', () async {
      await box.put('card-1', makeCard());
      final service = ExportService(box);

      final file = await service.buildExportFile('cleanup-test');
      expect(file.existsSync(), isTrue);
      final dir = file.parent;
      expect(dir.existsSync(), isTrue);

      await service.cleanupExportFile(file);
      expect(file.existsSync(), isFalse);
      expect(dir.existsSync(), isFalse);
    });

    test(
      'buildExportFile produces different output for different passphrases',
      () async {
        await box.put('card-1', makeCard());
        final service = ExportService(box);

        final file1 = await service.buildExportFile('pass-one');
        final file2 = await service.buildExportFile('pass-two');

        final contents1 = await file1.readAsString();
        final contents2 = await file2.readAsString();
        expect(contents1, isNot(contents2));

        await file1.delete();
        await file2.delete();
      },
    );
  });
}
