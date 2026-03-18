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
import 'theme.dart';

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

class CardStashApp extends ConsumerWidget {
  final bool isFirstLaunch;

  const CardStashApp({super.key, this.isFirstLaunch = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'Card Stash',
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: themeMode,
      routerConfig: createRouter(isFirstLaunch: isFirstLaunch),
    );
  }
}
