// ABOUTME: Tests for OcrService.extractCardInfoFromBytes temp file lifecycle.
// ABOUTME: Mocks the ML Kit platform channel to observe the file during recognition.

import 'dart:io';

import 'package:card_stash/services/ocr_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('google_mlkit_text_recognizer');
  late bool fileExistedDuringRecognition;
  late String? imagePath;

  setUp(() {
    fileExistedDuringRecognition = false;
    imagePath = null;
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
          if (call.method == 'vision#startTextRecognizer') {
            final imageData = call.arguments['imageData'] as Map;
            imagePath = imageData['path'] as String;
            // A native read is not instantaneous. The temp file must survive
            // until recognition has finished with it.
            await Future<void>.delayed(const Duration(milliseconds: 50));
            fileExistedDuringRecognition = File(imagePath!).existsSync();
            return {'text': '1234 5678 9012 3456', 'blocks': []};
          }
          return null;
        });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('OcrService.extractCardInfoFromBytes', () {
    test('keeps the temp image on disk until recognition completes', () async {
      final result = await OcrService.extractCardInfoFromBytes(
        Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xD9]),
      );

      expect(fileExistedDuringRecognition, isTrue);
      expect(result?.cardNumber, '1234567890123456');
    });

    test('removes the temp image once recognition completes', () async {
      await OcrService.extractCardInfoFromBytes(
        Uint8List.fromList([0xFF, 0xD8, 0xFF, 0xD9]),
      );

      // Deletion is fire-and-forget, so give it a moment to land.
      await Future<void>.delayed(const Duration(milliseconds: 100));
      expect(File(imagePath!).existsSync(), isFalse);
    });
  });
}
