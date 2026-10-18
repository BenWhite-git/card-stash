// ABOUTME: App entry point for Card Stash.
// ABOUTME: Initialises encrypted storage, preferences and notifications in parallel before launch.

import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'providers/first_launch_provider.dart';
import 'providers/notification_provider.dart';
import 'router.dart';
import 'services/notification_service.dart';
import 'services/storage_service.dart';
import 'theme.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final notificationService = NotificationService(
    FlutterLocalNotificationsPlugin(),
  );

  // The three initialisations touch independent platform channels, so they
  // run concurrently to keep the time before first frame as short as possible.
  final storageFuture = StorageService.init();
  final prefsFuture = SharedPreferences.getInstance();
  final notificationsFuture = notificationService.init();

  final storageService = await storageFuture;
  final sharedPreferences = await prefsFuture;
  await notificationsFuture;

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

class CardStashApp extends ConsumerStatefulWidget {
  final bool isFirstLaunch;

  const CardStashApp({super.key, this.isFirstLaunch = false});

  @override
  ConsumerState<CardStashApp> createState() => _CardStashAppState();
}

class _CardStashAppState extends ConsumerState<CardStashApp> {
  // Created once so theme changes rebuild the app without resetting
  // navigation state.
  late final GoRouter _router = createRouter(
    isFirstLaunch: widget.isFirstLaunch,
  );

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);
    return MaterialApp.router(
      title: 'Card Stash',
      theme: buildLightTheme(),
      darkTheme: buildDarkTheme(),
      themeMode: themeMode,
      routerConfig: _router,
    );
  }
}
