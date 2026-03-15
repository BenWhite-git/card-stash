// ABOUTME: Tests for ExpiryBadge widget.
// ABOUTME: Verifies correct colour and text for various expiry timeframes.

import 'package:card_stash/widgets/expiry_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Returns a local DateTime N calendar days from today at midnight.
DateTime _daysFromToday(int days) {
  final now = DateTime.now();
  // Use UTC addition then convert back to local to get exact calendar days.
  final utc = DateTime.utc(now.year, now.month, now.day + days);
  return DateTime(utc.year, utc.month, utc.day);
}

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('ExpiryBadge', () {
    testWidgets('returns empty when expiryDate is null', (tester) async {
      await tester.pumpWidget(wrap(const ExpiryBadge(expiryDate: null)));
      expect(find.byType(SizedBox), findsOneWidget);
    });

    testWidgets('returns nothing when expiry is more than 30 days away', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(ExpiryBadge(expiryDate: _daysFromToday(60))),
      );
      expect(find.text('Expired'), findsNothing);
      expect(find.textContaining('d left'), findsNothing);
    });

    testWidgets('shows amber badge when expiry is 30 days away', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(ExpiryBadge(expiryDate: _daysFromToday(30))),
      );
      expect(find.text('30d left'), findsOneWidget);
    });

    testWidgets('shows amber badge when expiry is 15 days away', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(ExpiryBadge(expiryDate: _daysFromToday(15))),
      );
      expect(find.text('15d left'), findsOneWidget);
    });

    testWidgets('shows red badge when expiry is 7 days away', (tester) async {
      await tester.pumpWidget(wrap(ExpiryBadge(expiryDate: _daysFromToday(7))));
      expect(find.text('7d left'), findsOneWidget);
    });

    testWidgets('shows red badge when expiry is 1 day away', (tester) async {
      await tester.pumpWidget(wrap(ExpiryBadge(expiryDate: _daysFromToday(1))));
      expect(find.text('1d left'), findsOneWidget);
    });

    testWidgets('shows expired badge when expiry is in the past', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(ExpiryBadge(expiryDate: _daysFromToday(-5))),
      );
      expect(find.text('Expired'), findsOneWidget);
    });

    testWidgets('shows expired badge when expiry is today', (tester) async {
      await tester.pumpWidget(wrap(ExpiryBadge(expiryDate: _daysFromToday(0))));
      expect(find.text('Expired'), findsOneWidget);
    });

    testWidgets('amber badge has amber colour scheme', (tester) async {
      await tester.pumpWidget(
        wrap(ExpiryBadge(expiryDate: _daysFromToday(20))),
      );
      final text = tester.widget<Text>(find.text('20d left'));
      expect(text.style?.color, const Color(0xFFF59E0B));
    });

    testWidgets('red badge has red colour scheme', (tester) async {
      await tester.pumpWidget(wrap(ExpiryBadge(expiryDate: _daysFromToday(3))));
      final text = tester.widget<Text>(find.text('3d left'));
      expect(text.style?.color, const Color(0xFFEF4444));
    });
  });
}
