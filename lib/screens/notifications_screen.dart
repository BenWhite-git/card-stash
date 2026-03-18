// ABOUTME: Alerts screen showing cards with expiry dates sorted by soonest first.
// ABOUTME: Reads existing card data, no additional storage or state.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/card.dart';
import '../providers/card_provider.dart';
import '../theme.dart';
import '../widgets/expiry_badge.dart';

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cards = ref.watch(cardListProvider);
    final expiringCards = cards.where((c) => c.expiryDate != null).toList()
      ..sort((a, b) => a.expiryDate!.compareTo(b.expiryDate!));

    final colors = context.colors;
    return Scaffold(
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
              child: Text(
                'Alerts',
                style: TextStyle(
                  fontSize: 30,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
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
    // No context available directly; use Builder or pass from build.
    return Builder(
      builder: (context) {
        final colors = context.colors;
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.notifications_none_outlined,
                  size: 64,
                  color: colors.textMuted.withValues(alpha: 0.5),
                ),
                const SizedBox(height: 16),
                Text(
                  'No cards with expiry dates',
                  style: TextStyle(fontSize: 16, color: colors.textMuted),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildExpiryList(List<LoyaltyCard> cards) {
    return ListView.separated(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      itemCount: cards.length,
      separatorBuilder: (context, _) =>
          Divider(color: context.colors.border, height: 1),
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
    final colors = context.colors;
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
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(card.expiryDate!),
                  style: TextStyle(fontSize: 14, color: colors.textMuted),
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
