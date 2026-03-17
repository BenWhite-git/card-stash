// ABOUTME: Stub NotificationService for tests that need CardProvider.
// ABOUTME: Records calls without touching platform channels.

import 'package:card_stash/models/card.dart';
import 'package:card_stash/services/notification_service.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class StubNotificationService extends NotificationService {
  final List<String> calls = [];

  StubNotificationService() : super(FlutterLocalNotificationsPlugin());

  @override
  Future<List<int>> scheduleCardNotifications(LoyaltyCard card) async {
    calls.add('schedule:${card.id}');
    if (card.expiryDate == null) return [];
    final schedule = NotificationService.computeSchedule(
      cardName: card.name,
      expiryDate: card.expiryDate!,
    );
    return List.generate(
      schedule.length,
      (i) => NotificationService.generateNotificationId(card.id, i),
    );
  }

  @override
  Future<void> cancelCardNotifications(LoyaltyCard card) async {
    calls.add('cancel:${card.id}');
  }

  @override
  Future<void> cancelAllNotifications() async {
    calls.add('cancelAll');
  }

  @override
  Future<bool> requestPermission() async => true;

  @override
  Future<bool> areNotificationsEnabled() async => true;
}
