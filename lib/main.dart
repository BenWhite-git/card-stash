// ABOUTME: App entry point for Card Stash.
// ABOUTME: Initialises encrypted storage and SharedPreferences before launch.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'providers/first_launch_provider.dart';
import 'services/storage_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final storageService = await StorageService.init();
  final sharedPreferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      overrides: [
        storageServiceProvider.overrideWithValue(storageService),
        sharedPreferencesProvider.overrideWithValue(sharedPreferences),
      ],
      child: const CardStashApp(),
    ),
  );
}

class CardStashApp extends StatelessWidget {
  const CardStashApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Card Stash',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.amber),
        useMaterial3: true,
      ),
      home: const Scaffold(body: Center(child: Text('Card Stash'))),
    );
  }
}
