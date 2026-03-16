// ABOUTME: Screen for editing an existing card's name, notes, colour, barcode type, and expiry.
// ABOUTME: Also handles card deletion with confirmation dialog.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../models/card.dart';
import '../providers/card_provider.dart';

const _cardColours = <Color>[
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
];

class EditCardScreen extends ConsumerStatefulWidget {
  final String cardId;

  const EditCardScreen({super.key, required this.cardId});

  @override
  ConsumerState<EditCardScreen> createState() => _EditCardScreenState();
}

class _EditCardScreenState extends ConsumerState<EditCardScreen> {
  final _nameController = TextEditingController();
  final _notesController = TextEditingController();

  BarcodeType _selectedBarcodeType = BarcodeType.code128;
  Color _selectedColour = _cardColours.first;
  DateTime? _expiryDate;
  String? _logoPath;

  bool _initialised = false;

  LoyaltyCard? _findCard() {
    final cards = ref.read(cardListProvider);
    try {
      return cards.firstWhere((c) => c.id == widget.cardId);
    } on StateError {
      return null;
    }
  }

  void _initFromCard(LoyaltyCard card) {
    if (_initialised) return;
    _initialised = true;

    _nameController.text = card.name;
    _notesController.text = card.notes ?? '';
    _selectedBarcodeType = card.barcodeType;
    _selectedColour = card.colour;
    _expiryDate = card.expiryDate;
    _logoPath = card.logoPath;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool get _canSave => _nameController.text.trim().isNotEmpty;

  Future<void> _saveCard(LoyaltyCard original) async {
    if (!_canSave) return;

    final notes = _notesController.text.trim();
    final updated = LoyaltyCard(
      id: original.id,
      name: _nameController.text.trim(),
      issuer: original.issuer,
      cardNumber: original.cardNumber,
      barcodeType: _selectedBarcodeType,
      colourValue: _selectedColour.toARGB32(),
      logoPath: _logoPath,
      expiryDate: _expiryDate,
      usageCount: original.usageCount,
      lastUsed: original.lastUsed,
      createdAt: original.createdAt,
      notes: notes.isEmpty ? null : notes,
      isFavourite: original.isFavourite,
      notificationIds: original.notificationIds,
    );

    // TODO: Phase 6 - reschedule notifications if expiryDate changed.
    await ref.read(cardListProvider.notifier).updateCard(updated);
    if (mounted) Navigator.of(context).pop();
  }

  void _confirmDelete(LoyaltyCard card) {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: const Color(0xFF1E293B),
        title: const Text(
          'Delete card?',
          style: TextStyle(color: Color(0xFFF8FAFC)),
        ),
        content: Text(
          'Are you sure you want to delete "${card.name}"? This cannot be undone.',
          style: const TextStyle(color: Color(0xFFCBD5E1)),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text(
              'Cancel',
              style: TextStyle(color: Color(0xFF94A3B8)),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              _deleteCard(card);
            },
            child: const Text(
              'Delete',
              style: TextStyle(color: Color(0xFFEF4444)),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteCard(LoyaltyCard card) async {
    // TODO: Phase 6 - cancel notifications for this card.
    await ref.read(cardListProvider.notifier).deleteCard(card.id);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _pickExpiryDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? now.add(const Duration(days: 365)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 10)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: const Color(0xFFF59E0B),
              onPrimary: const Color(0xFF0F172A),
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _expiryDate = picked);
    }
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
    );
    if (image != null) {
      setState(() => _logoPath = image.path);
    }
  }

  @override
  Widget build(BuildContext context) {
    final card = _findCard();
    if (card == null) {
      return Scaffold(
        appBar: AppBar(
          title: const Text(
            'Edit Card',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Color(0xFFF8FAFC),
            ),
          ),
          backgroundColor: const Color(0xFF0F172A),
          iconTheme: const IconThemeData(color: Color(0xFFF8FAFC)),
        ),
        body: const Center(
          child: Text(
            'Card not found.',
            style: TextStyle(fontSize: 16, color: Color(0xFF94A3B8)),
          ),
        ),
      );
    }

    _initFromCard(card);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Edit Card',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFFF8FAFC),
          ),
        ),
        backgroundColor: const Color(0xFF0F172A),
        iconTheme: const IconThemeData(color: Color(0xFFF8FAFC)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel('Card name'),
            const SizedBox(height: 4),
            _buildTextField(
              controller: _nameController,
              hint: 'e.g. Tesco Clubcard',
              autofocus: true,
            ),
            const SizedBox(height: 20),

            _buildLabel('Card number'),
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
              decoration: BoxDecoration(
                color: const Color(0xFF1E293B),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFF334155)),
              ),
              child: Text(
                card.cardNumber,
                style: const TextStyle(fontSize: 16, color: Color(0xFF94A3B8)),
              ),
            ),
            const SizedBox(height: 20),

            _buildLabel('Barcode type'),
            const SizedBox(height: 8),
            _buildBarcodeTypeChips(),
            const SizedBox(height: 20),

            _buildLabel('Colour'),
            const SizedBox(height: 8),
            _buildColourPicker(),
            const SizedBox(height: 20),

            _buildLabel('Logo (optional)'),
            const SizedBox(height: 8),
            _buildLogoPicker(),
            const SizedBox(height: 20),

            _buildLabel('Expiry date (optional)'),
            const SizedBox(height: 4),
            _buildExpiryPicker(),
            const SizedBox(height: 20),

            _buildLabel('Notes (optional)'),
            const SizedBox(height: 4),
            _buildTextField(
              controller: _notesController,
              hint: "e.g. Partner's card",
              maxLines: 3,
            ),
            const SizedBox(height: 32),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _canSave ? () => _saveCard(card) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFF59E0B),
                  disabledBackgroundColor: const Color(
                    0xFF94A3B8,
                  ).withValues(alpha: 0.2),
                  foregroundColor: const Color(0xFF0F172A),
                  disabledForegroundColor: const Color(0xFF94A3B8),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Save changes'),
              ),
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => _confirmDelete(card),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Color(0xFFEF4444)),
                  foregroundColor: const Color(0xFFEF4444),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  textStyle: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                child: const Text('Delete card'),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: Color(0xFFCBD5E1),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    bool autofocus = false,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      autofocus: autofocus,
      maxLines: maxLines,
      onChanged: (_) => setState(() {}),
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

  Widget _buildBarcodeTypeChips() {
    final types = BarcodeType.values;
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: types.map((type) {
        final selected = type == _selectedBarcodeType;
        return ChoiceChip(
          label: Text(_barcodeTypeLabel(type)),
          selected: selected,
          onSelected: (_) => setState(() => _selectedBarcodeType = type),
          selectedColor: const Color(0xFFF59E0B).withValues(alpha: 0.2),
          backgroundColor: const Color(0xFF1E293B),
          side: BorderSide(
            color: selected ? const Color(0xFFF59E0B) : const Color(0xFF334155),
          ),
          labelStyle: TextStyle(
            fontSize: 13,
            color: selected ? const Color(0xFFF59E0B) : const Color(0xFFCBD5E1),
          ),
          showCheckmark: false,
        );
      }).toList(),
    );
  }

  Widget _buildColourPicker() {
    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: _cardColours.map((colour) {
        final selected = colour.toARGB32() == _selectedColour.toARGB32();
        return GestureDetector(
          onTap: () => setState(() => _selectedColour = colour),
          child: Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: colour,
              shape: BoxShape.circle,
              border: selected
                  ? Border.all(color: const Color(0xFFF8FAFC), width: 3)
                  : null,
            ),
            child: selected
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : null,
          ),
        );
      }).toList(),
    );
  }

  Widget _buildLogoPicker() {
    return GestureDetector(
      onTap: _pickLogo,
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
                _logoPath != null ? 'Logo selected' : 'No logo set',
                style: TextStyle(
                  fontSize: 16,
                  color: _logoPath != null
                      ? const Color(0xFFF8FAFC)
                      : const Color(0xFF94A3B8),
                ),
              ),
            ),
            if (_logoPath != null)
              GestureDetector(
                onTap: () => setState(() => _logoPath = null),
                child: const Icon(
                  Icons.close,
                  size: 18,
                  color: Color(0xFF94A3B8),
                ),
              )
            else
              const Icon(
                Icons.image_outlined,
                size: 18,
                color: Color(0xFF94A3B8),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildExpiryPicker() {
    return GestureDetector(
      onTap: _pickExpiryDate,
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
                _expiryDate != null
                    ? '${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}'
                    : 'No expiry date set',
                style: TextStyle(
                  fontSize: 16,
                  color: _expiryDate != null
                      ? const Color(0xFFF8FAFC)
                      : const Color(0xFF94A3B8),
                ),
              ),
            ),
            if (_expiryDate != null)
              GestureDetector(
                onTap: () => setState(() => _expiryDate = null),
                child: const Icon(
                  Icons.close,
                  size: 18,
                  color: Color(0xFF94A3B8),
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
    );
  }
}

String _barcodeTypeLabel(BarcodeType type) {
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
