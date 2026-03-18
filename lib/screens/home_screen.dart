// ABOUTME: Main card list screen with search, sorting, and long-press actions.
// ABOUTME: Favourites pinned to top, remaining sorted by usage count descending.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/card.dart';
import '../providers/card_provider.dart';
import '../theme.dart';
import '../widgets/card_form_fields.dart';
import '../widgets/card_tile.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

const _sortModeLabels = {
  CardSortMode.mostUsed: 'Most used',
  CardSortMode.alphabetical: 'A-Z',
  CardSortMode.recentlyUsed: 'Recently used',
  CardSortMode.dateAdded: 'Newest first',
};

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _searchQuery = '';

  void _showSortOptions() {
    final currentSort = ref.read(cardSortModeProvider);
    final colors = context.colors;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Sort by',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Divider(color: colors.border),
            for (final mode in CardSortMode.values)
              ListTile(
                leading: Icon(
                  mode == currentSort
                      ? Icons.radio_button_checked
                      : Icons.radio_button_unchecked,
                  color: mode == currentSort ? colors.accent : colors.textMuted,
                ),
                title: Text(
                  _sortModeLabels[mode]!,
                  style: TextStyle(
                    color: mode == currentSort
                        ? colors.accent
                        : colors.textPrimary,
                  ),
                ),
                onTap: () {
                  ref.read(cardSortModeProvider.notifier).setMode(mode);
                  Navigator.pop(sheetContext);
                },
              ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  List<LoyaltyCard> _filteredCards(List<LoyaltyCard> cards) {
    if (_searchQuery.isEmpty) return cards;
    final query = _searchQuery.toLowerCase();
    return cards.where((card) {
      return card.name.toLowerCase().contains(query) ||
          (card.issuer?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  void _showCardActions(BuildContext context, LoyaltyCard card) {
    final colors = context.colors;
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: colors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (sheetContext) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.textMuted,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              card.name,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Divider(color: colors.border),
            _ActionTile(
              icon: Icons.edit_outlined,
              label: 'Edit',
              onTap: () {
                Navigator.pop(sheetContext);
                context.push('/cards/${card.id}/edit');
              },
            ),
            _ActionTile(
              icon: card.isFavourite
                  ? Icons.star_rounded
                  : Icons.star_outline_rounded,
              label: card.isFavourite
                  ? 'Remove from favourites'
                  : 'Add to favourites',
              onTap: () {
                Navigator.pop(sheetContext);
                _toggleFavourite(card);
              },
            ),
            _ActionTile(
              icon: Icons.delete_outline,
              label: 'Delete',
              isDestructive: true,
              onTap: () {
                Navigator.pop(sheetContext);
                _confirmDelete(card);
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  void _toggleFavourite(LoyaltyCard card) {
    final updated = card.copyWith(isFavourite: !card.isFavourite);
    ref.read(cardListProvider.notifier).updateCard(updated);
  }

  Future<void> _confirmDelete(LoyaltyCard card) async {
    final confirmed = await confirmDeleteDialog(context, card.name);
    if (confirmed && mounted) {
      ref.read(cardListProvider.notifier).deleteCard(card.id);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cards = ref.watch(cardListProvider);
    final filtered = _filteredCards(cards);
    final favourites = filtered.where((c) => c.isFavourite).toList();
    final others = filtered.where((c) => !c.isFavourite).toList();
    final colors = context.colors;

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Card Stash',
                        style: TextStyle(
                          fontSize: 30,
                          fontWeight: FontWeight.w600,
                          color: colors.textPrimary,
                          height: 1.25,
                        ),
                      ),
                      IconButton(
                        icon: Icon(Icons.sort, color: colors.textMuted),
                        tooltip: 'Sort cards',
                        onPressed: _showSortOptions,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    onChanged: (value) => setState(() => _searchQuery = value),
                    style: TextStyle(fontSize: 16, color: colors.textPrimary),
                    decoration: InputDecoration(
                      hintText: 'Search cards...',
                      hintStyle: TextStyle(color: colors.textMuted),
                      prefixIcon: Icon(Icons.search, color: colors.textMuted),
                      filled: true,
                      fillColor: colors.surface,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: colors.border),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: colors.border),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide(color: colors.accent, width: 2),
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: cards.isEmpty
                  ? _buildEmptyState()
                  : filtered.isEmpty
                  ? _buildNoResults()
                  : _buildCardList(favourites, others),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/cards/add'),
        tooltip: 'Add card',
        backgroundColor: colors.accent,
        child: Icon(Icons.add, color: colors.background),
      ),
    );
  }

  Widget _buildEmptyState() {
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.credit_card_outlined,
              size: 64,
              color: colors.textMuted.withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            Text(
              'No cards yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap the + button to add your first loyalty card.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: colors.textMuted),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNoResults() {
    return Center(
      child: Text(
        'No cards match "$_searchQuery"',
        style: TextStyle(fontSize: 16, color: context.colors.textMuted),
      ),
    );
  }

  void _openCard(LoyaltyCard card) {
    ref.read(cardListProvider.notifier).incrementUsage(card.id);
    context.push('/cards/${card.id}');
  }

  Widget _buildCardList(
    List<LoyaltyCard> favourites,
    List<LoyaltyCard> others,
  ) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      children: [
        if (favourites.isNotEmpty) ...[
          _SectionHeader(label: 'PINNED'),
          const SizedBox(height: 8),
          for (final card in favourites) ...[
            CardTile(
              card: card,
              onTap: () => _openCard(card),
              onLongPress: () => _showCardActions(context, card),
            ),
            const SizedBox(height: 8),
          ],
          const SizedBox(height: 16),
        ],
        if (others.isNotEmpty) ...[
          _SectionHeader(
            label: _sortModeLabels[ref.watch(cardSortModeProvider)]!
                .toUpperCase(),
          ),
          const SizedBox(height: 8),
          for (final card in others) ...[
            CardTile(
              card: card,
              onTap: () => _openCard(card),
              onLongPress: () => _showCardActions(context, card),
            ),
            const SizedBox(height: 8),
          ],
        ],
        // Bottom padding so FAB doesn't overlap last card.
        const SizedBox(height: 80),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String label;

  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
        color: context.colors.textMuted,
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isDestructive;

  const _ActionTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isDestructive = false,
  });

  @override
  Widget build(BuildContext context) {
    final colours = context.colors;
    final colour = isDestructive ? colours.error : colours.textPrimary;
    return ListTile(
      leading: Icon(icon, color: colour),
      title: Text(label, style: TextStyle(color: colour)),
      onTap: onTap,
    );
  }
}
