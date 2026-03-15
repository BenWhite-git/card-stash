// ABOUTME: Smoke test for the Card Stash app.
// ABOUTME: Verifies the app launches and renders without errors.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:card_stash/main.dart';

void main() {
  testWidgets('App renders Card Stash text', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: CardStashApp()));
    expect(find.text('Card Stash'), findsOneWidget);
  });
}
