// ABOUTME: Screen for adding a new card via camera scan or manual entry.
// ABOUTME: Includes payment card rejection via Luhn + BIN detection.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mobile_scanner/mobile_scanner.dart' hide BarcodeType;
import 'package:uuid/uuid.dart';

import '../models/card.dart';
import '../providers/card_provider.dart';
import '../services/ocr_service.dart';
import '../services/scanner_service.dart';
import '../theme.dart';
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

  void _applyOcrResult(OcrResult ocr) {
    setState(() {
      if (ocr.issuerHint != null && _nameController.text.isEmpty) {
        _nameController.text = ocr.issuerHint!;
      }
      if (ocr.expiryDate != null && _expiryDate == null) {
        _expiryDate = ocr.expiryDate;
      }
    });
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

    // Run OCR on the captured image to extract name and expiry.
    final imageBytes = capture.image;
    if (imageBytes != null) {
      OcrService.extractCardInfoFromBytes(imageBytes).then((ocr) {
        if (ocr != null && mounted) _applyOcrResult(ocr);
      });
    }
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
      // Run barcode detection and OCR in parallel.
      _scannerController ??= MobileScannerController();
      final results = await Future.wait([
        _scannerController!.analyzeImage(image.path),
        OcrService.extractCardInfo(image.path),
      ]);
      final capture = results[0] as BarcodeCapture?;
      final ocr = results[1] as OcrResult?;

      final scanResult = capture != null
          ? ScannerService.extractResult(capture)
          : null;

      if (scanResult != null) {
        // Barcode found: use barcode number + type, supplement with OCR.
        setState(() {
          _scanned = true;
          _isScanMode = false;
          _cardNumberController.text = scanResult.cardNumber;
          _selectedBarcodeType = scanResult.barcodeType;
        });
        _scannerController?.stop();
        _checkPaymentCard(scanResult.cardNumber);
        if (ocr != null && mounted) _applyOcrResult(ocr);
      } else if (ocr?.cardNumber != null) {
        // No barcode but OCR found a number: use as displayOnly.
        setState(() {
          _scanned = true;
          _isScanMode = false;
          _cardNumberController.text = ocr!.cardNumber!;
          _selectedBarcodeType = BarcodeType.displayOnly;
        });
        _scannerController?.stop();
        _checkPaymentCard(ocr!.cardNumber!);
        _applyOcrResult(ocr);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('No barcode or text found in this image.'),
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _analyzingImage = false);
    }
  }

  Future<void> _captureAndScan() async {
    final picker = ImagePicker();
    final photo = await picker.pickImage(source: ImageSource.camera);
    if (photo == null) return;

    setState(() => _analyzingImage = true);
    try {
      final ocr = await OcrService.extractCardInfo(photo.path);
      if (ocr?.cardNumber != null) {
        setState(() {
          _scanned = true;
          _isScanMode = false;
          _cardNumberController.text = ocr!.cardNumber!;
          _selectedBarcodeType = BarcodeType.displayOnly;
        });
        _scannerController?.stop();
        _checkPaymentCard(ocr!.cardNumber!);
        _applyOcrResult(ocr);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('No text found in this photo.')),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _analyzingImage = false);
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

  bool get _isPaymentCard => _paymentCardError != null;

  bool get _canSave {
    final name = _nameController.text.trim();
    final number = _cardNumberController.text.trim();
    return name.isNotEmpty && number.isNotEmpty && !_isPaymentCard;
  }

  Future<void> _saveCard() async {
    if (!_canSave) return;

    // Defense-in-depth: reject payment cards even if UI state is stale.
    final number = _cardNumberController.text.trim();
    if (LuhnValidator.isValid(number) && BinDetector.isPaymentCard(number)) {
      setState(() => _paymentCardError = _paymentCardMessage);
      return;
    }

    // Check for duplicate card number.
    final duplicate = ref.read(cardListProvider.notifier).findDuplicate(number);
    if (duplicate != null && mounted) {
      final confirmed = await confirmDuplicateDialog(context, duplicate.name);
      if (!confirmed) return;
    }

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
    final colors = context.colors;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Add Card',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
        backgroundColor: colors.background,
        iconTheme: IconThemeData(color: colors.textPrimary),
        actions: [
          if (_isScanMode)
            TextButton(
              onPressed: _switchToManual,
              child: Text('Manual', style: TextStyle(color: colors.accent)),
            ),
        ],
      ),
      body: _isScanMode ? _buildScanMode() : _buildManualMode(),
    );
  }

  Widget _buildScanMode() {
    _scannerController ??= MobileScannerController(returnImage: true);
    final colors = context.colors;
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
                  final errColors = context.colors;
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.camera_alt_outlined,
                            size: 48,
                            color: errColors.textMuted,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _cameraErrorMessage(error),
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 16,
                              color: errColors.textMuted,
                            ),
                          ),
                          const SizedBox(height: 24),
                          OutlinedButton(
                            onPressed: _switchToManual,
                            style: OutlinedButton.styleFrom(
                              side: BorderSide(color: errColors.accent),
                            ),
                            child: Text(
                              'Enter manually',
                              style: TextStyle(color: errColors.accent),
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
                      color: colors.accent.withValues(alpha: 0.7),
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
                style: TextStyle(fontSize: 16, color: colors.textMuted),
              ),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton.icon(
                    onPressed: _analyzingImage ? null : _captureAndScan,
                    icon: _analyzingImage
                        ? SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: colors.accent,
                            ),
                          )
                        : const Icon(Icons.camera_alt_outlined),
                    label: const Text('Take photo'),
                    style: TextButton.styleFrom(foregroundColor: colors.accent),
                  ),
                  const SizedBox(width: 16),
                  TextButton.icon(
                    onPressed: _analyzingImage ? null : _scanFromImage,
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('From gallery'),
                    style: TextButton.styleFrom(foregroundColor: colors.accent),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildManualMode() {
    final colors = context.colors;
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
                color: colors.error.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border(left: BorderSide(color: colors.error, width: 4)),
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
                      style: TextStyle(fontSize: 14, color: colors.textPrimary),
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
