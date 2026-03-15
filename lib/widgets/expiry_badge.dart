// ABOUTME: Badge widget showing card expiry status.
// ABOUTME: Amber for 30 days or less, red for 7 days or less, hidden if >30 days.

import 'package:flutter/material.dart';

class ExpiryBadge extends StatelessWidget {
  final DateTime? expiryDate;

  const ExpiryBadge({super.key, required this.expiryDate});

  @override
  Widget build(BuildContext context) {
    if (expiryDate == null) return const SizedBox.shrink();

    final now = DateTime.now();
    // Use UTC to avoid DST skewing the day count.
    final today = DateTime.utc(now.year, now.month, now.day);
    final expiry = DateTime.utc(
      expiryDate!.year,
      expiryDate!.month,
      expiryDate!.day,
    );
    final daysLeft = expiry.difference(today).inDays;

    if (daysLeft > 30) return const SizedBox.shrink();

    final String label;
    final Color colour;

    if (daysLeft <= 0) {
      label = 'Expired';
      colour = const Color(0xFFEF4444); // danger
    } else if (daysLeft <= 7) {
      label = '${daysLeft}d left';
      colour = const Color(0xFFEF4444); // danger / red
    } else {
      label = '${daysLeft}d left';
      colour = const Color(0xFFF59E0B); // accent-fill / amber
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: colour.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(9999),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: colour,
          height: 1.4,
        ),
      ),
    );
  }
}
