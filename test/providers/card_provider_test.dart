// ABOUTME: Unit tests for CardListNotifier CRUD operations.
// ABOUTME: Uses in-memory Hive box to test add, read, update, delete, sort order.

import 'dart:io';

import 'package:card_stash/models/card.dart';
import 'package:card_stash/providers/card_provider.dart';
import 'package:card_stash/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import 'package:card_stash/hive_registrar.g.dart';

late Directory _tempDir;
var _boxCounter = 0;

LoyaltyCard _makeCard({
  String id = '1',
  String name = 'Test Card',
  int usageCount = 0,
  bool isFavourite = false,
}) {
  return LoyaltyCard(
    id: id,
    name: name,
    cardNumber: '1234567890',
    barcodeType: BarcodeType.code128,
    colourValue: Colors.blue.toARGB32(),
    createdAt: DateTime(2026, 1, 1),
    usageCount: usageCount,
    isFavourite: isFavourite,
  );
}

ProviderContainer _createContainer(Box<LoyaltyCard> box) {
  final storageService = StorageService.fromBox(box);
  return ProviderContainer(
    overrides: [storageServiceProvider.overrideWithValue(storageService)],
  );
}

void main() {
  late Box<LoyaltyCard> box;
  late ProviderContainer container;

  setUpAll(() async {
    _tempDir = await Directory.systemTemp.createTemp('card_stash_test_');
    Hive.init(_tempDir.path);
    Hive.registerAdapters();
  });

  setUp(() async {
    _boxCounter++;
    box = await Hive.openBox<LoyaltyCard>('test_cards_$_boxCounter');
    container = _createContainer(box);
  });

  tearDown(() async {
    container.dispose();
    await box.deleteFromDisk();
  });

  tearDownAll(() async {
    await Hive.close();
    if (_tempDir.existsSync()) {
      _tempDir.deleteSync(recursive: true);
    }
  });

  group('CardListNotifier', () {
    test('starts with empty list', () {
      final cards = container.read(cardListProvider);
      expect(cards, isEmpty);
    });

    test('addCard persists and returns card', () async {
      final notifier = container.read(cardListProvider.notifier);
      await notifier.addCard(_makeCard());

      final cards = container.read(cardListProvider);
      expect(cards, hasLength(1));
      expect(cards.first.name, 'Test Card');
    });

    test('updateCard modifies existing card', () async {
      final notifier = container.read(cardListProvider.notifier);
      await notifier.addCard(_makeCard());

      final updated = _makeCard(name: 'Updated Card');
      await notifier.updateCard(updated);

      final cards = container.read(cardListProvider);
      expect(cards, hasLength(1));
      expect(cards.first.name, 'Updated Card');
    });

    test('deleteCard removes card', () async {
      final notifier = container.read(cardListProvider.notifier);
      await notifier.addCard(_makeCard());
      expect(container.read(cardListProvider), hasLength(1));

      await notifier.deleteCard('1');
      expect(container.read(cardListProvider), isEmpty);
    });

    test('incrementUsage increments count and sets lastUsed', () async {
      final notifier = container.read(cardListProvider.notifier);
      await notifier.addCard(_makeCard());

      await notifier.incrementUsage('1');

      final cards = container.read(cardListProvider);
      expect(cards.first.usageCount, 1);
      expect(cards.first.lastUsed, isNotNull);
    });

    test('cards sort by usageCount descending', () async {
      final notifier = container.read(cardListProvider.notifier);
      await notifier.addCard(_makeCard(id: 'a', name: 'Low', usageCount: 1));
      await notifier.addCard(_makeCard(id: 'b', name: 'High', usageCount: 10));
      await notifier.addCard(_makeCard(id: 'c', name: 'Mid', usageCount: 5));

      final cards = container.read(cardListProvider);
      expect(cards.map((c) => c.name).toList(), ['High', 'Mid', 'Low']);
    });

    test('favourites are pinned to top regardless of usage count', () async {
      final notifier = container.read(cardListProvider.notifier);
      await notifier.addCard(
        _makeCard(id: 'a', name: 'Popular', usageCount: 100),
      );
      await notifier.addCard(
        _makeCard(id: 'b', name: 'Favourite', usageCount: 1, isFavourite: true),
      );

      final cards = container.read(cardListProvider);
      expect(cards.first.name, 'Favourite');
      expect(cards.last.name, 'Popular');
    });

    test('multiple favourites sort by usage count among themselves', () async {
      final notifier = container.read(cardListProvider.notifier);
      await notifier.addCard(
        _makeCard(id: 'a', name: 'Fav Low', usageCount: 1, isFavourite: true),
      );
      await notifier.addCard(
        _makeCard(id: 'b', name: 'Fav High', usageCount: 10, isFavourite: true),
      );
      await notifier.addCard(
        _makeCard(id: 'c', name: 'Normal', usageCount: 50),
      );

      final cards = container.read(cardListProvider);
      expect(cards.map((c) => c.name).toList(), [
        'Fav High',
        'Fav Low',
        'Normal',
      ]);
    });

    test('deleteCard for non-existent id does not throw', () async {
      final notifier = container.read(cardListProvider.notifier);
      await notifier.deleteCard('does-not-exist');
      expect(container.read(cardListProvider), isEmpty);
    });

    test('incrementUsage for non-existent id does not throw', () async {
      final notifier = container.read(cardListProvider.notifier);
      await notifier.incrementUsage('does-not-exist');
      expect(container.read(cardListProvider), isEmpty);
    });
  });
}
