// ABOUTME: Widget tests for ExportScreen passphrase entry and validation.
// ABOUTME: Tests warning text, field validation, button states, and export flow.

import 'package:card_stash/screens/export_screen.dart';
import 'package:card_stash/services/export_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/stub_export_service.dart';

void main() {
  late StubExportService stubExport;

  setUp(() {
    stubExport = StubExportService();
  });

  Widget buildExportScreen() {
    return ProviderScope(
      overrides: [exportServiceProvider.overrideWithValue(stubExport)],
      child: MaterialApp(
        theme: ThemeData(brightness: Brightness.dark),
        home: Navigator(
          onGenerateRoute: (_) =>
              MaterialPageRoute(builder: (context) => const ExportScreen()),
        ),
      ),
    );
  }

  group('ExportScreen', () {
    testWidgets('shows warning text about passphrase', (tester) async {
      await tester.pumpWidget(buildExportScreen());

      expect(find.textContaining('need this passphrase'), findsOneWidget);
    });

    testWidgets('shows two passphrase fields', (tester) async {
      await tester.pumpWidget(buildExportScreen());

      expect(find.byType(TextField), findsNWidgets(2));
    });

    testWidgets('export button disabled when fields empty', (tester) async {
      await tester.pumpWidget(buildExportScreen());

      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Export'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('export button disabled when passphrases do not match', (
      tester,
    ) async {
      await tester.pumpWidget(buildExportScreen());

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'password123');
      await tester.enterText(fields.at(1), 'different99');
      await tester.pump();

      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Export'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('export button disabled when passphrase too short', (
      tester,
    ) async {
      await tester.pumpWidget(buildExportScreen());

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'short');
      await tester.enterText(fields.at(1), 'short');
      await tester.pump();

      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Export'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets(
      'export button enabled when passphrases match and long enough',
      (tester) async {
        await tester.pumpWidget(buildExportScreen());

        final fields = find.byType(TextField);
        await tester.enterText(fields.at(0), 'validpass');
        await tester.enterText(fields.at(1), 'validpass');
        await tester.pump();

        final button = tester.widget<ElevatedButton>(
          find.widgetWithText(ElevatedButton, 'Export'),
        );
        expect(button.onPressed, isNotNull);
      },
    );

    testWidgets('shows mismatch error when passphrases differ', (tester) async {
      await tester.pumpWidget(buildExportScreen());

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'password123');
      await tester.enterText(fields.at(1), 'differentpass');
      await tester.pump();

      expect(find.textContaining('do not match'), findsOneWidget);
    });

    testWidgets('shows minimum length hint when too short', (tester) async {
      await tester.pumpWidget(buildExportScreen());

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'short');
      await tester.enterText(fields.at(1), 'short');
      await tester.pump();

      expect(find.textContaining('at least 8'), findsOneWidget);
    });

    testWidgets('triggers export on button tap', (tester) async {
      await tester.pumpWidget(buildExportScreen());

      final fields = find.byType(TextField);
      await tester.enterText(fields.at(0), 'validpass');
      await tester.enterText(fields.at(1), 'validpass');
      await tester.pump();

      // Tap the button, then let the async export complete.
      await tester.tap(find.widgetWithText(ElevatedButton, 'Export'));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();

      expect(stubExport.calls, contains('buildExportFile:validpass'));
    });
  });
}
