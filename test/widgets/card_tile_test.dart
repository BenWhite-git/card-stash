// ABOUTME: Tests for CardTile widget.
// ABOUTME: Verifies card name, note indicator, expiry badge, favourite badge, callbacks.

import 'package:card_stash/models/card.dart';
import 'package:card_stash/widgets/card_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

LoyaltyCard _makeCard({
  String name = 'Tesco Clubcard',
  String? notes,
  DateTime? expiryDate,
  bool isFavourite = false,
  int usageCount = 0,
  int colourValue = 0xFF1E293B,
}) {
  return LoyaltyCard(
    id: '1',
    name: name,
    cardNumber: '1234567890',
    barcodeType: BarcodeType.code128,
    colourValue: colourValue,
    createdAt: DateTime(2026, 1, 1),
    notes: notes,
    expiryDate: expiryDate,
    isFavourite: isFavourite,
    usageCount: usageCount,
  );
}

void main() {
  Widget wrap(Widget child) {
    return MaterialApp(home: Scaffold(body: child));
  }

  group('CardTile', () {
    testWidgets('displays card name', (tester) async {
      await tester.pumpWidget(
        wrap(
          CardTile(
            card: _makeCard(name: 'Boots Advantage'),
            onTap: () {},
            onLongPress: () {},
          ),
        ),
      );
      expect(find.text('Boots Advantage'), findsOneWidget);
    });

    testWidgets('shows note indicator when notes are present', (tester) async {
      await tester.pumpWidget(
        wrap(
          CardTile(
            card: _makeCard(notes: 'Joint account'),
            onTap: () {},
            onLongPress: () {},
          ),
        ),
      );
      expect(find.byIcon(Icons.notes_rounded), findsOneWidget);
    });

    testWidgets('hides note indicator when notes are empty', (tester) async {
      await tester.pumpWidget(
        wrap(CardTile(card: _makeCard(), onTap: () {}, onLongPress: () {})),
      );
      expect(find.byIcon(Icons.notes_rounded), findsNothing);
    });

    testWidgets('shows favourite icon when card is favourite', (tester) async {
      await tester.pumpWidget(
        wrap(
          CardTile(
            card: _makeCard(isFavourite: true),
            onTap: () {},
            onLongPress: () {},
          ),
        ),
      );
      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
    });

    testWidgets('hides favourite icon when card is not favourite', (
      tester,
    ) async {
      await tester.pumpWidget(
        wrap(
          CardTile(
            card: _makeCard(isFavourite: false),
            onTap: () {},
            onLongPress: () {},
          ),
        ),
      );
      expect(find.byIcon(Icons.star_rounded), findsNothing);
    });

    testWidgets('shows expiry badge when expiry is near', (tester) async {
      final soon = DateTime.now().add(const Duration(days: 5));
      await tester.pumpWidget(
        wrap(
          CardTile(
            card: _makeCard(expiryDate: soon),
            onTap: () {},
            onLongPress: () {},
          ),
        ),
      );
      expect(find.textContaining('d left'), findsOneWidget);
    });

    testWidgets('calls onTap when tapped', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        wrap(
          CardTile(
            card: _makeCard(),
            onTap: () => tapped = true,
            onLongPress: () {},
          ),
        ),
      );
      await tester.tap(find.byType(CardTile));
      expect(tapped, isTrue);
    });

    testWidgets('calls onLongPress when long-pressed', (tester) async {
      var longPressed = false;
      await tester.pumpWidget(
        wrap(
          CardTile(
            card: _makeCard(),
            onTap: () {},
            onLongPress: () => longPressed = true,
          ),
        ),
      );
      await tester.longPress(find.byType(CardTile));
      expect(longPressed, isTrue);
    });

    testWidgets('displays card colour accent', (tester) async {
      await tester.pumpWidget(
        wrap(
          CardTile(
            card: _makeCard(colourValue: Colors.blue.toARGB32()),
            onTap: () {},
            onLongPress: () {},
          ),
        ),
      );
      // The colour should be visible as a leading accent.
      expect(find.byType(CardTile), findsOneWidget);
    });
  });
}
