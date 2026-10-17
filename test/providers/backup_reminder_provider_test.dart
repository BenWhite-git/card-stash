// ABOUTME: Unit tests for the backup reminder rules.
// ABOUTME: Covers first-reminder threshold, stale backup detection, snooze and recording exports.

import 'dart:io';

import 'package:card_stash/models/card.dart';
import 'package:card_stash/providers/backup_reminder_provider.dart';
import 'package:card_stash/providers/first_launch_provider.dart';
import 'package:card_stash/providers/notification_provider.dart';
import 'package:card_stash/services/storage_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:card_stash/hive_registrar.g.dart';

import '../helpers/stub_notification_service.dart';

late Directory _tempDir;
var _boxCounter = 0;

final _now = DateTime(2026, 10, 17, 12);

LoyaltyCard _makeCard(String id, {DateTime? createdAt}) {
  return LoyaltyCard(
    id: id,
    name: 'Card $id',
    cardNumber: '000$id',
    barcodeType: BarcodeType.code128,
    colourValue: Colors.blue.toARGB32(),
    createdAt: createdAt ?? DateTime(2026, 1, 1),
  );
}

void main() {
  late Box<LoyaltyCard> box;
  late SharedPreferences prefs;
  late ProviderContainer container;

  setUpAll(() async {
    _tempDir = await Directory.systemTemp.createTemp('backup_reminder_test_');
    Hive.init(_tempDir.path);
    Hive.registerAdapters();
  });

  setUp(() async {
    _boxCounter++;
    box = await Hive.openBox<LoyaltyCard>('backup_$_boxCounter');
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
    container = ProviderContainer(
      overrides: [
        storageServiceProvider.overrideWithValue(StorageService.fromBox(box)),
        notificationServiceProvider.overrideWithValue(
          StubNotificationService(),
        ),
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(() => _now),
      ],
    );
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

  Future<void> addCards(int count, {DateTime? createdAt}) async {
    for (var i = 0; i < count; i++) {
      await box.put('$i', _makeCard('$i', createdAt: createdAt));
    }
  }

  group('backupReminderDueProvider', () {
    test('not due with no cards', () {
      expect(container.read(backupReminderDueProvider), isFalse);
    });

    test('not due before the first-reminder threshold is reached', () async {
      await addCards(minCardsBeforeFirstReminder - 1);
      expect(container.read(backupReminderDueProvider), isFalse);
    });

    test('due once the threshold is reached and never exported', () async {
      await addCards(minCardsBeforeFirstReminder);
      expect(container.read(backupReminderDueProvider), isTrue);
    });

    test('not due when a recent export exists', () async {
      await addCards(5);
      await prefs.setString(
        lastExportKey,
        _now.subtract(const Duration(days: 10)).toIso8601String(),
      );
      container.invalidate(backupReminderProvider);
      expect(container.read(backupReminderDueProvider), isFalse);
    });

    test(
      'not due when the export is stale but no cards were added since',
      () async {
        final exportedAt = _now.subtract(const Duration(days: 45));
        await addCards(
          5,
          createdAt: exportedAt.subtract(const Duration(days: 1)),
        );
        await prefs.setString(lastExportKey, exportedAt.toIso8601String());
        container.invalidate(backupReminderProvider);
        expect(container.read(backupReminderDueProvider), isFalse);
      },
    );

    test('due when the export is stale and cards were added since', () async {
      final exportedAt = _now.subtract(const Duration(days: 45));
      await addCards(1, createdAt: exportedAt.add(const Duration(days: 1)));
      await prefs.setString(lastExportKey, exportedAt.toIso8601String());
      container.invalidate(backupReminderProvider);
      expect(container.read(backupReminderDueProvider), isTrue);
    });

    test('not due while snoozed', () async {
      await addCards(minCardsBeforeFirstReminder);
      await container.read(backupReminderProvider.notifier).snooze();
      expect(container.read(backupReminderDueProvider), isFalse);
      expect(
        container.read(backupReminderProvider).snoozedUntil,
        _now.add(snoozeDuration),
      );
    });

    test('recording an export clears the reminder and the snooze', () async {
      await addCards(minCardsBeforeFirstReminder);
      final notifier = container.read(backupReminderProvider.notifier);
      await notifier.snooze();
      await notifier.recordExport();

      final state = container.read(backupReminderProvider);
      expect(state.lastExportAt, _now);
      expect(state.snoozedUntil, isNull);
      expect(container.read(backupReminderDueProvider), isFalse);
      expect(prefs.getString(lastExportKey), _now.toIso8601String());
    });
  });
}
