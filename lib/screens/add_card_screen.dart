// ABOUTME: Screen for adding a new card via camera scan or manual entry.
// ABOUTME: Includes payment card rejection via Luhn + BIN detection.

import 'package:flutter/material.dart';

class AddCardScreen extends StatelessWidget {
  const AddCardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add Card')),
      body: const Center(
        child: Text(
          'Add Card — coming in Phase 4',
          style: TextStyle(fontSize: 16, color: Color(0xFF94A3B8)),
        ),
      ),
    );
  }
}
