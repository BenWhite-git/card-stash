// ABOUTME: Screen for adding a new card via camera scan or manual entry.
// ABOUTME: Includes payment card rejection via Luhn + BIN detection.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mobile_scanner/mobile_scanner.dart' hide BarcodeType;
import 'package:uuid/uuid.dart';

import '../models/card.dart';
import '../providers/card_provider.dart';
import '../services/scanner_service.dart';
import '../utils/bin_detector.dart';
import '../utils/luhn_validator.dart';

const _paymentCardMessage =
    "This looks like a payment card. For your security, Card Stash doesn't "
    'store credit or debit cards. Use Apple Pay or Google Wallet instead.';

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

class AddCardScreen extends ConsumerStatefulWidget {
  final bool initialScanMode;

  const AddCardScreen({super.key, this.initialScanMode = true});

  @override
  ConsumerState<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends ConsumerState<AddCardScreen> {
  late bool _isScanMode = widget.initialScanMode;
  bool _scanned = false;

  final _nameController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _notesController = TextEditingController();

  BarcodeType _selectedBarcodeType = BarcodeType.code128;
  Color _selectedColour = _cardColours.first;
  DateTime? _expiryDate;
  String? _paymentCardError;

  MobileScannerController? _scannerController;

  @override
  void dispose() {
    _nameController.dispose();
    _cardNumberController.dispose();
    _notesController.dispose();
    _scannerController?.dispose();
    super.dispose();
  }

  void _onScanDetect(BarcodeCapture capture) {
    if (_scanned) return;
    final result = ScannerService.extractResult(capture);
    if (result == null) return;

    setState(() {
      _scanned = true;
      _isScanMode = false;
      _cardNumberController.text = result.cardNumber;
      _selectedBarcodeType = result.barcodeType;
    });
    _scannerController?.stop();
    _checkPaymentCard(result.cardNumber);
  }

  void _checkPaymentCard(String number) {
    if (LuhnValidator.isValid(number) && BinDetector.isPaymentCard(number)) {
      setState(() => _paymentCardError = _paymentCardMessage);
    } else {
      setState(() => _paymentCardError = null);
    }
  }

  void _switchToManual() {
    _scannerController?.stop();
    setState(() {
      _isScanMode = false;
      _scanned = false;
    });
  }

  void _switchToScan() {
    setState(() {
      _isScanMode = true;
      _scanned = false;
    });
    _scannerController?.start();
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

  bool get _isPaymentCard => _paymentCardError != null;

  bool get _canSave {
    final name = _nameController.text.trim();
    final number = _cardNumberController.text.trim();
    return name.isNotEmpty && number.isNotEmpty && !_isPaymentCard;
  }

  Future<void> _saveCard() async {
    if (!_canSave) return;

    final card = LoyaltyCard(
      id: const Uuid().v4(),
      name: _nameController.text.trim(),
      cardNumber: _cardNumberController.text.trim(),
      barcodeType: _selectedBarcodeType,
      colourValue: _selectedColour.toARGB32(),
      createdAt: DateTime.now(),
      expiryDate: _expiryDate,
      notes: _notesController.text.trim().isEmpty
          ? null
          : _notesController.text.trim(),
    );

    await ref.read(cardListProvider.notifier).addCard(card);
    if (mounted && Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Add Card',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Color(0xFFF8FAFC),
          ),
        ),
        backgroundColor: const Color(0xFF0F172A),
        iconTheme: const IconThemeData(color: Color(0xFFF8FAFC)),
        actions: [
          if (!_isScanMode)
            TextButton(
              onPressed: _switchToScan,
              child: const Text(
                'Scan',
                style: TextStyle(color: Color(0xFFF59E0B)),
              ),
            ),
          if (_isScanMode)
            TextButton(
              onPressed: _switchToManual,
              child: const Text(
                'Manual',
                style: TextStyle(color: Color(0xFFF59E0B)),
              ),
            ),
        ],
      ),
      body: _isScanMode ? _buildScanMode() : _buildManualMode(),
    );
  }

  Widget _buildScanMode() {
    _scannerController ??= MobileScannerController();
    return Column(
      children: [
        Expanded(
          child: Stack(
            alignment: Alignment.center,
            children: [
              MobileScanner(
                controller: _scannerController!,
                onDetect: _onScanDetect,
                errorBuilder: (context, error) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.camera_alt_outlined,
                            size: 48,
                            color: Color(0xFF94A3B8),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _cameraErrorMessage(error),
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                          const SizedBox(height: 24),
                          OutlinedButton(
                            onPressed: _switchToManual,
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFFF59E0B)),
                            ),
                            child: const Text(
                              'Enter manually',
                              style: TextStyle(color: Color(0xFFF59E0B)),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
              // Viewfinder overlay.
              IgnorePointer(
                child: Container(
                  width: 280,
                  height: 180,
                  decoration: BoxDecoration(
                    border: Border.all(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.7),
                      width: 2,
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Point your camera at the barcode on your card.',
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 16, color: Color(0xFF94A3B8)),
          ),
        ),
      ],
    );
  }

  Widget _buildManualMode() {
    return SingleChildScrollView(
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
          _buildTextField(
            controller: _cardNumberController,
            hint: 'Enter or scan the card number',
            keyboardType: TextInputType.text,
            onChanged: (value) => _checkPaymentCard(value),
          ),
          if (_isPaymentCard) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border(
                  left: BorderSide(color: const Color(0xFFEF4444), width: 4),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.warning_amber_rounded,
                    color: Color(0xFFEF4444),
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _paymentCardError!,
                      style: const TextStyle(
                        fontSize: 14,
                        color: Color(0xFFF8FAFC),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),

          _buildLabel('Barcode type'),
          const SizedBox(height: 8),
          _buildBarcodeTypeChips(),
          const SizedBox(height: 20),

          _buildLabel('Colour'),
          const SizedBox(height: 8),
          _buildColourPicker(),
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
              onPressed: _canSave ? _saveCard : null,
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
              child: const Text('Save card'),
            ),
          ),
          const SizedBox(height: 32),
        ],
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
    TextInputType? keyboardType,
    bool autofocus = false,
    int maxLines = 1,
    void Function(String)? onChanged,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      autofocus: autofocus,
      maxLines: maxLines,
      onChanged: (value) {
        setState(() {});
        onChanged?.call(value);
      },
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

  String _cameraErrorMessage(MobileScannerException error) {
    switch (error.errorCode) {
      case MobileScannerErrorCode.permissionDenied:
        return 'Camera permission is required to scan barcodes. '
            'You can grant it in Settings, or enter the card manually.';
      default:
        return 'Could not access the camera. '
            'You can enter the card details manually instead.';
    }
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
