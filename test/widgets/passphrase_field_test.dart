// ABOUTME: Widget tests for PassphraseField secure text input.
// ABOUTME: Tests obscured text, visibility toggle, onChanged, and error display.

import 'package:card_stash/widgets/passphrase_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget wrap(Widget child) {
  return MaterialApp(home: Scaffold(body: child));
}

void main() {
  group('PassphraseField', () {
    testWidgets('renders with label text', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrap(PassphraseField(labelText: 'Enter passphrase', onChanged: (_) {})),
      );

      expect(find.text('Enter passphrase'), findsOneWidget);
    });

    testWidgets('text is obscured by default', (WidgetTester tester) async {
      await tester.pumpWidget(
        wrap(PassphraseField(labelText: 'Password', onChanged: (_) {})),
      );

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.obscureText, isTrue);
    });

    testWidgets('toggle button shows and hides text', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap(PassphraseField(labelText: 'Password', onChanged: (_) {})),
      );

      // Initially obscured.
      var textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.obscureText, isTrue);

      // Tap toggle to show.
      await tester.tap(find.byIcon(Icons.visibility_outlined));
      await tester.pump();

      textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.obscureText, isFalse);

      // Tap toggle to hide again.
      await tester.tap(find.byIcon(Icons.visibility_off_outlined));
      await tester.pump();

      textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.obscureText, isTrue);
    });

    testWidgets('onChanged fires on input', (WidgetTester tester) async {
      String? captured;
      await tester.pumpWidget(
        wrap(
          PassphraseField(
            labelText: 'Password',
            onChanged: (value) => captured = value,
          ),
        ),
      );

      await tester.enterText(find.byType(TextField), 'my-secret');
      expect(captured, 'my-secret');
    });

    testWidgets('displays error text when provided', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          PassphraseField(
            labelText: 'Password',
            onChanged: (_) {},
            errorText: 'Passphrases do not match',
          ),
        ),
      );

      expect(find.text('Passphrases do not match'), findsOneWidget);
    });

    testWidgets('does not display error text when null', (
      WidgetTester tester,
    ) async {
      await tester.pumpWidget(
        wrap(PassphraseField(labelText: 'Password', onChanged: (_) {})),
      );

      // Only the label text should be present, no error.
      expect(find.text('Password'), findsOneWidget);
    });
  });
}
