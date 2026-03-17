// ABOUTME: Main card list screen with search, sorting, and long-press actions.
// ABOUTME: Favourites pinned to top, remaining sorted by usage count descending.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/card.dart';
import '../providers/card_provider.dart';
import '../widgets/card_form_fields.dart';
import '../widgets/card_tile.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  String _searchQuery = '';

  List<LoyaltyCard> _filteredCards(List<LoyaltyCard> cards) {
    if (_searchQuery.isEmpty) return cards;
    final query = _searchQuery.toLowerCase();
    return cards.where((card) {
      return card.name.toLowerCase().contains(query) ||
          (card.issuer?.toLowerCase().contains(query) ?? false);
    }).toList();
  }

  void _showCardActions(BuildContext context, LoyaltyCard card) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: const Color(0xFF1E293B),
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
                color: const Color(0xFF94A3B8),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              card.name,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Color(0xFFF8FAFC),
              ),
            ),
            const SizedBox(height: 8),
            const Divider(color: Color(0xFF334155)),
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
                  const Text(
                    'Card Stash',
                    style: TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFF8FAFC),
                      height: 1.25,
                    ),
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    onChanged: (value) => setState(() => _searchQuery = value),
                    style: const TextStyle(
                      fontSize: 16,
                      color: Color(0xFFF8FAFC),
                    ),
                    decoration: InputDecoration(
                      hintText: 'Search cards...',
                      hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
                      prefixIcon: const Icon(
                        Icons.search,
                        color: Color(0xFF94A3B8),
                      ),
                      filled: true,
                      fillColor: const Color(0xFF1E293B),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF334155)),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(color: Color(0xFF334155)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: const BorderSide(
                          color: Color(0xFFF59E0B),
                          width: 2,
                        ),
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
        backgroundColor: const Color(0xFFF59E0B),
        child: const Icon(Icons.add, color: Color(0xFF0F172A)),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.credit_card_outlined,
              size: 64,
              color: const Color(0xFF94A3B8).withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No cards yet',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Color(0xFFF8FAFC),
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap the + button to add your first loyalty card.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: Color(0xFF94A3B8)),
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
        style: const TextStyle(fontSize: 16, color: Color(0xFF94A3B8)),
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
          _SectionHeader(label: 'MOST USED'),
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
      style: const TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        letterSpacing: 1.2,
        color: Color(0xFFA1B5CC),
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
    final colour = isDestructive
        ? const Color(0xFFEF4444)
        : const Color(0xFFF8FAFC);
    return ListTile(
      leading: Icon(icon, color: colour),
      title: Text(label, style: TextStyle(color: colour)),
      onTap: onTap,
    );
  }
}
