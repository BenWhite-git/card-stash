// ABOUTME: Cryptographic utilities for export/import encryption.
// ABOUTME: Argon2id KDF, AES-256-GCM encrypt/decrypt, HMAC-SHA256 sign/verify.

import 'dart:math';
import 'dart:typed_data';

import 'package:cryptography/cryptography.dart';

/// Result of Argon2id key derivation: separate keys for encryption and signing.
class DerivedKeys {
  final SecretKey encryptionKey;
  final SecretKey hmacKey;
  final Uint8List salt;
  final Uint8List _encryptionKeyBytes;
  final Uint8List _hmacKeyBytes;

  DerivedKeys._({
    required this.encryptionKey,
    required this.hmacKey,
    required this.salt,
    required Uint8List encryptionKeyBytes,
    required Uint8List hmacKeyBytes,
  }) : _encryptionKeyBytes = encryptionKeyBytes,
       _hmacKeyBytes = hmacKeyBytes;

  Uint8List get encryptionKeyBytes => _encryptionKeyBytes;
  Uint8List get hmacKeyBytes => _hmacKeyBytes;
}

/// Result of AES-256-GCM encryption.
class EncryptedData {
  final Uint8List ciphertext;
  final Uint8List nonce;
  final Uint8List mac;

  const EncryptedData({
    required this.ciphertext,
    required this.nonce,
    required this.mac,
  });
}

class CryptoUtils {
  // Argon2id parameters - tune on low-end device, target <1s.
  static const argon2Memory = 65536; // 64 MiB
  static const argon2Parallelism = 2;
  static const argon2Iterations = 3;
  static const saltLength = 16;
  static const keyLength = 32; // 256 bits

  /// Derives two 256-bit keys from a passphrase using Argon2id.
  /// Bytes 0-31 are the AES encryption key, bytes 32-63 are the HMAC key.
  /// A random 16-byte salt is generated if none is provided.
  static Future<DerivedKeys> deriveKeys(
    String passphrase, {
    Uint8List? salt,
  }) async {
    final effectiveSalt = salt ?? _generateSalt();

    final algorithm = Argon2id(
      memory: argon2Memory,
      parallelism: argon2Parallelism,
      iterations: argon2Iterations,
      hashLength: keyLength * 2, // 64 bytes: 32 for AES + 32 for HMAC
    );

    final secretKey = await algorithm.deriveKey(
      secretKey: SecretKey(passphrase.codeUnits),
      nonce: effectiveSalt,
    );

    final keyBytes = Uint8List.fromList(await secretKey.extractBytes());
    final encBytes = Uint8List.sublistView(keyBytes, 0, keyLength);
    final hmacBytes = Uint8List.sublistView(keyBytes, keyLength, keyLength * 2);

    return DerivedKeys._(
      encryptionKey: SecretKey(encBytes),
      hmacKey: SecretKey(hmacBytes),
      salt: effectiveSalt,
      encryptionKeyBytes: Uint8List.fromList(encBytes),
      hmacKeyBytes: Uint8List.fromList(hmacBytes),
    );
  }

  /// AES-256-GCM encrypt.
  static Future<EncryptedData> encrypt(
    Uint8List plaintext,
    SecretKey key,
  ) async {
    final algorithm = AesGcm.with256bits();
    final secretBox = await algorithm.encrypt(plaintext, secretKey: key);

    return EncryptedData(
      ciphertext: Uint8List.fromList(secretBox.cipherText),
      nonce: Uint8List.fromList(secretBox.nonce),
      mac: Uint8List.fromList(secretBox.mac.bytes),
    );
  }

  /// AES-256-GCM decrypt. Throws on authentication failure.
  static Future<Uint8List> decrypt(EncryptedData data, SecretKey key) async {
    final algorithm = AesGcm.with256bits();
    final secretBox = SecretBox(
      data.ciphertext,
      nonce: data.nonce,
      mac: Mac(data.mac),
    );

    final plaintext = await algorithm.decrypt(secretBox, secretKey: key);
    return Uint8List.fromList(plaintext);
  }

  /// HMAC-SHA256 sign.
  static Future<Uint8List> sign(Uint8List message, SecretKey key) async {
    final algorithm = Hmac.sha256();
    final mac = await algorithm.calculateMac(message, secretKey: key);
    return Uint8List.fromList(mac.bytes);
  }

  /// HMAC-SHA256 verify.
  static Future<bool> verify(
    Uint8List message,
    Uint8List macBytes,
    SecretKey key,
  ) async {
    final algorithm = Hmac.sha256();
    final computed = await algorithm.calculateMac(message, secretKey: key);
    final expected = Mac(macBytes);
    // Constant-time comparison is handled by the Mac equality.
    return computed == expected;
  }

  static Uint8List _generateSalt() {
    final random = Random.secure();
    return Uint8List.fromList(
      List.generate(saltLength, (_) => random.nextInt(256)),
    );
  }
}
