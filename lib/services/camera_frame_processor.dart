// ABOUTME: Processes camera frames through ML Kit barcode and text recognizers.
// ABOUTME: Handles platform-specific frame conversion, throttling, and parallel recognition.

import 'dart:io';

import 'package:camera/camera.dart';
import 'package:flutter/services.dart';
import 'package:google_mlkit_barcode_scanning/google_mlkit_barcode_scanning.dart'
    hide BarcodeType;
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Result of processing a single camera frame through both ML Kit recognizers.
class FrameProcessingResult {
  final List<Barcode> barcodes;
  final RecognizedText? recognizedText;
  final Size imageSize;

  const FrameProcessingResult({
    required this.barcodes,
    required this.recognizedText,
    required this.imageSize,
  });
}

/// Processes camera frames through barcode scanning and text recognition.
///
/// Uses a drop-if-busy pattern with a minimum interval between processing
/// starts to naturally adapt to device speed. Fast phones process ~6fps,
/// slow phones ~2fps.
class CameraFrameProcessor {
  final BarcodeScanner _barcodeScanner = BarcodeScanner();
  final TextRecognizer _textRecognizer = TextRecognizer();

  bool _isProcessing = false;
  DateTime _lastProcessingStart = DateTime(2000);

  static const _minInterval = Duration(milliseconds: 150);

  /// Process a camera frame through both recognizers.
  ///
  /// Returns null if the frame is dropped (previous frame still processing
  /// or minimum interval not elapsed). Otherwise returns barcode and text
  /// recognition results.
  Future<FrameProcessingResult?> processFrame(
    CameraImage image,
    int sensorOrientation,
    DeviceOrientation deviceOrientation,
  ) async {
    if (_isProcessing) return null;

    final now = DateTime.now();
    if (now.difference(_lastProcessingStart) < _minInterval) return null;

    _isProcessing = true;
    _lastProcessingStart = now;

    try {
      final inputImage = _buildInputImage(
        image,
        sensorOrientation,
        deviceOrientation,
      );
      if (inputImage == null) return null;

      final imageSize = Size(image.width.toDouble(), image.height.toDouble());

      final results = await Future.wait([
        _barcodeScanner.processImage(inputImage),
        _textRecognizer.processImage(inputImage),
      ]);

      return FrameProcessingResult(
        barcodes: results[0] as List<Barcode>,
        recognizedText: results[1] as RecognizedText,
        imageSize: imageSize,
      );
    } finally {
      _isProcessing = false;
    }
  }

  /// Build an [InputImage] from a [CameraImage] frame.
  ///
  /// Handles platform-specific format differences:
  /// - Android: NV21 format from planes[0]
  /// - iOS: BGRA8888 format from planes[0]
  InputImage? _buildInputImage(
    CameraImage image,
    int sensorOrientation,
    DeviceOrientation deviceOrientation,
  ) {
    final rotation = _rotationFromNative(sensorOrientation, deviceOrientation);
    if (rotation == null) return null;

    final format = _inputImageFormat(image.format.group);
    if (format == null) return null;

    // For NV21 on Android, we need all planes concatenated.
    // For BGRA8888 on iOS, planes[0] contains all bytes.
    final bytes = image.planes.length == 1
        ? image.planes[0].bytes
        : Uint8List.fromList(
            image.planes.expand((plane) => plane.bytes).toList(),
          );

    return InputImage.fromBytes(
      bytes: bytes,
      metadata: InputImageMetadata(
        size: Size(image.width.toDouble(), image.height.toDouble()),
        rotation: rotation,
        format: format,
        bytesPerRow: image.planes[0].bytesPerRow,
      ),
    );
  }

  /// Map camera sensor orientation and device orientation to ML Kit rotation.
  InputImageRotation? _rotationFromNative(
    int sensorOrientation,
    DeviceOrientation deviceOrientation,
  ) {
    if (Platform.isIOS) {
      return InputImageRotationValue.fromRawValue(sensorOrientation);
    }

    // On Android, combine sensor and device orientations.
    final deviceRotation = _deviceOrientationToDegrees(deviceOrientation);
    final compensated = (sensorOrientation - deviceRotation + 360) % 360;
    return InputImageRotationValue.fromRawValue(compensated);
  }

  int _deviceOrientationToDegrees(DeviceOrientation orientation) {
    switch (orientation) {
      case DeviceOrientation.portraitUp:
        return 0;
      case DeviceOrientation.landscapeLeft:
        return 90;
      case DeviceOrientation.portraitDown:
        return 180;
      case DeviceOrientation.landscapeRight:
        return 270;
    }
  }

  /// Map camera image format group to ML Kit input image format.
  InputImageFormat? _inputImageFormat(ImageFormatGroup group) {
    switch (group) {
      case ImageFormatGroup.nv21:
        return InputImageFormat.nv21;
      case ImageFormatGroup.yuv420:
        return Platform.isAndroid
            ? InputImageFormat.yuv_420_888
            : InputImageFormat.yuv420;
      case ImageFormatGroup.bgra8888:
        return InputImageFormat.bgra8888;
      default:
        return null;
    }
  }

  /// Close both recognizers and release resources.
  Future<void> dispose() async {
    await Future.wait([_barcodeScanner.close(), _textRecognizer.close()]);
  }
}
