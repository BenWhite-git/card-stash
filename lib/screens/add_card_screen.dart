// ABOUTME: Screen for adding a new card via live camera scan or manual entry.
// ABOUTME: Includes payment card rejection via Luhn + BIN detection.

import 'dart:ui' as ui;

import 'package:camera/camera.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart'
    hide BarcodeType;
import 'package:image_picker/image_picker.dart';
import 'package:uuid/uuid.dart';

import '../models/card.dart';
import '../providers/card_provider.dart';
import '../services/camera_frame_processor.dart';
import '../services/ocr_service.dart';
import '../services/scanner_service.dart';
import '../theme.dart';
import '../utils/bin_detector.dart';
import '../utils/luhn_validator.dart';
import '../widgets/card_form_fields.dart';
import '../widgets/scan_status_bar.dart';
import '../widgets/text_overlay_painter.dart';

const _paymentCardMessage =
    "This looks like a payment card. For your security, Card Stash doesn't "
    'store credit or debit cards. Use Apple Pay or Google Wallet instead.';

class AddCardScreen extends ConsumerStatefulWidget {
  final bool initialScanMode;

  const AddCardScreen({super.key, this.initialScanMode = true});

  @override
  ConsumerState<AddCardScreen> createState() => _AddCardScreenState();
}

