// ABOUTME: Unit tests for NotificationService scheduling logic.
// ABOUTME: Tests pure date calculation and message generation without platform calls.

import 'package:card_stash/services/notification_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('NotificationService.computeSchedule', () {
    test('schedules 30-day, 7-day, and expiry-day for far-future expiry', () {
      final now = DateTime(2026, 1, 1);
      final expiry = DateTime(2026, 6, 15);

      final schedule = NotificationService.computeSchedule(
        cardName: 'Tesco Clubcard',
        expiryDate: expiry,
        now: now,
      );

      expect(schedule, hasLength(3));

      expect(schedule[0].time, DateTime(2026, 5, 16));
      expect(schedule[0].title, 'Tesco Clubcard expires in 30 days');

      expect(schedule[1].time, DateTime(2026, 6, 8));
      expect(schedule[1].title, 'Tesco Clubcard expires in 7 days');

      expect(schedule[2].time, DateTime(2026, 6, 15));
      expect(schedule[2].title, 'Tesco Clubcard expired today');
    });

    test('skips 30-day notification if expiry is less than 30 days away', () {
      final now = DateTime(2026, 3, 1);
      final expiry = DateTime(2026, 3, 20);

      final schedule = NotificationService.computeSchedule(
        cardName: 'Costa',
        expiryDate: expiry,
        now: now,
      );

      expect(schedule, hasLength(2));
      expect(schedule[0].title, 'Costa expires in 7 days');
      expect(schedule[0].time, DateTime(2026, 3, 13));
      expect(schedule[1].title, 'Costa expired today');
      expect(schedule[1].time, DateTime(2026, 3, 20));
    });

    test('skips 30-day and 7-day if expiry is less than 7 days away', () {
      final now = DateTime(2026, 3, 15);
      final expiry = DateTime(2026, 3, 18);

      final schedule = NotificationService.computeSchedule(
        cardName: 'Boots',
        expiryDate: expiry,
        now: now,
      );

      expect(schedule, hasLength(1));
      expect(schedule[0].title, 'Boots expired today');
      expect(schedule[0].time, DateTime(2026, 3, 18));
    });

    test('returns empty list if expiry is today', () {
      final now = DateTime(2026, 3, 15);
      final expiry = DateTime(2026, 3, 15);

      final schedule = NotificationService.computeSchedule(
        cardName: 'Expired',
        expiryDate: expiry,
        now: now,
      );

      expect(schedule, isEmpty);
    });

    test('returns empty list if expiry is in the past', () {
      final now = DateTime(2026, 3, 15);
      final expiry = DateTime(2026, 3, 10);

      final schedule = NotificationService.computeSchedule(
        cardName: 'Old Card',
        expiryDate: expiry,
        now: now,
      );

      expect(schedule, isEmpty);
    });

    test('uses correct message templates', () {
      final now = DateTime(2026, 1, 1);
      final expiry = DateTime(2026, 6, 1);

      final schedule = NotificationService.computeSchedule(
        cardName: 'My Card',
        expiryDate: expiry,
        now: now,
      );

      expect(schedule[0].body, 'Your My Card expires in 30 days');
      expect(schedule[1].body, 'Your My Card expires in 7 days');
      expect(
        schedule[2].body,
        'Your My Card expired today \u2014 update or remove it',
      );
    });

    test('exactly 30 days away schedules only 7-day and expiry', () {
      final now = DateTime(2026, 3, 1);
      final expiry = DateTime(2026, 3, 31);

      final schedule = NotificationService.computeSchedule(
        cardName: 'Edge',
        expiryDate: expiry,
        now: now,
      );

      // 30 days before is March 1 = now, so it's not in the future.
      expect(schedule, hasLength(2));
      expect(schedule[0].title, 'Edge expires in 7 days');
      expect(schedule[1].title, 'Edge expired today');
    });

    test('exactly 7 days away schedules only expiry-day', () {
      final now = DateTime(2026, 3, 1);
      final expiry = DateTime(2026, 3, 8);

      final schedule = NotificationService.computeSchedule(
        cardName: 'Edge7',
        expiryDate: expiry,
        now: now,
      );

      // 7 days before is March 1 = now, so it's not in the future.
      expect(schedule, hasLength(1));
      expect(schedule[0].title, 'Edge7 expired today');
    });

    test('31 days away includes 30-day notification', () {
      final now = DateTime(2026, 3, 1);
      final expiry = DateTime(2026, 4, 1);

      final schedule = NotificationService.computeSchedule(
        cardName: 'JustOver30',
        expiryDate: expiry,
        now: now,
      );

      expect(schedule, hasLength(3));
      expect(schedule[0].time, DateTime(2026, 3, 2));
      expect(schedule[0].title, 'JustOver30 expires in 30 days');
    });

    test('8 days away includes 7-day notification', () {
      final now = DateTime(2026, 3, 1);
      final expiry = DateTime(2026, 3, 9);

      final schedule = NotificationService.computeSchedule(
        cardName: 'JustOver7',
        expiryDate: expiry,
        now: now,
      );

      expect(schedule, hasLength(2));
      expect(schedule[0].time, DateTime(2026, 3, 2));
      expect(schedule[0].title, 'JustOver7 expires in 7 days');
    });
  });

  group('NotificationService.generateNotificationId', () {
    test('produces consistent IDs for same card and index', () {
      final id1 = NotificationService.generateNotificationId('card-abc', 0);
      final id2 = NotificationService.generateNotificationId('card-abc', 0);
      expect(id1, equals(id2));
    });

    test('produces different IDs for different indices', () {
      final id0 = NotificationService.generateNotificationId('card-abc', 0);
      final id1 = NotificationService.generateNotificationId('card-abc', 1);
      final id2 = NotificationService.generateNotificationId('card-abc', 2);
      expect({id0, id1, id2}, hasLength(3));
    });

    test('produces different IDs for different card IDs', () {
      final idA = NotificationService.generateNotificationId('card-a', 0);
      final idB = NotificationService.generateNotificationId('card-b', 0);
      expect(idA, isNot(equals(idB)));
    });
  });
}
