// ABOUTME: Status indicator bar for the live camera scan mode.
// ABOUTME: Shows detected field chips and "Use these details" action button.

import 'package:flutter/material.dart';

import '../services/ocr_service.dart';
import '../theme.dart';

/// Displays which card fields have been detected during live OCR scanning.
///
/// Shows animated chips for card number, expiry, and card name that light up
/// as each field is recognized. A "Use these details" button appears when
/// at least a card number has been found.
class ScanStatusBar extends StatelessWidget {
  final OcrResult? ocrResult;
  final VoidCallback? onAccept;

  const ScanStatusBar({
    super.key,
    required this.ocrResult,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final hasNumber = ocrResult?.cardNumber != null;
    final hasExpiry = ocrResult?.expiryDate != null;
    final hasName = ocrResult?.issuerHint != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: colors.background.withValues(alpha: 0.9),
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              _DetectionChip(
                label: 'Card number',
                detected: hasNumber,
                colors: colors,
              ),
              _DetectionChip(
                label: 'Expiry',
                detected: hasExpiry,
                colors: colors,
              ),
              _DetectionChip(
                label: 'Card name',
                detected: hasName,
                colors: colors,
              ),
            ],
          ),
          if (hasNumber) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onAccept,
                style: ElevatedButton.styleFrom(
                  backgroundColor: colors.accent,
                  foregroundColor: colors.background,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Use these details'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetectionChip extends StatelessWidget {
  final String label;
  final bool detected;
  final CardStashColors colors;

  const _DetectionChip({
    required this.label,
    required this.detected,
    required this.colors,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 150),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: detected
            ? colors.accent.withValues(alpha: 0.15)
            : colors.textMuted.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(9999),
        border: Border.all(
          color: detected
              ? colors.accent
              : colors.textMuted.withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (detected)
            Padding(
              padding: const EdgeInsets.only(right: 4),
              child: Icon(Icons.check_circle, size: 14, color: colors.accent),
            ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: detected ? FontWeight.w600 : FontWeight.w400,
              color: detected ? colors.accent : colors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
