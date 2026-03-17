// ABOUTME: Card export service for device migration.
// ABOUTME: Serialises, encrypts with passphrase, signs with HMAC, writes .cardstash file.

import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_ce/hive.dart';
import 'package:share_plus/share_plus.dart';

import '../models/card.dart';
import '../models/export_manifest.dart';
import '../services/storage_service.dart';
import '../utils/crypto_utils.dart';

final exportServiceProvider = Provider<ExportService>((ref) {
  return ExportService(ref.read(storageServiceProvider).box);
});

class ExportService {
  final Box<LoyaltyCard> _box;

  ExportService(this._box);

  /// Serialises all cards to export JSON, excluding device-local fields.
  List<Map<String, dynamic>> serialiseCards() {
    return _box.values.map((card) => card.toExportJson()).toList();
  }

  /// Builds an encrypted, signed .cardstash file and returns it.
  /// Does not trigger the share sheet - call [shareExportFile] separately.
  Future<File> buildExportFile(String passphrase) async {
    final cards = serialiseCards();
    final jsonString = jsonEncode(cards);
    final plaintext = Uint8List.fromList(utf8.encode(jsonString));

    final keys = await CryptoUtils.deriveKeys(passphrase);
    final encrypted = await CryptoUtils.encrypt(plaintext, keys.encryptionKey);

    // Combine nonce + mac + ciphertext into a single blob for the payload.
    final payloadBytes = <int>[
      ...encrypted.nonce,
      ...encrypted.mac,
      ...encrypted.ciphertext,
    ];
    final payload = base64Encode(payloadBytes);

    final exportedAt = DateTime.now().toUtc();
    final salt = base64Encode(keys.salt);

    // Build the signable message and compute HMAC.
    final signableMessage =
        '${ExportManifest.currentVersion}${exportedAt.toIso8601String()}$payload';
    final mac = await CryptoUtils.sign(
      Uint8List.fromList(utf8.encode(signableMessage)),
      keys.hmacKey,
    );
    final signature = mac
        .map((b) => b.toRadixString(16).padLeft(2, '0'))
        .join();

    final manifest = ExportManifest(
      version: ExportManifest.currentVersion,
      exportedAt: exportedAt,
      signature: signature,
      payload: payload,
      salt: salt,
    );

    final tempDir = await Directory.systemTemp.createTemp('cardstash_export_');
    final file = File('${tempDir.path}/cards.cardstash');
    await file.writeAsString(jsonEncode(manifest.toJson()));

    return file;
  }

  /// Shares a .cardstash file via the OS share sheet.
  Future<void> shareExportFile(File file) async {
    await Share.shareXFiles([XFile(file.path)], subject: 'Card Stash Backup');
  }
}
