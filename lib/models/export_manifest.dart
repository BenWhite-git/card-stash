// ABOUTME: Data model for the .cardstash export file envelope.
// ABOUTME: Contains version, timestamp, HMAC signature, encrypted payload, and KDF salt.

class ExportManifest {
  static const currentVersion = 1;

  final int version;
  final DateTime exportedAt;
  final String signature;
  final String payload;
  final String salt;

  const ExportManifest({
    required this.version,
    required this.exportedAt,
    required this.signature,
    required this.payload,
    required this.salt,
  });

  /// The message that gets HMAC-signed: version + exported_at ISO + payload.
  String get signableMessage =>
      '$version${exportedAt.toIso8601String()}$payload';

  Map<String, dynamic> toJson() => {
    'version': version,
    'exported_at': exportedAt.toIso8601String(),
    'signature': signature,
    'payload': payload,
    'salt': salt,
  };

  factory ExportManifest.fromJson(Map<String, dynamic> json) {
    if (!json.containsKey('version')) {
      throw const FormatException('Missing required field: version');
    }
    if (!json.containsKey('exported_at')) {
      throw const FormatException('Missing required field: exported_at');
    }
    if (!json.containsKey('signature')) {
      throw const FormatException('Missing required field: signature');
    }
    if (!json.containsKey('payload')) {
      throw const FormatException('Missing required field: payload');
    }
    if (!json.containsKey('salt')) {
      throw const FormatException('Missing required field: salt');
    }

    final version = json['version'] as int;
    if (version != currentVersion) {
      throw FormatException('Unsupported version: $version');
    }

    return ExportManifest(
      version: version,
      exportedAt: DateTime.parse(json['exported_at'] as String),
      signature: json['signature'] as String,
      payload: json['payload'] as String,
      salt: json['salt'] as String,
    );
  }
}
