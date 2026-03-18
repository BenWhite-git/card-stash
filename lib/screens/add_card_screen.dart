// ABOUTME: Screen for adding a new card via camera scan or manual entry.
// ABOUTME: Includes payment card rejection via Luhn + BIN detection.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart' hide BarcodeType;
import 'package:uuid/uuid.dart';

import '../models/card.dart';
import '../providers/card_provider.dart';
import '../services/scanner_service.dart';
import '../utils/bin_detector.dart';
import '../utils/luhn_validator.dart';
import '../widgets/card_form_fields.dart';

const _paymentCardMessage =
    "This looks like a payment card. For your security, Card Stash doesn't "
    'store credit or debit cards. Use Apple Pay or Google Wallet instead.';

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
  Color _selectedColour = cardColours.first;
  DateTime? _expiryDate;
  String? _paymentCardError;

  MobileScannerController? _scannerController;
  bool _analyzingImage = false;

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

  Future<void> _scanFromImage() async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: ImageSource.gallery);
    if (image == null) return;

    setState(() => _analyzingImage = true);
    try {
      _scannerController ??= MobileScannerController();
      final capture = await _scannerController!.analyzeImage(image.path);
      if (capture == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No barcode found in this image.')),
          );
        }
        return;
      }
      final result = ScannerService.extractResult(capture);
      if (result == null) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No barcode found in this image.')),
          );
        }
        return;
      }
      setState(() {
        _scanned = true;
        _isScanMode = false;
        _cardNumberController.text = result.cardNumber;
        _selectedBarcodeType = result.barcodeType;
      });
      _scannerController?.stop();
      _checkPaymentCard(result.cardNumber);
    } finally {
      if (mounted) setState(() => _analyzingImage = false);
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
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          child: Column(
            children: [
              Text(
                'Point your camera at the barcode on your card.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16, color: Color(0xFF94A3B8)),
              ),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _analyzingImage ? null : _scanFromImage,
                icon: _analyzingImage
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Color(0xFFF59E0B),
                        ),
                      )
                    : const Icon(Icons.photo_library_outlined),
                label: Text(
                  _analyzingImage ? 'Scanning...' : 'Scan from photo',
                ),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFFF59E0B),
                ),
              ),
            ],
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
          const SizedBox(height: 24),

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
            hint: 'Enter or scan the card number',
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

          const CardFormLabel(text: 'Expiry date (optional)'),
          const SizedBox(height: 4),
          ExpiryPicker(
            expiryDate: _expiryDate,
            onTap: _pickExpiryDate,
            onClear: () => setState(() => _expiryDate = null),
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
        ],
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