class _AddCardScreenState extends ConsumerState<AddCardScreen>
    with WidgetsBindingObserver {
  late bool _isScanMode = widget.initialScanMode;
  bool _scanned = false;

  final _nameController = TextEditingController();
  final _cardNumberController = TextEditingController();
  final _notesController = TextEditingController();

  BarcodeType _selectedBarcodeType = BarcodeType.code128;
  Color _selectedColour = cardColours.first;
  DateTime? _expiryDate;
  String? _paymentCardError;

  // Camera and frame processing state.
  CameraController? _cameraController;
  CameraFrameProcessor? _frameProcessor;
  bool _cameraInitialised = false;
  String? _cameraError;

  // Live recognition state.
  List<Rect> _liveRelevantBoxes = [];
  OcrResult? _liveOcrResult;
  ui.Size _imageSize = ui.Size.zero;

  bool _analyzingImage = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (widget.initialScanMode) {
      _initCamera();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _nameController.dispose();
    _cardNumberController.dispose();
    _notesController.dispose();
    _stopCamera();
    _frameProcessor?.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!_isScanMode) return;
    if (state == AppLifecycleState.inactive ||
        state == AppLifecycleState.paused) {
      _stopCamera();
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) {
        if (mounted) {
          setState(() => _cameraError = 'No camera available on this device.');
        }
        return;
      }

      // Prefer back camera.
      final camera = cameras.firstWhere(
        (c) => c.lensDirection == CameraLensDirection.back,
        orElse: () => cameras.first,
      );

      final controller = CameraController(
        camera,
        ResolutionPreset.high,
        enableAudio: false,
        imageFormatGroup: defaultTargetPlatform == TargetPlatform.iOS
            ? ImageFormatGroup.bgra8888
            : ImageFormatGroup.nv21,
      );

      await controller.initialize();
      if (!mounted) {
        controller.dispose();
        return;
      }

      _cameraController = controller;
      _frameProcessor ??= CameraFrameProcessor();

      await controller.startImageStream(_onFrameAvailable);

      setState(() {
        _cameraInitialised = true;
        _cameraError = null;
      });
    } on CameraException catch (e) {
      if (mounted) {
        setState(() => _cameraError = _cameraErrorMessage(e));
      }
    } catch (e) {
      if (mounted) {
        setState(
          () => _cameraError =
              'Could not access the camera. '
              'You can enter the card details manually instead.',
        );
      }
    }
  }

  void _stopCamera() {
    _cameraController?.dispose();
    _cameraController = null;
    _cameraInitialised = false;
  }

  void _onFrameAvailable(CameraImage image) {
    if (_scanned || !_isScanMode) return;

    final camera = _cameraController;
    if (camera == null) return;

    final sensorOrientation = camera.description.sensorOrientation;

    _frameProcessor
        ?.processFrame(image, sensorOrientation, DeviceOrientation.portraitUp)
        .then((result) {
          if (result == null || !mounted || _scanned) return;

          // Barcode detected: auto-accept immediately.
          final scanResult = ScannerService.extractResult(result.barcodes);
          if (scanResult != null) {
            _scanned = true;
            _cameraController?.stopImageStream();
            setState(() {
              _isScanMode = false;
              _cardNumberController.text = scanResult.cardNumber;
              _selectedBarcodeType = scanResult.barcodeType;
            });
            _checkPaymentCard(scanResult.cardNumber);

            // Also apply any text recognition for name/expiry.
            if (result.recognizedText != null &&
                result.recognizedText!.text.isNotEmpty) {
              final ocr = OcrService.parseText(result.recognizedText!.text);
              if (ocr != null) _applyOcrResult(ocr);
            }
            return;
          }

          // No barcode - update live overlay and OCR result.
          if (result.recognizedText != null &&
              result.recognizedText!.text.isNotEmpty) {
            final ocr = OcrService.parseText(result.recognizedText!.text);
            // Only highlight blocks with card numbers or expiry patterns.
            final boxes = result.recognizedText!.blocks
                .where((b) => OcrService.isRelevantText(b.text))
                .map((b) => b.boundingBox)
                .toList();
            // ML Kit returns bounding boxes in the rotated coordinate
            // space, but CameraImage dimensions are in the sensor's native
            // orientation. Swap width/height when sensor is rotated 90/270.
            final rotated = sensorOrientation == 90 || sensorOrientation == 270;
            final effectiveSize = rotated
                ? ui.Size(result.imageSize.height, result.imageSize.width)
                : result.imageSize;
            setState(() {
              _liveRelevantBoxes = boxes;
              _imageSize = effectiveSize;
              _liveOcrResult = ocr;
            });
          }
        });
  }

  void _acceptLiveResults() {
    if (_liveOcrResult == null) return;

    _scanned = true;
    _cameraController?.stopImageStream();

    setState(() {
      _isScanMode = false;
      if (_liveOcrResult!.cardNumber != null) {
        _cardNumberController.text = _liveOcrResult!.cardNumber!;
        _selectedBarcodeType = BarcodeType.displayOnly;
        _checkPaymentCard(_liveOcrResult!.cardNumber!);
      }
      _applyOcrResult(_liveOcrResult!);
    });
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

  void _checkPaymentCard(String number) {
    if (LuhnValidator.isValid(number) && BinDetector.isPaymentCard(number)) {
      setState(() => _paymentCardError = _paymentCardMessage);
    } else {
      setState(() => _paymentCardError = null);
    }
  }

  void _switchToManual() {
    _cameraController?.stopImageStream();
    _stopCamera();
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
      // Run barcode detection and OCR in parallel using ML Kit directly.
      final barcodeScanner = BarcodeScanner();
      final inputImage = InputImage.fromFilePath(image.path);
      try {
        final results = await Future.wait([
          barcodeScanner.processImage(inputImage),
          OcrService.extractCardInfo(image.path),
        ]);
        final barcodes = results[0] as List<Barcode>;
        final ocr = results[1] as OcrResult?;

        final scanResult = ScannerService.extractResult(barcodes);

        if (scanResult != null) {
          setState(() {
            _scanned = true;
            _isScanMode = false;
            _cardNumberController.text = scanResult.cardNumber;
            _selectedBarcodeType = scanResult.barcodeType;
          });
          _stopCamera();
          _checkPaymentCard(scanResult.cardNumber);
          if (ocr != null && mounted) _applyOcrResult(ocr);
        } else if (ocr?.cardNumber != null) {
          setState(() {
            _scanned = true;
            _isScanMode = false;
            _cardNumberController.text = ocr!.cardNumber!;
            _selectedBarcodeType = BarcodeType.displayOnly;
          });
          _stopCamera();
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
        barcodeScanner.close();
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
    final colors = context.colors;

    if (_cameraError != null) {
      return _buildCameraError(colors);
    }

    if (!_cameraInitialised || _cameraController == null) {
      return Center(child: CircularProgressIndicator(color: colors.accent));
    }

    return Column(
      children: [
        Expanded(
          child: ClipRect(
            child: Stack(
              fit: StackFit.expand,
              alignment: Alignment.center,
              children: [
                // Camera preview.
                CameraPreview(_cameraController!),
                // Live text overlay (filtered to card-relevant blocks only).
                if (_liveRelevantBoxes.isNotEmpty)
                  CustomPaint(
                    painter: TextOverlayPainter(
                      relevantBoxes: _liveRelevantBoxes,
                      imageSize: _imageSize,
                      color: colors.accent,
                    ),
                  ),
                // Viewfinder card guide.
                IgnorePointer(
                  child: Center(
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
                ),
              ],
            ),
          ),
        ),
        // Status bar and gallery button.
        ScanStatusBar(
          ocrResult: _liveOcrResult,
          onAccept: _liveOcrResult?.cardNumber != null
              ? _acceptLiveResults
              : null,
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 16, top: 4),
          child: Column(
            children: [
              if (_liveOcrResult == null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Text(
                    'Point your camera at a card to scan it.',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, color: colors.textMuted),
                  ),
                ),
              TextButton.icon(
                onPressed: _analyzingImage ? null : _scanFromImage,
                icon: _analyzingImage
                    ? SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colors.accent,
                        ),
                      )
                    : const Icon(Icons.photo_library_outlined),
                label: const Text('From gallery'),
                style: TextButton.styleFrom(foregroundColor: colors.accent),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildCameraError(CardStashColors colors) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.camera_alt_outlined, size: 48, color: colors.textMuted),
            const SizedBox(height: 16),
            Text(
              _cameraError!,
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 16, color: colors.textMuted),
            ),
            const SizedBox(height: 24),
            OutlinedButton(
              onPressed: _switchToManual,
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: colors.accent),
              ),
              child: Text(
                'Enter manually',
                style: TextStyle(color: colors.accent),
              ),
            ),
          ],
        ),
      ),
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

  String _cameraErrorMessage(CameraException error) {
    if (error.code == 'CameraAccessDenied') {
      return 'Camera permission is required to scan cards. '
          'You can grant it in Settings, or enter the card manually.';
    }
    return 'Could not access the camera. '
        'You can enter the card details manually instead.';
  }
}
