// ABOUTME: App info screen with version, Ko-fi link, licences, and attribution.
// ABOUTME: Follows Ben White app portfolio pattern with always-light theme.

import 'package:flutter/material.dart';

class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'About — coming in Phase 8',
          style: TextStyle(fontSize: 16, color: Color(0xFF94A3B8)),
        ),
      ),
    );
  }
}
