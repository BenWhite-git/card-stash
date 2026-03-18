// ABOUTME: Widget tests for AboutScreen content, layout, and navigation.
// ABOUTME: Tests version display, legal rows, copyright, and dark theme.

import 'package:card_stash/screens/about_screen.dart';
import 'package:card_stash/theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:package_info_plus/package_info_plus.dart';

void main() {
  setUp(() {
    PackageInfo.setMockInitialValues(
      appName: 'Card Stash',
      packageName: 'co.benwhite.cardstash',
      version: '1.2.3',
      buildNumber: '1',
      buildSignature: '',
    );
  });

  Widget buildSubject() {
    return MaterialApp(theme: buildDarkTheme(), home: const AboutScreen());
  }

  group('AboutScreen', () {
    testWidgets('shows app name', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Card Stash'), findsOneWidget);
    });

    testWidgets('shows version from PackageInfo', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('1.2.3'), findsOneWidget);
    });

    testWidgets('shows description text', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(
        find.textContaining('loyalty and membership cards'),
        findsOneWidget,
      );
    });

    testWidgets('shows Ko-fi button', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.textContaining('Ko-fi'), findsOneWidget);
    });

    testWidgets('shows Privacy Policy row', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Privacy Policy'), findsOneWidget);
    });

    testWidgets('shows Open Source Licences row', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Open Source Licences'), findsOneWidget);
    });

    testWidgets('shows GitHub row', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('GitHub'), findsOneWidget);
    });

    testWidgets('shows MIT licence footer', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.text('Open source. MIT Licence.'), findsOneWidget);
    });

    testWidgets('shows copyright line', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.textContaining('2026 Ben White'), findsOneWidget);
    });

    testWidgets('shows app icon', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      final imageFinder = find.byWidgetPredicate(
        (widget) =>
            widget is Image &&
            widget.image is AssetImage &&
            (widget.image as AssetImage).assetName ==
                'assets/icon/app_icon_64.png',
      );
      expect(imageFinder, findsOneWidget);
    });

    testWidgets('legal rows have chevron icons', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.chevron_right), findsNWidgets(3));
    });

    testWidgets('scaffold uses dark theme background', (tester) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(Scaffold).last);
      final themeBackground = Theme.of(context).scaffoldBackgroundColor;
      expect(themeBackground, const Color(0xFF0F172A));
    });

    testWidgets('tapping Open Source Licences shows LicensePage', (
      tester,
    ) async {
      await tester.pumpWidget(buildSubject());
      await tester.pumpAndSettle();

      await tester.tap(find.text('Open Source Licences'));
      await tester.pumpAndSettle();

      expect(find.byType(LicensePage), findsOneWidget);
    });
  });
}
