// ABOUTME: Custom painter for drawing bounding boxes around card-relevant text on camera preview.
// ABOUTME: Scales ML Kit image coordinates to preview widget coordinates.

import 'package:flutter/material.dart';

/// Paints bounding boxes around detected card-relevant text over the camera preview.
///
/// Uses simple proportional scaling from image coordinates to widget coordinates.
class TextOverlayPainter extends CustomPainter {
  final List<Rect> relevantBoxes;
  final Size imageSize;
  final Color color;

  TextOverlayPainter({
    required this.relevantBoxes,
    required this.imageSize,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (relevantBoxes.isEmpty || imageSize == Size.zero) return;

    final borderPaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final fillPaint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    final scaleX = size.width / imageSize.width;
    final scaleY = size.height / imageSize.height;

    for (final rect in relevantBoxes) {
      final scaledRect = Rect.fromLTRB(
        rect.left * scaleX,
        rect.top * scaleY,
        rect.right * scaleX,
        rect.bottom * scaleY,
      );

      final rrect = RRect.fromRectAndRadius(
        scaledRect,
        const Radius.circular(4),
      );
      canvas.drawRRect(rrect, fillPaint);
      canvas.drawRRect(rrect, borderPaint);
    }
  }

  @override
  bool shouldRepaint(TextOverlayPainter oldDelegate) {
    return relevantBoxes != oldDelegate.relevantBoxes ||
        imageSize != oldDelegate.imageSize;
  }
}
