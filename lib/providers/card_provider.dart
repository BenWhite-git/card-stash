// ABOUTME: Riverpod providers for card CRUD operations.
// ABOUTME: Watches encrypted Hive box and exposes sorted, filterable card list.

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';

import '../models/card.dart';
import '../providers/notification_provider.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';

/// Sort mode for the card list.
enum CardSortMode { mostUsed, alphabetical, recentlyUsed, dateAdded }

/// Provider for the current sort mode.
final cardSortModeProvider =
    NotifierProvider<CardSortModeNotifier, CardSortMode>(
      CardSortModeNotifier.new,
    );

class CardSortModeNotifier extends Notifier<CardSortMode> {
  @override
  CardSortMode build() => CardSortMode.mostUsed;

  void setMode(CardSortMode mode) => state = mode;
}

final cardListProvider = NotifierProvider<CardListNotifier, List<LoyaltyCard>>(
  CardListNotifier.new,
);

class CardListNotifier extends Notifier<List<LoyaltyCard>> {
  Box<LoyaltyCard> get _box => ref.read(storageServiceProvider).box;
  NotificationService get _notifications =>
      ref.read(notificationServiceProvider);

  @override
  List<LoyaltyCard> build() {
    ref.watch(cardSortModeProvider);
    return _sortedCards();
  }

  List<LoyaltyCard> _sortedCards() {
    final cards = _box.values.toList();
    final sortMode = ref.read(cardSortModeProvider);
    cards.sort((a, b) {
      // Favourites always pinned to top.
      if (a.isFavourite && !b.isFavourite) return -1;
      if (!a.isFavourite && b.isFavourite) return 1;
      // Then by selected sort mode.
      return switch (sortMode) {
        CardSortMode.mostUsed => b.usageCount.compareTo(a.usageCount),
        CardSortMode.alphabetical => a.name.toLowerCase().compareTo(
          b.name.toLowerCase(),
        ),
        CardSortMode.recentlyUsed => (b.lastUsed ?? DateTime(0)).compareTo(
          a.lastUsed ?? DateTime(0),
        ),
        CardSortMode.dateAdded => b.createdAt.compareTo(a.createdAt),
      };
    });
    return cards;
  }

  void _refresh() {
    state = _sortedCards();
  }

  /// Persists notification IDs on a card without triggering rescheduling.
  Future<void> _persistNotificationIds(String cardId, List<int> ids) async {
    final card = _box.get(cardId);
    if (card == null) return;
    card.notificationIds = ids;
    await card.save();
  }

  Future<void> addCard(LoyaltyCard card) async {
    await _box.put(card.id, card);

    if (card.expiryDate != null) {
      final ids = await _notifications.scheduleCardNotifications(card);
      if (ids.isNotEmpty) {
        await _persistNotificationIds(card.id, ids);
      }
    }

    _refresh();
  }

  Future<void> updateCard(LoyaltyCard card) async {
    // Cancel existing notifications before rescheduling.
    final existing = _box.get(card.id);
    if (existing != null) {
      await _notifications.cancelCardNotifications(existing);
    }

    await _box.put(card.id, card);

    if (card.expiryDate != null) {
      final ids = await _notifications.scheduleCardNotifications(card);
      await _persistNotificationIds(card.id, ids);
    } else {
      await _persistNotificationIds(card.id, []);
    }

    _refresh();
  }

  Future<void> deleteCard(String id) async {
    final card = _box.get(id);
    if (card != null) {
      await _notifications.cancelCardNotifications(card);
    }

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
