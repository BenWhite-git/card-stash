// ABOUTME: Widget tests for SettingsScreen navigation rows.
// ABOUTME: Tests presence of appearance, export, import, and about options.

import 'package:card_stash/providers/first_launch_provider.dart';
import 'package:card_stash/screens/settings_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late SharedPreferences prefs;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    prefs = await SharedPreferences.getInstance();
  });

  Widget buildSubject() {
    return ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(prefs)],
      child: const MaterialApp(home: SettingsScreen()),
    );
  }

  group('SettingsScreen', () {
    testWidgets('shows Settings title', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('Settings'), findsOneWidget);
    });

    testWidgets('shows Appearance row', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('Appearance'), findsOneWidget);
    });

    testWidgets('shows Export cards row', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('Export cards'), findsOneWidget);
    });

    testWidgets('shows Import cards row', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('Import cards'), findsOneWidget);
    });

    testWidgets('shows About row', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.text('About'), findsOneWidget);
    });

    testWidgets('all rows have chevron icons', (tester) async {
      await tester.pumpWidget(buildSubject());

      expect(find.byIcon(Icons.chevron_right), findsNWidgets(4));
    });
  });
}
