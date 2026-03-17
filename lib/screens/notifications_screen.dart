// ABOUTME: Alerts screen showing cards with expiry dates sorted by soonest first.
// ABOUTME: Reads existing card data, no additional storage or state.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/card.dart';
import '../providers/card_provider.dart';
import '../widgets/expiry_badge.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cards = ref.watch(cardListProvider);
    final expiringCards = cards.where((c) => c.expiryDate != null).toList()
      ..sort((a, b) => a.expiryDate!.compareTo(b.expiryDate!));

    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Text(
                'Alerts',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFFF8FAFC),
                  height: 1.25,
                ),
              ),
            ),
            Expanded(
              child: expiringCards.isEmpty
                  ? _buildEmptyState()
                  : _buildExpiryList(expiringCards),
            ),
          ],
        ),
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
              Icons.notifications_none_outlined,
              size: 64,
              color: const Color(0xFF94A3B8).withValues(alpha: 0.5),
            ),
            const SizedBox(height: 16),
            const Text(
              'No cards with expiry dates',
              style: TextStyle(fontSize: 16, color: Color(0xFF94A3B8)),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpiryList(List<LoyaltyCard> cards) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: cards.length,
      separatorBuilder: (_, _) =>
          const Divider(color: Color(0xFF334155), height: 1),
      itemBuilder: (context, index) {
        final card = cards[index];
        return _ExpiryRow(card: card);
      },
    );
  }
}

class _ExpiryRow extends StatelessWidget {
  final LoyaltyCard card;

  const _ExpiryRow({required this.card});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: Color(0xFFF8FAFC),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(card.expiryDate!),
                  style: const TextStyle(
                    fontSize: 14,
                    color: Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          ExpiryBadge(expiryDate: card.expiryDate),
        ],
      ),
    );
  }
}

const _months = [
  'Jan',
  'Feb',
  'Mar',
  'Apr',
  'May',
  'Jun',
  'Jul',
  'Aug',
  'Sep',
  'Oct',
  'Nov',
  'Dec',
];

String _formatDate(DateTime date) {
  return '${date.day} ${_months[date.month - 1]} ${date.year}';
}
