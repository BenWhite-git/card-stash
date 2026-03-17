// ABOUTME: Unit tests for LoyaltyCard export JSON serialisation.
// ABOUTME: Tests round-trip, field exclusions, and nullable field handling.

import 'package:card_stash/models/card.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('LoyaltyCard export serialisation', () {
    LoyaltyCard makeCard({
      String id = 'test-id',
      String name = 'Tesco Clubcard',
      String? issuer = 'Tesco',
      String cardNumber = '1234567890',
      BarcodeType barcodeType = BarcodeType.ean13,
      int colourValue = 0xFF42A5F5,
      String? logoPath,
      DateTime? expiryDate,
      int usageCount = 5,
      DateTime? lastUsed,
      DateTime? createdAt,
      String? notes,
      bool isFavourite = false,
      List<int>? notificationIds,
    }) {
      return LoyaltyCard(
        id: id,
        name: name,
        issuer: issuer,
        cardNumber: cardNumber,
        barcodeType: barcodeType,
        colourValue: colourValue,
        logoPath: logoPath,
        expiryDate: expiryDate,
        usageCount: usageCount,
        lastUsed: lastUsed,
        createdAt: createdAt ?? DateTime.utc(2026, 1, 1),
        notes: notes,
        isFavourite: isFavourite,
        notificationIds: notificationIds,
      );
    }

    test('toExportJson includes all standard fields', () {
      final card = makeCard(
        expiryDate: DateTime.utc(2027, 6, 15),
        lastUsed: DateTime.utc(2026, 3, 10),
        notes: 'Joint account',
        isFavourite: true,
      );

      final json = card.toExportJson();

      expect(json['id'], 'test-id');
      expect(json['name'], 'Tesco Clubcard');
      expect(json['issuer'], 'Tesco');
      expect(json['cardNumber'], '1234567890');
      expect(json['barcodeType'], 'ean13');
      expect(json['colourValue'], 0xFF42A5F5);
      expect(json['expiryDate'], '2027-06-15T00:00:00.000Z');
      expect(json['usageCount'], 5);
      expect(json['lastUsed'], '2026-03-10T00:00:00.000Z');
      expect(json['createdAt'], '2026-01-01T00:00:00.000Z');
      expect(json['notes'], 'Joint account');
      expect(json['isFavourite'], true);
    });

    test('toExportJson excludes logoPath', () {
      final card = makeCard(logoPath: '/path/to/logo.png');
      final json = card.toExportJson();
      expect(json.containsKey('logoPath'), isFalse);
    });

    test('toExportJson excludes notificationIds', () {
      final card = makeCard(notificationIds: [1, 2, 3]);
      final json = card.toExportJson();
      expect(json.containsKey('notificationIds'), isFalse);
    });

    test('toExportJson handles null optional fields', () {
      final card = makeCard(
        issuer: null,
        expiryDate: null,
        lastUsed: null,
        notes: null,
      );

      final json = card.toExportJson();

      expect(json['issuer'], isNull);
      expect(json['expiryDate'], isNull);
      expect(json['lastUsed'], isNull);
      expect(json['notes'], isNull);
    });

    test('fromExportJson round-trip preserves all fields', () {
      final original = makeCard(
        expiryDate: DateTime.utc(2027, 6, 15),
        lastUsed: DateTime.utc(2026, 3, 10),
        notes: 'Joint account',
        isFavourite: true,
      );

      final json = original.toExportJson();
      final restored = LoyaltyCard.fromExportJson(json);

      expect(restored.id, original.id);
      expect(restored.name, original.name);
      expect(restored.issuer, original.issuer);
      expect(restored.cardNumber, original.cardNumber);
      expect(restored.barcodeType, original.barcodeType);
      expect(restored.colourValue, original.colourValue);
      expect(restored.expiryDate, original.expiryDate);
      expect(restored.usageCount, original.usageCount);
      expect(restored.lastUsed, original.lastUsed);
      expect(restored.createdAt, original.createdAt);
      expect(restored.notes, original.notes);
      expect(restored.isFavourite, original.isFavourite);
    });

    test('fromExportJson restores null optional fields', () {
      final original = makeCard(
        issuer: null,
        expiryDate: null,
        lastUsed: null,
        notes: null,
      );

      final restored = LoyaltyCard.fromExportJson(original.toExportJson());

      expect(restored.issuer, isNull);
      expect(restored.expiryDate, isNull);
      expect(restored.lastUsed, isNull);
      expect(restored.notes, isNull);
    });

    test('fromExportJson sets logoPath to null', () {
      final card = makeCard();
      final restored = LoyaltyCard.fromExportJson(card.toExportJson());
      expect(restored.logoPath, isNull);
    });

    test('fromExportJson sets notificationIds to null', () {
      final card = makeCard();
      final restored = LoyaltyCard.fromExportJson(card.toExportJson());
      expect(restored.notificationIds, isNull);
    });

    test('fromExportJson handles all barcode types', () {
      for (final type in BarcodeType.values) {
        final card = makeCard(barcodeType: type);
        final restored = LoyaltyCard.fromExportJson(card.toExportJson());
        expect(restored.barcodeType, type);
      }
    });
  });
}
