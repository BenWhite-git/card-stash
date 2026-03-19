// ABOUTME: Widget tests for ImportScreen file picker, passphrase, and mode selection.
// ABOUTME: Tests UI states, validation, import flow, and error display.

import 'package:card_stash/screens/import_screen.dart';
import 'package:card_stash/services/file_picker_service.dart';
import 'package:card_stash/services/import_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/stub_import_service.dart';

class FakeFilePickerService implements FilePickerService {
  String? pathToReturn;

  @override
  Future<String?> pickCardstashFile() async => pathToReturn;
}

void main() {
  late StubImportService stubImport;
  late FakeFilePickerService fakePicker;

  setUp(() {
    stubImport = StubImportService();
    fakePicker = FakeFilePickerService();
  });

  Widget buildImportScreen() {
    return ProviderScope(
      overrides: [
        importServiceProvider.overrideWithValue(stubImport),
        filePickerServiceProvider.overrideWithValue(fakePicker),
      ],
      child: MaterialApp(
        theme: ThemeData(brightness: Brightness.dark),
        home: Navigator(
          onGenerateRoute: (_) =>
              MaterialPageRoute(builder: (context) => const ImportScreen()),
        ),
      ),
    );
  }

  group('ImportScreen', () {
    testWidgets('shows file picker button initially', (tester) async {
      await tester.pumpWidget(buildImportScreen());

      expect(find.textContaining('Select file'), findsOneWidget);
    });

    testWidgets('shows passphrase field after file selected', (tester) async {
      fakePicker.pathToReturn = '/tmp/test.cardstash';
      await tester.pumpWidget(buildImportScreen());

      await tester.tap(find.textContaining('Select file'));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();

      expect(find.byType(TextField), findsOneWidget);
    });

    testWidgets('shows import mode choice after file selected', (tester) async {
      fakePicker.pathToReturn = '/tmp/test.cardstash';
      await tester.pumpWidget(buildImportScreen());

      await tester.tap(find.textContaining('Select file'));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();

      expect(find.text('Replace all'), findsOneWidget);
      expect(find.text('Merge'), findsOneWidget);
    });

    testWidgets('import button disabled until passphrase entered', (
      tester,
    ) async {
      fakePicker.pathToReturn = '/tmp/test.cardstash';
      await tester.pumpWidget(buildImportScreen());

      await tester.tap(find.textContaining('Select file'));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();

      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Import'),
      );
      expect(button.onPressed, isNull);
    });

    testWidgets('import button enabled when passphrase entered', (
      tester,
    ) async {
      fakePicker.pathToReturn = '/tmp/test.cardstash';
      await tester.pumpWidget(buildImportScreen());

      await tester.tap(find.textContaining('Select file'));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();

      await tester.enterText(find.byType(TextField), 'mypassphrase');
      await tester.pump();

      final button = tester.widget<ElevatedButton>(
        find.widgetWithText(ElevatedButton, 'Import'),
      );
      expect(button.onPressed, isNotNull);
    });

    testWidgets('shows result after successful import', (tester) async {
      fakePicker.pathToReturn = '/tmp/test.cardstash';
      stubImport.resultToReturn = const ImportResult(
        totalCards: 5,
        importedCards: 5,
        skippedDuplicates: 0,
        skippedPaymentCards: 0,
      );
      await tester.pumpWidget(buildImportScreen());

      // Select file.
      await tester.tap(find.textContaining('Select file'));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();

      // Enter passphrase.
      await tester.enterText(find.byType(TextField), 'mypassphrase');
      await tester.pump();

      // Tap import.
      await tester.tap(find.widgetWithText(ElevatedButton, 'Import'));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();

      expect(find.textContaining('5 cards imported'), findsOneWidget);
    });

    testWidgets('shows error on wrong passphrase', (tester) async {
      fakePicker.pathToReturn = '/tmp/test.cardstash';
      stubImport.exceptionToThrow = const ImportSignatureException(
        'Wrong passphrase or corrupted file.',
      );
      await tester.pumpWidget(buildImportScreen());

      // Select file.
      await tester.tap(find.textContaining('Select file'));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();

      // Enter passphrase.
      await tester.enterText(find.byType(TextField), 'wrongpass');
      await tester.pump();

      // Tap import.
      await tester.tap(find.widgetWithText(ElevatedButton, 'Import'));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();

      expect(find.textContaining('Wrong passphrase'), findsOneWidget);
    });

    testWidgets('shows merge result with skipped duplicates', (tester) async {
      fakePicker.pathToReturn = '/tmp/test.cardstash';
      stubImport.resultToReturn = const ImportResult(
        totalCards: 5,
        importedCards: 3,
        skippedDuplicates: 2,
        skippedPaymentCards: 0,
      );
      await tester.pumpWidget(buildImportScreen());

      // Select file.
      await tester.tap(find.textContaining('Select file'));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();

      // Switch to merge mode.
      await tester.tap(find.text('Merge'));
      await tester.pump();

      // Enter passphrase.
      await tester.enterText(find.byType(TextField), 'mypassphrase');
      await tester.pump();

      // Tap import.
      await tester.tap(find.widgetWithText(ElevatedButton, 'Import'));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();

      expect(find.textContaining('3 cards imported'), findsOneWidget);
      expect(find.textContaining('2 duplicates skipped'), findsOneWidget);
    });

    testWidgets('no file selected does nothing', (tester) async {
      fakePicker.pathToReturn = null; // User cancelled.
      await tester.pumpWidget(buildImportScreen());

      await tester.tap(find.textContaining('Select file'));
      await tester.runAsync(() => Future<void>.delayed(Duration.zero));
      await tester.pump();

      // Should still show file picker, no passphrase field.
      expect(find.textContaining('Select file'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
    });
  });
}
