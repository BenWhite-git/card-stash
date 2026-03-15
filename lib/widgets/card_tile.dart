// ABOUTME: List tile widget for a single card in the home screen.
// ABOUTME: Shows name, colour accent, expiry badge, note indicator, favourite badge.

import 'package:flutter/material.dart';

import '../models/card.dart';
import 'expiry_badge.dart';

class CardTile extends StatelessWidget {
  final LoyaltyCard card;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  const CardTile({
    super.key,
    required this.card,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E293B).withValues(alpha: 0.40),
          border: Border.all(color: const Color(0xFF334155)),
          borderRadius: BorderRadius.circular(16),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Colour accent circle.
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: card.colour,
                borderRadius: BorderRadius.circular(12),
              ),
              child: card.isFavourite
                  ? const Icon(
                      Icons.star_rounded,
                      color: Colors.white,
                      size: 20,
                    )
                  : null,
            ),
            const SizedBox(width: 16),
            // Card name and metadata.
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    card.name,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFFF8FAFC),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (card.issuer != null && card.issuer!.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(
                      card.issuer!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFFCBD5E1),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),
            // Trailing indicators.
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (card.notes != null && card.notes!.isNotEmpty)
                  const Padding(
                    padding: EdgeInsets.only(right: 8),
                    child: Icon(
                      Icons.notes_rounded,
                      size: 18,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                ExpiryBadge(expiryDate: card.expiryDate),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
