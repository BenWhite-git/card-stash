// ABOUTME: Unit tests for CardListNotifier CRUD operations.
// ABOUTME: Uses in-memory Hive box to test add, read, update, delete, sort order.

import 'dart:io';

import 'package:card_stash/models/card.dart';
import 'package:card_stash/providers/card_provider.dart';
import 'package:card_stash/providers/notification_provider.dart';
import 'package:card_stash/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import 'package:card_stash/hive_registrar.g.dart';

import '../helpers/stub_notification_service.dart';

late Directory _tempDir;
var _boxCounter = 0;

LoyaltyCard _makeCard({
  String id = '1',
  String name = 'Test Card',
  int usageCount = 0,
  bool isFavourite = false,
  DateTime? expiryDate,
  List<int>? notificationIds,
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
    expiryDate: expiryDate,
    notificationIds: notificationIds,
  );
}

ProviderContainer _createContainer(
  Box<LoyaltyCard> box,
  StubNotificationService notificationService,
) {
  final storageService = StorageService.fromBox(box);
  return ProviderContainer(
    overrides: [
      storageServiceProvider.overrideWithValue(storageService),
      notificationServiceProvider.overrideWithValue(notificationService),
    ],
  );
}

void main() {
  late Box<LoyaltyCard> box;
  late ProviderContainer container;
  late StubNotificationService stubNotifications;

  setUpAll(() async {
    _tempDir = await Directory.systemTemp.createTemp('card_stash_test_');
    Hive.init(_tempDir.path);
    Hive.registerAdapters();
  });

  setUp(() async {
    _boxCounter++;
    box = await Hive.openBox<LoyaltyCard>('test_cards_$_boxCounter');
    stubNotifications = StubNotificationService();
    container = _createContainer(box, stubNotifications);
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

  group('CardListNotifier notification integration', () {
    test('addCard with expiry schedules notifications', () async {
      final notifier = container.read(cardListProvider.notifier);
      await notifier.addCard(
        _makeCard(expiryDate: DateTime.now().add(const Duration(days: 60))),
      );

      expect(stubNotifications.calls, contains('schedule:1'));
    });

    test('addCard without expiry does not schedule notifications', () async {
      final notifier = container.read(cardListProvider.notifier);
      await notifier.addCard(_makeCard());

      expect(
        stubNotifications.calls.where((c) => c.startsWith('schedule')),
        isEmpty,
      );
    });

    test('addCard stores notification IDs on card', () async {
      final notifier = container.read(cardListProvider.notifier);
      await notifier.addCard(
        _makeCard(expiryDate: DateTime.now().add(const Duration(days: 60))),
      );

      final card = container.read(cardListProvider).first;
      expect(card.notificationIds, isNotNull);
      expect(card.notificationIds, isNotEmpty);
    });

    test('updateCard cancels old and schedules new notifications', () async {
      final notifier = container.read(cardListProvider.notifier);
      await notifier.addCard(
        _makeCard(expiryDate: DateTime.now().add(const Duration(days: 60))),
      );
      stubNotifications.calls.clear();

      await notifier.updateCard(
        _makeCard(
          name: 'Updated',
          expiryDate: DateTime.now().add(const Duration(days: 90)),
        ),
      );

      expect(stubNotifications.calls, contains('cancel:1'));
      expect(stubNotifications.calls, contains('schedule:1'));
    });

    test('updateCard clears notification IDs when expiry removed', () async {
      final notifier = container.read(cardListProvider.notifier);
      await notifier.addCard(
        _makeCard(expiryDate: DateTime.now().add(const Duration(days: 60))),
      );

      await notifier.updateCard(_makeCard(name: 'No Expiry'));

      final card = container.read(cardListProvider).first;
      expect(card.notificationIds, isEmpty);
    });

    test('deleteCard cancels notifications', () async {
      final notifier = container.read(cardListProvider.notifier);
      await notifier.addCard(_makeCard(notificationIds: [100, 101, 102]));
      stubNotifications.calls.clear();

      await notifier.deleteCard('1');

      expect(stubNotifications.calls, contains('cancel:1'));
    });

    test('deleteCard handles card with null notificationIds', () async {
      final notifier = container.read(cardListProvider.notifier);
      await notifier.addCard(_makeCard());
      stubNotifications.calls.clear();

      await notifier.deleteCard('1');

      // Should call cancel but not crash (notificationIds is null).
      expect(stubNotifications.calls, contains('cancel:1'));
    });
  });
}
