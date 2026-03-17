// ABOUTME: Unit tests for CryptoUtils - Argon2id KDF, AES-256-GCM, HMAC-SHA256.
// ABOUTME: Tests round-trip encryption, key derivation, signing, and failure cases.

import 'dart:convert';
import 'dart:typed_data';

import 'package:card_stash/utils/crypto_utils.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CryptoUtils', () {
    group('deriveKeys', () {
      test('produces 32-byte encryption and HMAC keys', () async {
        final result = await CryptoUtils.deriveKeys('test-passphrase');
        expect(result.encryptionKeyBytes.length, 32);
        expect(result.hmacKeyBytes.length, 32);
      });

      test('produces 16-byte salt when none provided', () async {
        final result = await CryptoUtils.deriveKeys('test-passphrase');
        expect(result.salt.length, 16);
      });

      test('same passphrase and salt produces same keys', () async {
        final first = await CryptoUtils.deriveKeys('same-pass');
        final second = await CryptoUtils.deriveKeys(
          'same-pass',
          salt: first.salt,
        );
        expect(second.encryptionKeyBytes, first.encryptionKeyBytes);
        expect(second.hmacKeyBytes, first.hmacKeyBytes);
      });

      test(
        'same passphrase with different salt produces different keys',
        () async {
          final first = await CryptoUtils.deriveKeys('same-pass');
          final second = await CryptoUtils.deriveKeys('same-pass');
          // Random salts differ, so keys differ.
          expect(second.encryptionKeyBytes, isNot(first.encryptionKeyBytes));
        },
      );

      test('different passphrases produce different keys', () async {
        final first = await CryptoUtils.deriveKeys('pass-one');
        final second = await CryptoUtils.deriveKeys(
          'pass-two',
          salt: first.salt,
        );
        expect(second.encryptionKeyBytes, isNot(first.encryptionKeyBytes));
        expect(second.hmacKeyBytes, isNot(first.hmacKeyBytes));
      });

      test('encryption key and HMAC key are different', () async {
        final result = await CryptoUtils.deriveKeys('test-passphrase');
        expect(result.encryptionKeyBytes, isNot(result.hmacKeyBytes));
      });
    });

    group('encrypt and decrypt', () {
      test('round-trip returns original plaintext', () async {
        final keys = await CryptoUtils.deriveKeys('round-trip-test');
        final plaintext = utf8.encode('Hello, Card Stash!');

        final encrypted = await CryptoUtils.encrypt(
          Uint8List.fromList(plaintext),
          keys.encryptionKey,
        );
        final decrypted = await CryptoUtils.decrypt(
          encrypted,
          keys.encryptionKey,
        );

        expect(utf8.decode(decrypted), 'Hello, Card Stash!');
      });

      test(
        'encrypting same plaintext twice produces different ciphertext',
        () async {
          final keys = await CryptoUtils.deriveKeys('nonce-test');
          final plaintext = Uint8List.fromList(utf8.encode('duplicate'));

          final first = await CryptoUtils.encrypt(
            plaintext,
            keys.encryptionKey,
          );
          final second = await CryptoUtils.encrypt(
            plaintext,
            keys.encryptionKey,
          );

          expect(second.ciphertext, isNot(first.ciphertext));
        },
      );

      test('wrong key fails decryption', () async {
        final keys1 = await CryptoUtils.deriveKeys('correct-pass');
        final keys2 = await CryptoUtils.deriveKeys('wrong-pass');
        final plaintext = Uint8List.fromList(utf8.encode('secret'));

        final encrypted = await CryptoUtils.encrypt(
          plaintext,
          keys1.encryptionKey,
        );

        expect(
          () => CryptoUtils.decrypt(encrypted, keys2.encryptionKey),
          throwsA(isA<Exception>()),
        );
      });

      test('handles empty plaintext', () async {
        final keys = await CryptoUtils.deriveKeys('empty-test');
        final plaintext = Uint8List(0);

        final encrypted = await CryptoUtils.encrypt(
          plaintext,
          keys.encryptionKey,
        );
        final decrypted = await CryptoUtils.decrypt(
          encrypted,
          keys.encryptionKey,
        );

        expect(decrypted, isEmpty);
      });

      test('handles large plaintext', () async {
        final keys = await CryptoUtils.deriveKeys('large-test');
        final plaintext = Uint8List.fromList(
          List.generate(100000, (i) => i % 256),
        );

        final encrypted = await CryptoUtils.encrypt(
          plaintext,
          keys.encryptionKey,
        );
        final decrypted = await CryptoUtils.decrypt(
          encrypted,
          keys.encryptionKey,
        );

        expect(decrypted, plaintext);
      });
    });

    group('sign and verify', () {
      test('round-trip sign and verify succeeds', () async {
        final keys = await CryptoUtils.deriveKeys('sign-test');
        final message = utf8.encode('message to sign');

        final mac = await CryptoUtils.sign(
          Uint8List.fromList(message),
          keys.hmacKey,
        );
        final valid = await CryptoUtils.verify(
          Uint8List.fromList(message),
          mac,
          keys.hmacKey,
        );

        expect(valid, isTrue);
      });

      test('verify fails with wrong key', () async {
        final keys1 = await CryptoUtils.deriveKeys('key-one');
        final keys2 = await CryptoUtils.deriveKeys('key-two');
        final message = Uint8List.fromList(utf8.encode('test'));

        final mac = await CryptoUtils.sign(message, keys1.hmacKey);
        final valid = await CryptoUtils.verify(message, mac, keys2.hmacKey);

        expect(valid, isFalse);
      });

      test('verify fails with tampered message', () async {
        final keys = await CryptoUtils.deriveKeys('tamper-test');
        final message = Uint8List.fromList(utf8.encode('original'));

        final mac = await CryptoUtils.sign(message, keys.hmacKey);
        final tampered = Uint8List.fromList(utf8.encode('tampered'));
        final valid = await CryptoUtils.verify(tampered, mac, keys.hmacKey);

        expect(valid, isFalse);
      });

      test('verify fails with tampered mac', () async {
        final keys = await CryptoUtils.deriveKeys('mac-tamper');
        final message = Uint8List.fromList(utf8.encode('test'));

        final mac = await CryptoUtils.sign(message, keys.hmacKey);
        // Flip one byte in the mac.
        final tamperedMac = Uint8List.fromList(mac);
        tamperedMac[0] = tamperedMac[0] ^ 0xFF;
        final valid = await CryptoUtils.verify(
          message,
          tamperedMac,
          keys.hmacKey,
        );

        expect(valid, isFalse);
      });

      test('same message and key produces same mac', () async {
        final keys = await CryptoUtils.deriveKeys('deterministic');
        final message = Uint8List.fromList(utf8.encode('consistent'));

        final mac1 = await CryptoUtils.sign(message, keys.hmacKey);
        final mac2 = await CryptoUtils.sign(message, keys.hmacKey);

        expect(mac1, mac2);
      });
    });
  });
}
