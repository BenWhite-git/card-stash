// ABOUTME: Riverpod providers for card CRUD operations.
// ABOUTME: Watches encrypted Hive box and exposes sorted, filterable card list.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';

import '../models/card.dart';
import '../services/storage_service.dart';

final cardListProvider = NotifierProvider<CardListNotifier, List<LoyaltyCard>>(
  CardListNotifier.new,
);

class CardListNotifier extends Notifier<List<LoyaltyCard>> {
  Box<LoyaltyCard> get _box => ref.read(storageServiceProvider).box;

  @override
  List<LoyaltyCard> build() {
    return _sortedCards();
  }

  List<LoyaltyCard> _sortedCards() {
    final cards = _box.values.toList();
    cards.sort((a, b) {
      // Favourites pinned to top.
      if (a.isFavourite && !b.isFavourite) return -1;
      if (!a.isFavourite && b.isFavourite) return 1;
      // Then by usage count descending.
      return b.usageCount.compareTo(a.usageCount);
    });
    return cards;
  }

  void _refresh() {
    state = _sortedCards();
  }

  Future<void> addCard(LoyaltyCard card) async {
    await _box.put(card.id, card);
    _refresh();
  }

  Future<void> updateCard(LoyaltyCard card) async {
    await _box.put(card.id, card);
    _refresh();
  }

  Future<void> deleteCard(String id) async {
    await _box.delete(id);
    _refresh();
  }

  Future<void> incrementUsage(String id) async {
    final card = _box.get(id);
    if (card == null) return;
    card.usageCount++;
    card.lastUsed = DateTime.now();
    await card.save();
    _refresh();
  }
}
