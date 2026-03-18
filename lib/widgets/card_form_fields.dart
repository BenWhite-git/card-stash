// ABOUTME: Shared form widgets used by both add and edit card screens.
// ABOUTME: Extracted to eliminate duplication between the two form screens.

import 'package:flutter/material.dart';

import '../models/card.dart';

/// Colour palette for card backgrounds with accessibility labels.
const cardColours = <Color>[
  Color(0xFF3B82F6), // Blue
  Color(0xFF10B981), // Emerald
  Color(0xFFF59E0B), // Amber
  Color(0xFFEF4444), // Red
  Color(0xFF8B5CF6), // Violet
  Color(0xFFEC4899), // Pink
  Color(0xFF06B6D4), // Cyan
  Color(0xFFF97316), // Orange
  Color(0xFF6366F1), // Indigo
  Color(0xFF14B8A6), // Teal
  Color(0xFF84CC16), // Lime
  Color(0xFFD946EF), // Fuchsia
  Color(0xFF78716C), // Stone
  Color(0xFF0EA5E9), // Sky
  Color(0xFFA855F7), // Purple
  Color(0xFFE11D48), // Rose
];

const _colourNames = <int, String>{
  0xFF3B82F6: 'Blue',
  0xFF10B981: 'Emerald',
  0xFFF59E0B: 'Amber',
  0xFFEF4444: 'Red',
  0xFF8B5CF6: 'Violet',
  0xFFEC4899: 'Pink',
  0xFF06B6D4: 'Cyan',
  0xFFF97316: 'Orange',
  0xFF6366F1: 'Indigo',
  0xFF14B8A6: 'Teal',
  0xFF84CC16: 'Lime',
  0xFFD946EF: 'Fuchsia',
  0xFF78716C: 'Stone',
  0xFF0EA5E9: 'Sky',
  0xFFA855F7: 'Purple',
  0xFFE11D48: 'Rose',
};

/// Returns a user-facing label for a barcode type.
String barcodeTypeLabel(BarcodeType type) {
  switch (type) {
    case BarcodeType.qrCode:
      return 'QR Code';
    case BarcodeType.code128:
      return 'Code 128';
    case BarcodeType.code39:
      return 'Code 39';
    case BarcodeType.ean13:
      return 'EAN-13';
    case BarcodeType.ean8:
      return 'EAN-8';
    case BarcodeType.dataMatrix:
      return 'Data Matrix';
    case BarcodeType.pdf417:
      return 'PDF417';
    case BarcodeType.aztec:
      return 'Aztec';
    case BarcodeType.displayOnly:
      return 'Display Only';
  }
}

/// Section label used above form fields.
class CardFormLabel extends StatelessWidget {
  final String text;

  const CardFormLabel({super.key, required this.text});

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFFCBD5E1),
      ),
    );
  }
}

/// Styled text field matching the Card Stash dark theme.
class CardTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final TextInputType? keyboardType;
  final TextCapitalization textCapitalization;
  final bool autofocus;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  const CardTextField({
    super.key,
    required this.controller,
    required this.hint,
    this.keyboardType,
    this.textCapitalization = TextCapitalization.none,
    this.autofocus = false,
    this.maxLines = 1,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textCapitalization: textCapitalization,
      autofocus: autofocus,
      maxLines: maxLines,
      onChanged: onChanged,
      style: const TextStyle(fontSize: 16, color: Color(0xFFF8FAFC)),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: const TextStyle(color: Color(0xFF94A3B8)),
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
          borderSide: const BorderSide(color: Color(0xFFF59E0B), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
      ),
    );
  }
}

/// Barcode type selector rendered as a row of choice chips.
class BarcodeTypeChips extends StatelessWidget {
  final BarcodeType selected;
  final ValueChanged<BarcodeType> onSelected;

  const BarcodeTypeChips({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: BarcodeType.values.map((type) {
        final isSelected = type == selected;
        return ChoiceChip(
          label: Text(barcodeTypeLabel(type)),
          selected: isSelected,
          onSelected: (_) => onSelected(type),
          selectedColor: const Color(0xFFF59E0B).withValues(alpha: 0.2),
          backgroundColor: const Color(0xFF1E293B),
          side: BorderSide(
            color: isSelected
                ? const Color(0xFFF59E0B)
                : const Color(0xFF334155),
          ),
          labelStyle: TextStyle(
            fontSize: 13,
            color: isSelected
                ? const Color(0xFFF59E0B)
                : const Color(0xFFCBD5E1),
          ),
          showCheckmark: false,
        );
      }).toList(),
    );
  }
}

