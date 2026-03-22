// ABOUTME: Card import service for restoring from .cardstash files.
// ABOUTME: Verifies HMAC, decrypts, deserialises, supports merge and replace.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:uuid/uuid.dart';

import '../utils/card_number_utils.dart';

import '../models/card.dart';
import '../models/export_manifest.dart';
import '../services/notification_service.dart';
import '../services/storage_service.dart';
import '../providers/notification_provider.dart';
import '../utils/bin_detector.dart';
import '../utils/crypto_utils.dart';
import '../utils/luhn_validator.dart';

enum ImportMode { replaceAll, merge }

class ImportResult {
  final int totalCards;
  final int importedCards;
  final int skippedDuplicates;
  final int skippedPaymentCards;

  const ImportResult({
    required this.totalCards,
    required this.importedCards,
    required this.skippedDuplicates,
    required this.skippedPaymentCards,
  });
}

class ImportSignatureException implements Exception {
  final String message;
  const ImportSignatureException(this.message);
  @override
  String toString() => 'ImportSignatureException: $message';
}

class ImportFormatException implements Exception {
  final String message;
  const ImportFormatException(this.message);
  @override
  String toString() => 'ImportFormatException: $message';
}

final importServiceProvider = Provider<ImportService>((ref) {
  return ImportService(
    ref.read(storageServiceProvider).box,
    ref.read(notificationServiceProvider),
  );
});

class ImportService {
  final Box<LoyaltyCard> _box;
  final NotificationService _notifications;

  ImportService(this._box, this._notifications);

  /// Returns true if the card number looks like a payment card.
  static bool _isPaymentCard(String number) {
    return LuhnValidator.isValid(number) && BinDetector.isPaymentCard(number);
  }

  /// Import cards from a .cardstash file.
  /// Verifies HMAC before attempting decryption.
  Future<ImportResult> importCards(
    String filePath,
    String passphrase,
    ImportMode mode,
  ) async {
    // 1. Read and parse the manifest.
    final ExportManifest manifest;
    try {
      final file = File(filePath);
      final contents = await file.readAsString();
      final json = jsonDecode(contents) as Map<String, dynamic>;
      manifest = ExportManifest.fromJson(json);
    } on FormatException catch (e) {
      throw ImportFormatException(e.message);
    } catch (e) {
      throw ImportFormatException('Failed to read file: $e');
    }

    // 2. Re-derive keys from passphrase + stored salt.
    final salt = Uint8List.fromList(base64Decode(manifest.salt));
    final keys = await CryptoUtils.deriveKeys(passphrase, salt: salt);

    // 3. Verify HMAC first - fail fast on wrong passphrase.
    final signableMessage = manifest.signableMessage;
    final signatureBytes = _hexToBytes(manifest.signature);
    final valid = await CryptoUtils.verify(
      Uint8List.fromList(utf8.encode(signableMessage)),
      signatureBytes,
      keys.hmacKey,
    );
    if (!valid) {
      throw const ImportSignatureException(
        'Wrong passphrase or corrupted file.',
      );
    }

    // 4. Decrypt payload.
    final payloadBytes = base64Decode(manifest.payload);
    // Payload format: nonce (12 bytes) + mac (16 bytes) + ciphertext.
    const nonceLength = 12;
    const macLength = 16;
    if (payloadBytes.length < nonceLength + macLength) {
      throw const ImportFormatException('Payload too short.');
    }
    final nonce = Uint8List.sublistView(payloadBytes, 0, nonceLength);
    final mac = Uint8List.sublistView(
      payloadBytes,
      nonceLength,
      nonceLength + macLength,
    );
    final ciphertext = Uint8List.sublistView(
      payloadBytes,
      nonceLength + macLength,
    );

    final encrypted = EncryptedData(
      ciphertext: ciphertext,
      nonce: nonce,
      mac: mac,
    );
    final plaintext = await CryptoUtils.decrypt(encrypted, keys.encryptionKey);

    // 5. Deserialise cards.
    final List<dynamic> cardJsonList;
    try {
      cardJsonList = jsonDecode(utf8.decode(plaintext)) as List<dynamic>;
    } catch (e) {
      throw ImportFormatException('Failed to parse card data: $e');
    }

    final allCards = cardJsonList
        .map((j) => LoyaltyCard.fromExportJson(j as Map<String, dynamic>))
        .toList();
    final cards = allCards.where((c) => !_isPaymentCard(c.cardNumber)).toList();
    final skippedPaymentCards = allCards.length - cards.length;

    // 6. Apply import mode.
    switch (mode) {
      case ImportMode.replaceAll:
        return _replaceAll(cards, skippedPaymentCards: skippedPaymentCards);
      case ImportMode.merge:
        return _merge(cards, skippedPaymentCards: skippedPaymentCards);
    }
  }

  Future<ImportResult> _replaceAll(
    List<LoyaltyCard> cards, {
    required int skippedPaymentCards,
  }) async {
    // Cancel notifications for all existing cards.
    for (final existing in _box.values) {
      await _notifications.cancelCardNotifications(existing);
    }

    // Clear the box.
    await _box.clear();

    // Import all cards.
    for (final card in cards) {
      await _box.put(card.id, card);
    }

    return ImportResult(
      totalCards: cards.length + skippedPaymentCards,
      importedCards: cards.length,
      skippedDuplicates: 0,
      skippedPaymentCards: skippedPaymentCards,
    );
  }

  Future<ImportResult> _merge(
    List<LoyaltyCard> cards, {
    required int skippedPaymentCards,
  }) async {
    final existingNumbers = _box.values
        .map((c) => normaliseCardNumber(c.cardNumber))
        .toSet();

    var imported = 0;
    var skipped = 0;

    for (final card in cards) {
      final normalised = normaliseCardNumber(card.cardNumber);
      if (existingNumbers.contains(normalised)) {
        skipped++;
        continue;
      }

      // Generate a new UUID if the ID already exists in the box.
      var cardToStore = card;
      if (_box.containsKey(card.id)) {
        cardToStore = LoyaltyCard(
          id: const Uuid().v4(),
          name: card.name,
          issuer: card.issuer,
          cardNumber: card.cardNumber,
          barcodeType: card.barcodeType,
          colourValue: card.colourValue,
          expiryDate: card.expiryDate,
          usageCount: card.usageCount,
          lastUsed: card.lastUsed,
          createdAt: card.createdAt,
          notes: card.notes,
          isFavourite: card.isFavourite,
        );
      }

      await _box.put(cardToStore.id, cardToStore);
      existingNumbers.add(normalised);
      imported++;
    }

    return ImportResult(
      totalCards: cards.length + skippedPaymentCards,
      importedCards: imported,
      skippedDuplicates: skipped,
      skippedPaymentCards: skippedPaymentCards,
    );
  }

  static Uint8List _hexToBytes(String hex) {
    if (hex.length % 2 != 0) {
      throw const ImportFormatException('Invalid signature format.');
    }
    final bytes = <int>[];
    for (var i = 0; i < hex.length; i += 2) {
      bytes.add(int.parse(hex.substring(i, i + 2), radix: 16));
    }
    return Uint8List.fromList(bytes);
  }
}
