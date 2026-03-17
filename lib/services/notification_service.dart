// ABOUTME: Local notification scheduling for card expiry reminders.
// ABOUTME: Schedules at 30 days, 7 days, and expiry day; handles iOS permission.

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

import '../models/card.dart';

/// A single scheduled notification with its computed time and message.
class ScheduledNotification {
  final DateTime time;
  final String title;
  final String body;

  const ScheduledNotification({
    required this.time,
    required this.title,
    required this.body,
  });
}

class NotificationService {
  final FlutterLocalNotificationsPlugin _plugin;

  NotificationService(this._plugin);

  static const _channelId = 'card_expiry';
  static const _channelName = 'Card expiry reminders';
  static const _channelDescription =
      'Notifications when your loyalty cards are about to expire';

  /// Initializes the notification plugin with platform-specific settings.
  Future<void> init() async {
    const androidSettings = AndroidInitializationSettings(
      '@mipmap/ic_launcher',
    );
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _plugin.initialize(settings);
  }

  /// Requests notification permission on iOS. Returns true if granted.
  Future<bool> requestPermission() async {
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      final granted = await ios.requestPermissions(
        alert: true,
        badge: true,
        sound: true,
      );
      return granted ?? false;
    }

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      final granted = await android.requestNotificationsPermission();
      return granted ?? true;
    }

    return true;
  }

  /// Checks whether notifications are currently permitted without requesting.
  Future<bool> areNotificationsEnabled() async {
    final ios = _plugin
        .resolvePlatformSpecificImplementation<
          IOSFlutterLocalNotificationsPlugin
        >();
    if (ios != null) {
      final permissions = await ios.checkPermissions();
      return permissions?.isEnabled ?? false;
    }

    final android = _plugin
        .resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin
        >();
    if (android != null) {
      final enabled = await android.areNotificationsEnabled();
      return enabled ?? true;
    }

    return true;
  }

  /// Computes notification schedule for a card expiry. Pure logic, no side effects.
  ///
  /// Schedules up to 3 notifications: 30 days before, 7 days before, expiry day.
  /// Skips any that are not in the future relative to [now].
  static List<ScheduledNotification> computeSchedule({
    required String cardName,
    required DateTime expiryDate,
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();
    final expiry = DateTime(expiryDate.year, expiryDate.month, expiryDate.day);
    final today = DateTime(
      currentTime.year,
      currentTime.month,
      currentTime.day,
    );

    if (!expiry.isAfter(today)) return [];

    final triggers = <ScheduledNotification>[];

    final thirtyDaysBefore = DateTime(
      expiry.year,
      expiry.month,
      expiry.day - 30,
    );
    if (thirtyDaysBefore.isAfter(today)) {
      triggers.add(
        ScheduledNotification(
          time: thirtyDaysBefore,
          title: '$cardName expires in 30 days',
          body: 'Your $cardName expires in 30 days',
        ),
      );
    }

    final sevenDaysBefore = DateTime(expiry.year, expiry.month, expiry.day - 7);
    if (sevenDaysBefore.isAfter(today)) {
      triggers.add(
        ScheduledNotification(
          time: sevenDaysBefore,
          title: '$cardName expires in 7 days',
          body: 'Your $cardName expires in 7 days',
        ),
      );
    }

    triggers.add(
      ScheduledNotification(
        time: expiry,
        title: '$cardName expired today',
        body: 'Your $cardName expired today \u2014 update or remove it',
      ),
    );

    return triggers;
  }

  /// Generates a deterministic notification ID from a card ID and index.
  static int generateNotificationId(String cardId, int index) {
    // Use hashCode + index offset, clamped to 32-bit positive int range.
    return (cardId.hashCode + index).abs() % 2147483647;
  }

  /// Schedules expiry notifications for a card. Returns the notification IDs.
  ///
  /// If the card has no expiry date, returns an empty list.
  /// Requests permission on first call (iOS).
  Future<List<int>> scheduleCardNotifications(LoyaltyCard card) async {
    if (card.expiryDate == null) return [];

    final schedule = computeSchedule(
      cardName: card.name,
      expiryDate: card.expiryDate!,
    );

    if (schedule.isEmpty) return [];

    await requestPermission();

    final ids = <int>[];

    for (var i = 0; i < schedule.length; i++) {
      final notification = schedule[i];
      final id = generateNotificationId(card.id, i);
      ids.add(id);

      final scheduledDate = tz.TZDateTime.from(
        DateTime(
          notification.time.year,
          notification.time.month,
          notification.time.day,
          9, // 9:00 AM local time.
        ),
        tz.local,
      );

      await _plugin.zonedSchedule(
        id,
        notification.title,
        notification.body,
        scheduledDate,
        const NotificationDetails(
          android: AndroidNotificationDetails(
            _channelId,
            _channelName,
            channelDescription: _channelDescription,
            importance: Importance.defaultImportance,
            priority: Priority.defaultPriority,
          ),
          iOS: DarwinNotificationDetails(),
        ),
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
      );
    }

    return ids;
  }

  /// Cancels all notifications for a card using its stored notification IDs.
  Future<void> cancelCardNotifications(LoyaltyCard card) async {
    final ids = card.notificationIds;
    if (ids == null) return;
    for (final id in ids) {
      await _plugin.cancel(id);
    }
  }

  /// Cancels all scheduled notifications. Used for full data wipe.
  Future<void> cancelAllNotifications() async {
    await _plugin.cancelAll();
  }
}