/// Colour picker rendered as a row of tappable circles with a custom option.
class ColourPicker extends StatelessWidget {
  final Color selected;
  final ValueChanged<Color> onSelected;

  const ColourPicker({
    super.key,
    required this.selected,
    required this.onSelected,
  });

  bool get _isCustomColour =>
      !cardColours.any((c) => c.toARGB32() == selected.toARGB32());

  Future<void> _showCustomPicker(BuildContext context) async {
    final colour = await showDialog<Color>(
      context: context,
      builder: (ctx) => _HsvColourPickerDialog(initial: selected),
    );
    if (colour != null) onSelected(colour);
  }

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        ...cardColours.map((colour) {
          final isSelected = colour.toARGB32() == selected.toARGB32();
          final name = _colourNames[colour.toARGB32()] ?? 'Colour';
          return Semantics(
            label: 'Select $name',
            button: true,
            selected: isSelected,
            child: GestureDetector(
              onTap: () => onSelected(colour),
              child: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: colour,
                  shape: BoxShape.circle,
                  border: isSelected
                      ? Border.all(color: const Color(0xFFF8FAFC), width: 3)
                      : null,
                ),
                child: isSelected
                    ? const Icon(Icons.check, color: Colors.white, size: 18)
                    : null,
              ),
            ),
          );
        }),
        Semantics(
          label: 'Pick custom colour',
          button: true,
          selected: _isCustomColour,
          child: GestureDetector(
            onTap: () => _showCustomPicker(context),
            child: Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _isCustomColour
                      ? const Color(0xFFF8FAFC)
                      : const Color(0xFF334155),
                  width: _isCustomColour ? 3 : 1,
                ),
                gradient: const SweepGradient(
                  colors: [
                    Color(0xFFFF0000),
                    Color(0xFFFFFF00),
                    Color(0xFF00FF00),
                    Color(0xFF00FFFF),
                    Color(0xFF0000FF),
                    Color(0xFFFF00FF),
                    Color(0xFFFF0000),
                  ],
                ),
              ),
              child: _isCustomColour
                  ? const Icon(Icons.check, color: Colors.white, size: 18)
                  : null,
            ),
          ),
        ),
      ],
    );
  }
}

/// Simple HSV colour picker dialog with hue slider and saturation/value grid.
class _HsvColourPickerDialog extends StatefulWidget {
  final Color initial;

  const _HsvColourPickerDialog({required this.initial});

  @override
  State<_HsvColourPickerDialog> createState() => _HsvColourPickerDialogState();
}

class _HsvColourPickerDialogState extends State<_HsvColourPickerDialog> {
  late HSVColor _hsv;

  @override
  void initState() {
    super.initState();
    _hsv = HSVColor.fromColor(widget.initial);
  }

