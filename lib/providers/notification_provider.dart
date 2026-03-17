// ABOUTME: Riverpod provider wrapping NotificationService.
// ABOUTME: Exposes notification scheduling and cancellation for card expiry.

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../services/notification_service.dart';

final notificationServiceProvider = Provider<NotificationService>((ref) {
  return NotificationService(FlutterLocalNotificationsPlugin());
});
