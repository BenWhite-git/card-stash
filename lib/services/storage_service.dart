// ABOUTME: Hive CE initialization and encrypted box management.
// ABOUTME: Generates and stores encryption key in device secure enclave.

import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive_ce_flutter/hive_ce_flutter.dart';

import '../hive_registrar.g.dart';
import '../models/card.dart';

const _encryptionKeyName = 'card_stash_encryption_key';
const _boxName = 'cards';

final storageServiceProvider = Provider<StorageService>((ref) {
  throw UnimplementedError(
    'StorageService must be initialised before use. '
    'Override this provider with the initialised instance.',
  );
});

class StorageService {
  final Box<LoyaltyCard> _box;

  StorageService._(this._box);

  /// Creates a StorageService from an already-opened box. Used in tests.
  StorageService.fromBox(Box<LoyaltyCard> box) : _box = box;

  Box<LoyaltyCard> get box => _box;

  static Future<StorageService> init({
    FlutterSecureStorage? secureStorage,
  }) async {
    await Hive.initFlutter();
    Hive.registerAdapters();

    final key = await _getOrCreateKey(
      secureStorage ?? const FlutterSecureStorage(),
    );
    final encryptionCipher = HiveAesCipher(key);

    final box = await Hive.openBox<LoyaltyCard>(
      _boxName,
      encryptionCipher: encryptionCipher,
    );

    return StorageService._(box);
  }

  static Future<List<int>> _getOrCreateKey(
    FlutterSecureStorage secureStorage,
  ) async {
    final existingKey = await secureStorage.read(key: _encryptionKeyName);

    if (existingKey != null) {
      return base64Url.decode(existingKey);
    }

    final key = Hive.generateSecureKey();
    await secureStorage.write(
      key: _encryptionKeyName,
      value: base64UrlEncode(key),
    );
    return key;
  }

  Future<void> close() async {
    await _box.close();
  }
}
