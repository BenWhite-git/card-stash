// ABOUTME: Placeholder screen for the Alerts tab.
// ABOUTME: Will show expiry notifications and alerts in Phase 6.

import 'package:flutter/material.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(
        child: Text(
          'Alerts coming soon',
          style: TextStyle(fontSize: 16, color: Color(0xFF94A3B8)),
        ),
      ),
    );
  }
}
