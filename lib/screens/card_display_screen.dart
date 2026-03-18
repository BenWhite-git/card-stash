// ABOUTME: Full-screen card display with barcode at max brightness.
// ABOUTME: Forces screen brightness to maximum on open, restores on dismiss.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../models/card.dart';
import '../providers/card_provider.dart';
import '../services/brightness_service.dart';
import '../widgets/barcode_view.dart';

/// Riverpod provider for BrightnessService, overridable for testing.
final brightnessServiceProvider = Provider<BrightnessService>((ref) {
  return BrightnessService();
});

class CardDisplayScreen extends ConsumerStatefulWidget {
  final String cardId;

  const CardDisplayScreen({super.key, required this.cardId});

  @override
  ConsumerState<CardDisplayScreen> createState() => _CardDisplayScreenState();
}

class _CardDisplayScreenState extends ConsumerState<CardDisplayScreen> {
  // Cached so we can restore brightness in dispose() after ref is invalidated.
  late final BrightnessService _brightnessService;

  @override
  void initState() {
    super.initState();
    _brightnessService = ref.read(brightnessServiceProvider);
    _brightnessService.setMaxBrightness();
  }

  @override
  void dispose() {
    _brightnessService.restoreBrightness();
    super.dispose();
  }

  LoyaltyCard? _findCard() {
    final cards = ref.read(cardListProvider);
    try {
      return cards.firstWhere((c) => c.id == widget.cardId);
    } on StateError {
      return null;
    }
  }

  void _dismiss() {
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final card = _findCard();

    if (card == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: const Center(
          child: Text('Card not found', style: TextStyle(fontSize: 18)),
        ),
      );
    }

    return GestureDetector(
      onTap: _dismiss,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              children: [
                Row(
                  children: [
                    const SizedBox(width: 40),
                    Expanded(
                      child: Text(
                        card.name,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(
                        Icons.edit_outlined,
                        color: Colors.black54,
                      ),
                      tooltip: 'Edit card',
                      onPressed: () {
                        _dismiss();
                        context.push('/cards/${card.id}/edit');
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                if (card.issuer != null && card.issuer!.isNotEmpty)
                  Text(
                    card.issuer!,
                    style: const TextStyle(fontSize: 16, color: Colors.black54),
                    textAlign: TextAlign.center,
                  ),
                const Spacer(),
                BarcodeView(
                  cardNumber: card.cardNumber,
                  barcodeType: card.barcodeType,
                ),
                const Spacer(),
                _buildMetadata(card),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetadata(LoyaltyCard card) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (card.expiryDate != null)
          _MetadataRow(label: 'Expires', value: _formatDate(card.expiryDate!)),
        if (card.lastUsed != null)
          _MetadataRow(label: 'Last used', value: _formatDate(card.lastUsed!)),
        if (card.notes != null && card.notes!.isNotEmpty) ...[
          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Notes',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade600,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              card.notes!,
              style: const TextStyle(fontSize: 14, color: Colors.black87),
            ),
          ),
        ],
      ],
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

class _MetadataRow extends StatelessWidget {
  final String label;
  final String value;

  const _MetadataRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey.shade600,
            ),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 14, color: Colors.black87),
          ),
        ],
      ),
    );
  }
}
