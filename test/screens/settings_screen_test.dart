// ABOUTME: Widget tests for SettingsScreen navigation rows.
// ABOUTME: Tests presence of export, import, and about options.

import 'package:card_stash/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('SettingsScreen', () {
    testWidgets('shows Settings title', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));

      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('shows Export cards row', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));

      expect(find.text('Export cards'), findsOneWidget);
    });

    testWidgets('shows Import cards row', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));

      expect(find.text('Import cards'), findsOneWidget);
    });

    testWidgets('shows About row', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));

      expect(find.text('About'), findsOneWidget);
    });

    testWidgets('all rows have chevron icons', (tester) async {
      await tester.pumpWidget(const MaterialApp(home: SettingsScreen()));

      expect(find.byIcon(Icons.chevron_right), findsNWidgets(3));
    });
  });
}
