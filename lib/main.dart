// ABOUTME: App entry point for Card Stash.
// ABOUTME: Initialises the Flutter app with Riverpod and Material theme.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

void main() {
  runApp(const ProviderScope(child: CardStashApp()));
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
