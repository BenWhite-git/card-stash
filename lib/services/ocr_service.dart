// ABOUTME: On-device OCR service for extracting card info from images.
// ABOUTME: Uses google_mlkit_text_recognition for ML Kit calls, with pure Dart parseText for testable text parsing.

import 'dart:io';
import 'dart:typed_data';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Parsed result from OCR text extraction.
class OcrResult {
  final String? cardNumber;
  final DateTime? expiryDate;
  final String? issuerHint;
  final String rawText;

  const OcrResult({
    this.cardNumber,
    this.expiryDate,
    this.issuerHint,
    required this.rawText,
  });
}

class OcrService {
  OcrService._();

  static const _noiseWords = {
    'MEMBER',
    'CARD',
    'NUMBER',
    'VALID',
    'THRU',
    'EXP',
    'POINTS',
    'REWARD',
    'REWARDS',
    'LOYALTY',
  };

  /// Extract card info from an image file path via ML Kit.
  static Future<OcrResult?> extractCardInfo(String imagePath) async {
    final recognizer = TextRecognizer();
    try {
      final inputImage = InputImage.fromFilePath(imagePath);
      final recognised = await recognizer.processImage(inputImage);
      if (recognised.text.isEmpty) return null;
      return parseText(recognised.text);
    } finally {
      recognizer.close();
    }
  }

  /// Extract card info from JPEG image bytes via ML Kit.
  /// Writes bytes to a temp file since ML Kit requires a file path for
  /// encoded images.
  static Future<OcrResult?> extractCardInfoFromBytes(Uint8List bytes) async {
    final tempDir = await Directory.systemTemp.createTemp('ocr_');
    final tempFile = File('${tempDir.path}/capture.jpg');
    try {
      await tempFile.writeAsBytes(bytes);
      return extractCardInfo(tempFile.path);
    } finally {
      tempDir.delete(recursive: true).ignore();
    }
  }

  /// Parse raw OCR text to extract card number, expiry date, and issuer hint.
  /// Pure Dart - no ML Kit dependency, fully testable.
  static OcrResult? parseText(String rawText) {
    if (rawText.trim().isEmpty) return null;

    final cardNumber = _extractCardNumber(rawText);
    final expiryDate = _extractExpiryDate(rawText);
    final issuerHint = _extractIssuerHint(rawText);

    if (cardNumber == null && expiryDate == null && issuerHint == null) {
      return null;
    }

    return OcrResult(
      cardNumber: cardNumber,
      expiryDate: expiryDate,
      issuerHint: issuerHint,
      rawText: rawText,
    );
  }

  /// Find the longest digit sequence (8+ digits) after stripping spaces and
  /// hyphens.
  static String? _extractCardNumber(String text) {
    // Match sequences of digits, spaces, and hyphens that contain at least
    // one digit.
    final pattern = RegExp(r'[\d][\d \-]*[\d]|[\d]');
    final matches = pattern.allMatches(text);

    String? longest;
    for (final match in matches) {
      final digits = match.group(0)!.replaceAll(RegExp(r'[\s\-]'), '');
      if (digits.length >= 8) {
        if (longest == null || digits.length > longest.length) {
          longest = digits;
        }
      }
    }
    return longest;
  }

  /// Match expiry date patterns: EXP MM/YY, VALID THRU MM/YY, MM/YYYY,
  /// standalone MM/YY.
  static DateTime? _extractExpiryDate(String text) {
    final pattern = RegExp(
      r'(?:(?:EXP(?:IRY)?|VALID\s*THRU)\s*)?(\d{2})\s*/\s*(\d{2,4})\b',
      caseSensitive: false,
    );

    for (final match in pattern.allMatches(text)) {
      final month = int.tryParse(match.group(1)!);
      var year = int.tryParse(match.group(2)!);
      if (month == null || year == null) continue;
      if (month < 1 || month > 12) continue;

      // Convert 2-digit year to 4-digit.
      if (year < 100) {
        year += 2000;
      }

      return DateTime(year, month, 1);
    }
    return null;
  }

  /// Find first text block that contains only letters and spaces, is at least
  /// 3 characters, and is not entirely noise words.
  static String? _extractIssuerHint(String text) {
    final lines = text.split('\n');
    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.length < 3) continue;
      // Must be only letters and spaces.
      if (!RegExp(r'^[a-zA-Z\s]+$').hasMatch(trimmed)) continue;

      // Check that not all words are noise words.
      final words = trimmed.toUpperCase().split(RegExp(r'\s+'));
      final meaningful = words.where((w) => !_noiseWords.contains(w));
      if (meaningful.isEmpty) continue;

      return trimmed;
    }
    return null;
  }
}