  @override
  Widget build(BuildContext context) {
    final colour = _hsv.toColor();
    return AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      title: const Text(
        'Pick a colour',
        style: TextStyle(color: Color(0xFFF8FAFC)),
      ),
      content: SizedBox(
        width: 280,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Saturation/Value area.
            GestureDetector(
              onPanUpdate: (details) => _onSvPan(details, context),
              onTapDown: (details) => _onSvTap(details, context),
              child: SizedBox(
                height: 200,
                width: 280,
                child: CustomPaint(
                  painter: _SvPainter(hue: _hsv.hue),
                  child: Stack(
                    children: [
                      Positioned(
                        left: _hsv.saturation * 280 - 10,
                        top: (1 - _hsv.value) * 200 - 10,
                        child: Container(
                          width: 20,
                          height: 20,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Hue slider.
            SizedBox(
              height: 24,
              child: SliderTheme(
                data: SliderThemeData(
                  trackHeight: 12,
                  thumbShape: const RoundSliderThumbShape(
                    enabledThumbRadius: 10,
                  ),
                  thumbColor: HSVColor.fromAHSV(1, _hsv.hue, 1, 1).toColor(),
                  activeTrackColor: Colors.transparent,
                  inactiveTrackColor: Colors.transparent,
                  overlayShape: SliderComponentShape.noOverlay,
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(6),
                          gradient: const LinearGradient(
                            colors: [
                              Color(0xFFFF0000),
                              Color(0xFFFFFF00),
                              Color(0xFF00FF00),
                              Color(0xFF00FFFF),
                              Color(0xFF0000FF),
                              Color(0xFFFF00FF),
                              Color(0xFFFF0000),
                            ],
                          ),
                        ),
                      ),
                    ),
                    Slider(
                      value: _hsv.hue,
                      min: 0,
                      max: 360,
                      onChanged: (v) {
                        setState(() {
                          _hsv = _hsv.withHue(v.clamp(0, 360));
                        });
                      },
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            // Preview.
            Container(
              height: 40,
              width: double.infinity,
              decoration: BoxDecoration(
                color: colour,
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text(
            'Cancel',
            style: TextStyle(color: Color(0xFF94A3B8)),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, colour),
          child: const Text(
            'Select',
            style: TextStyle(color: Color(0xFFF59E0B)),
          ),
        ),
      ],
    );
  }

  void _onSvPan(DragUpdateDetails details, BuildContext context) {
    final box = context.findRenderObject() as RenderBox?;
    if (box == null) return;
    _updateSv(details.localPosition);
  }

  void _onSvTap(TapDownDetails details, BuildContext context) {
    _updateSv(details.localPosition);
  }

  void _updateSv(Offset position) {
    final s = (position.dx / 280).clamp(0.0, 1.0);
    final v = (1 - position.dy / 200).clamp(0.0, 1.0);
    setState(() {
      _hsv = HSVColor.fromAHSV(1, _hsv.hue, s, v);
    });
  }
}

/// Paints the saturation/value gradient for a given hue.
class _SvPainter extends CustomPainter {
  final double hue;

  _SvPainter({required this.hue});

  @override
  void paint(Canvas canvas, Size size) {
    final hueColour = HSVColor.fromAHSV(1, hue, 1, 1).toColor();
    // White-to-hue horizontal gradient.
    final satGradient = LinearGradient(colors: [Colors.white, hueColour]);
    canvas.drawRect(
      Offset.zero & size,
      Paint()..shader = satGradient.createShader(Offset.zero & size),
    );
    // Transparent-to-black vertical gradient.
    final valGradient = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [Colors.transparent, Colors.black],
    );
    canvas.drawRect(
      Offset.zero & size,
      Paint()..shader = valGradient.createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(_SvPainter old) => old.hue != hue;
}

/// Expiry date picker with optional clear button.
class ExpiryPicker extends StatelessWidget {
  final DateTime? expiryDate;
  final VoidCallback onTap;
  final VoidCallback? onClear;

  const ExpiryPicker({
    super.key,
    required this.expiryDate,
    required this.onTap,
    this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Pick expiry date',
      button: true,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: const Color(0xFF1E293B),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: const Color(0xFF334155)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  expiryDate != null
                      ? '${expiryDate!.day}/${expiryDate!.month}/${expiryDate!.year}'
                      : 'No expiry date set',
                  style: TextStyle(
                    fontSize: 16,
                    color: expiryDate != null
                        ? const Color(0xFFF8FAFC)
                        : const Color(0xFF94A3B8),
                  ),
                ),
              ),
              if (expiryDate != null && onClear != null)
                Semantics(
                  label: 'Remove expiry date',
                  button: true,
                  child: GestureDetector(
                    onTap: onClear,
                    child: const Icon(
                      Icons.close,
                      size: 18,
                      color: Color(0xFF94A3B8),
                    ),
                  ),
                )
              else
                const Icon(
                  Icons.calendar_today_outlined,
                  size: 18,
                  color: Color(0xFF94A3B8),
                ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Shows a confirmation dialog for deleting a card.
Future<bool> confirmDeleteDialog(BuildContext context, String cardName) async {
  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      backgroundColor: const Color(0xFF1E293B),
      title: const Text(
        'Delete card?',
        style: TextStyle(color: Color(0xFFF8FAFC)),
      ),
      content: Text(
        'Are you sure you want to delete "$cardName"? This cannot be undone.',
        style: const TextStyle(color: Color(0xFFCBD5E1)),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, false),
          child: const Text(
            'Cancel',
            style: TextStyle(color: Color(0xFF94A3B8)),
          ),
        ),
        TextButton(
          onPressed: () => Navigator.pop(dialogContext, true),
          child: const Text(
            'Delete',
            style: TextStyle(color: Color(0xFFEF4444)),
          ),
        ),
      ],
    ),
  );
  return confirmed ?? false;
}
