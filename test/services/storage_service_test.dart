// ABOUTME: Unit tests for StorageService encryption key handling.
// ABOUTME: Verifies corrupted key detection and proper error reporting.

import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';

import 'package:card_stash/hive_registrar.g.dart';
import 'package:card_stash/services/storage_service.dart';

/// Fake secure storage that returns a predetermined value for the encryption key.
class FakeSecureStorage extends FlutterSecureStorage {
  final String? storedValue;

  const FakeSecureStorage({this.storedValue});

  @override
  Future<String?> read({
    required String key,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {
    return storedValue;
  }

  @override
  Future<void> write({
    required String key,
    required String? value,
    AppleOptions? iOptions,
    AndroidOptions? aOptions,
    LinuxOptions? lOptions,
    WebOptions? webOptions,
    AppleOptions? mOptions,
    WindowsOptions? wOptions,
  }) async {}
}

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = await Directory.systemTemp.createTemp('storage_service_test_');
    Hive.init(tempDir.path);
    Hive.registerAdapters();
  });

  tearDownAll(() async {
    await Hive.close();
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  group('StorageService', () {
    test('corrupted key (wrong length) throws StateError', () async {
      // 16 bytes encoded as base64url - too short (need 32).
      final shortKey = base64Url.encode(List.filled(16, 0));
      final storage = FakeSecureStorage(storedValue: shortKey);

      expect(
        () => StorageService.init(secureStorage: storage, skipHiveInit: true),
        throwsA(
          isA<StateError>().having(
            (e) => e.message,
            'message',
            contains('corrupted'),
          ),
        ),
      );
    });
  });
}
