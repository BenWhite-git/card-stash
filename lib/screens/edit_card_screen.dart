// ABOUTME: Screen for editing an existing card's details including card number.
// ABOUTME: Includes payment card rejection, duplicate detection, and deletion.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';

import '../models/card.dart';
import '../providers/card_provider.dart';
import '../providers/notification_provider.dart';
import '../theme.dart';
import '../utils/bin_detector.dart';
import '../utils/luhn_validator.dart';
import '../widgets/card_form_fields.dart';

const _paymentCardMessage =
    "This looks like a payment card. For your security, Card Stash doesn't "
    'store credit or debit cards. Use Apple Pay or Google Wallet instead.';

class EditCardScreen extends ConsumerStatefulWidget {
  final String cardId;

  const EditCardScreen({super.key, required this.cardId});

  @override
  ConsumerState<EditCardScreen> createState() => _EditCardScreenState();
}

class _EditCardScreenState extends ConsumerState<EditCardScreen> {
  final _nameController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _notesController = TextEditingController();

  BarcodeType _selectedBarcodeType = BarcodeType.code128;
  Color _selectedColour = cardColours.first;
  DateTime? _expiryDate;
  String? _logoPath;
  bool _notificationsPermitted = true;
  String? _paymentCardError;

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
    _cardNumberController.text = card.cardNumber;
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

  void _checkPaymentCard(String number) {
    if (LuhnValidator.isValid(number) && BinDetector.isPaymentCard(number)) {
      setState(() => _paymentCardError = _paymentCardMessage);
    } else {
      setState(() => _paymentCardError = null);
    }
  }

  bool get _isPaymentCard => _paymentCardError != null;

  @override
  void dispose() {
    _nameController.dispose();
    _cardNumberController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  bool get _canSave {
    final name = _nameController.text.trim();
    final number = _cardNumberController.text.trim();
    return name.isNotEmpty && number.isNotEmpty && !_isPaymentCard;
  }

  Future<void> _saveCard(LoyaltyCard original) async {
    if (!_canSave) return;

    // Defense-in-depth: reject payment cards even if UI state is stale.
    final number = _cardNumberController.text.trim();
    if (LuhnValidator.isValid(number) && BinDetector.isPaymentCard(number)) {
      setState(() => _paymentCardError = _paymentCardMessage);
      return;
    }

    // Check for duplicate card number, excluding this card.
    final duplicate = ref
        .read(cardListProvider.notifier)
        .findDuplicate(number, excludeId: original.id);
    if (duplicate != null && mounted) {
      final confirmed = await confirmDuplicateDialog(context, duplicate.name);
      if (!confirmed) return;
    }

    final notes = _notesController.text.trim();
    final updated = LoyaltyCard(
      id: original.id,
      name: _nameController.text.trim(),
      issuer: original.issuer,
      cardNumber: number,
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
    final colors = context.colors;
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? now.add(const Duration(days: 365)),
      firstDate: now,
      lastDate: now.add(const Duration(days: 365 * 10)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: colors.accent,
              onPrimary: colors.background,
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
    final colors = context.colors;
    final card = _findCard();
    if (card == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'Edit Card',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          backgroundColor: colors.background,
          iconTheme: IconThemeData(color: colors.textPrimary),
        ),
        body: Center(
          child: Text(
            'Card not found.',
            style: TextStyle(fontSize: 16, color: colors.textMuted),
          ),
        ),
      );
    }

    _initFromCard(card);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Edit Card',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        backgroundColor: colors.background,
        iconTheme: IconThemeData(color: colors.textPrimary),
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
            CardTextField(
              controller: _cardNumberController,
              hint: 'Enter the card number',
              keyboardType: TextInputType.text,
              onChanged: (value) {
                setState(() {});
                _checkPaymentCard(value);
              },
            ),
            if (_isPaymentCard) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.error.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                  border: Border(
                    left: BorderSide(color: colors.error, width: 4),
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: colors.error,
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        _paymentCardError!,
                        style: TextStyle(
                          fontSize: 14,
                          color: colors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
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
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  'Expiry reminders require notification permission in Settings.',
                  style: TextStyle(fontSize: 12, color: colors.accent),
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
                  backgroundColor: colors.accent,
                  disabledBackgroundColor: colors.textMuted.withValues(
                    alpha: 0.2,
                  ),
                  foregroundColor: colors.background,
                  disabledForegroundColor: colors.textMuted,
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
                  side: BorderSide(color: colors.error),
                  foregroundColor: colors.error,
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
    final colors = context.colors;
    return Semantics(
      label: 'Choose logo image',
      button: true,
      child: GestureDetector(
        onTap: _pickLogo,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  _logoPath != null ? 'Logo selected' : 'No logo set',
                  style: TextStyle(
                    fontSize: 16,
                    color: _logoPath != null
                        ? colors.textPrimary
                        : colors.textMuted,
                  ),
                ),
              ),
              if (_logoPath != null)
                Semantics(
                  label: 'Remove logo',
                  button: true,
                  child: GestureDetector(
                    onTap: () => setState(() => _logoPath = null),
                    child: Icon(Icons.close, size: 18, color: colors.textMuted),
                  ),
                )
              else
                Icon(Icons.image_outlined, size: 18, color: colors.textMuted),
            ],
          ),
        ),
      ),
    );
  }
}
