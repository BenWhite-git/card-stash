// ABOUTME: Screen for editing an existing card's name, notes, colour, barcode type, and expiry.
// ABOUTME: Also handles card deletion with confirmation dialog.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../models/card.dart';
import '../providers/card_provider.dart';
import '../providers/notification_provider.dart';
import '../widgets/card_form_fields.dart';

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
  Color _selectedColour = cardColours.first;
  DateTime? _expiryDate;
  String? _logoPath;
  bool _notificationsPermitted = true;

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
    _checkNotificationPermission();
  }

  Future<void> _checkNotificationPermission() async {
    final permitted = await ref
        .read(notificationServiceProvider)
        .areNotificationsEnabled();
    if (mounted && permitted != _notificationsPermitted) {
      setState(() => _notificationsPermitted = permitted);
    }
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

    await ref.read(cardListProvider.notifier).updateCard(updated);
    if (mounted) Navigator.of(context).pop();
  }

  Future<void> _handleDelete(LoyaltyCard card) async {
    final confirmed = await confirmDeleteDialog(context, card.name);
    if (confirmed && mounted) {
      await ref.read(cardListProvider.notifier).deleteCard(card.id);
      if (mounted) Navigator.of(context).pop();
    }
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
            const CardFormLabel(text: 'Card name'),
            const SizedBox(height: 4),
            CardTextField(
              controller: _nameController,
              hint: 'e.g. Tesco Clubcard',
              textCapitalization: TextCapitalization.words,
              autofocus: true,
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 20),

            const CardFormLabel(text: 'Card number'),
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

            const CardFormLabel(text: 'Barcode type'),
            const SizedBox(height: 8),
            BarcodeTypeChips(
              selected: _selectedBarcodeType,
              onSelected: (type) => setState(() => _selectedBarcodeType = type),
            ),
            const SizedBox(height: 20),

            const CardFormLabel(text: 'Colour'),
            const SizedBox(height: 8),
            ColourPicker(
              selected: _selectedColour,
              onSelected: (colour) => setState(() => _selectedColour = colour),
            ),
            const SizedBox(height: 20),

            const CardFormLabel(text: 'Logo (optional)'),
            const SizedBox(height: 8),
            _buildLogoPicker(),
            const SizedBox(height: 20),

            const CardFormLabel(text: 'Expiry date (optional)'),
            const SizedBox(height: 4),
            ExpiryPicker(
              expiryDate: _expiryDate,
              onTap: _pickExpiryDate,
              onClear: () => setState(() => _expiryDate = null),
            ),
            if (_expiryDate != null && !_notificationsPermitted)
              const Padding(
                padding: EdgeInsets.only(top: 6),
                child: Text(
                  'Expiry reminders require notification permission in Settings.',
                  style: TextStyle(fontSize: 12, color: Color(0xFFF59E0B)),
                ),
              ),
            const SizedBox(height: 20),

            const CardFormLabel(text: 'Notes (optional)'),
            const SizedBox(height: 4),
            CardTextField(
              controller: _notesController,
              hint: "e.g. Partner's card",
              maxLines: 3,
              onChanged: (_) => setState(() {}),
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
                onPressed: () => _handleDelete(card),
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

  Widget _buildLogoPicker() {
    return Semantics(
      label: 'Choose logo image',
      button: true,
      child: GestureDetector(
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
                Semantics(
                  label: 'Remove logo',
                  button: true,
                  child: GestureDetector(
                    onTap: () => setState(() => _logoPath = null),
                    child: const Icon(
                      Icons.close,
                      size: 18,
                      color: Color(0xFF94A3B8),
                    ),
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
      ),
    );
  }
}
