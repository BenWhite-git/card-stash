// ABOUTME: Unit tests for ExportManifest model.
// ABOUTME: Tests JSON serialisation, signable message, and validation.

import 'package:card_stash/models/export_manifest.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ExportManifest', () {
    final sampleManifest = ExportManifest(
      version: 1,
      exportedAt: DateTime.utc(2026, 3, 14, 9, 41),
      signature: 'abc123',
      payload: 'base64payload==',
      salt: 'base64salt==',
    );

    test('toJson produces correct structure', () {
      final json = sampleManifest.toJson();
      expect(json['version'], 1);
      expect(json['exported_at'], '2026-03-14T09:41:00.000Z');
      expect(json['signature'], 'abc123');
      expect(json['payload'], 'base64payload==');
      expect(json['salt'], 'base64salt==');
    });

    test('fromJson round-trip preserves all fields', () {
      final json = sampleManifest.toJson();
      final restored = ExportManifest.fromJson(json);

      expect(restored.version, sampleManifest.version);
      expect(restored.exportedAt, sampleManifest.exportedAt);
      expect(restored.signature, sampleManifest.signature);
      expect(restored.payload, sampleManifest.payload);
      expect(restored.salt, sampleManifest.salt);
    });

    test('signableMessage concatenates version, exported_at, and payload', () {
      expect(
        sampleManifest.signableMessage,
        '12026-03-14T09:41:00.000Zbase64payload==',
      );
    });

    test('fromJson throws FormatException on missing version', () {
      final json = sampleManifest.toJson()..remove('version');
      expect(
        () => ExportManifest.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });

    test('fromJson throws FormatException on missing exported_at', () {
      final json = sampleManifest.toJson()..remove('exported_at');
      expect(
        () => ExportManifest.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });

    test('fromJson throws FormatException on missing signature', () {
      final json = sampleManifest.toJson()..remove('signature');
      expect(
        () => ExportManifest.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });

    test('fromJson throws FormatException on missing payload', () {
      final json = sampleManifest.toJson()..remove('payload');
      expect(
        () => ExportManifest.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });

    test('fromJson throws FormatException on missing salt', () {
      final json = sampleManifest.toJson()..remove('salt');
      expect(
        () => ExportManifest.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });

    test('fromJson throws FormatException on unsupported version', () {
      final json = sampleManifest.toJson()..['version'] = 99;
      expect(
        () => ExportManifest.fromJson(json),
        throwsA(isA<FormatException>()),
      );
    });
  });
}
