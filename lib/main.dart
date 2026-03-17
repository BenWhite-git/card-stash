// ABOUTME: App entry point for Card Stash.
// ABOUTME: Initialises encrypted storage and SharedPreferences before launch.

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;

import 'providers/first_launch_provider.dart';
import 'providers/notification_provider.dart';
import 'router.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  tz.initializeTimeZones();

  final storageService = await StorageService.init();
  final sharedPreferences = await SharedPreferences.getInstance();
  final notificationService = NotificationService(
    FlutterLocalNotificationsPlugin(),
  );
  await notificationService.init();
  final isFirstLaunch =
      !(sharedPreferences.getBool('first_launch_completed') ?? false);

  runApp(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storageService),
        notificationServiceProvider.overrideWithValue(notificationService),
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: CardStashApp(isFirstLaunch: isFirstLaunch),
    ),
  );
}

class CardStashApp extends StatelessWidget {
  final bool isFirstLaunch;

  const CardStashApp({super.key, this.isFirstLaunch = false});

  @override
  Widget build(BuildContext context) {
    return MaterialApp.router(
      title: 'Card Stash',
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F172A),
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFF59E0B),
          brightness: Brightness.dark,
          surface: const Color(0xFF0F172A),
        ),
        navigationBarTheme: NavigationBarThemeData(
          backgroundColor: const Color(0xFF1E293B),
          indicatorColor: const Color(0xFFF59E0B).withValues(alpha: 0.15),
          labelTextStyle: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0xFFF59E0B),
              );
            }
            return const TextStyle(fontSize: 12, color: Color(0xFF94A3B8));
          }),
          iconTheme: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const IconThemeData(color: Color(0xFFF59E0B));
            }
            return const IconThemeData(color: Color(0xFF94A3B8));
          }),
        ),
        useMaterial3: true,
      ),
      routerConfig: createRouter(isFirstLaunch: isFirstLaunch),
    );
  }
}
