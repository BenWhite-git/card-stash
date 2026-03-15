# Changelog

All notable changes to Card Stash will be documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/). Versioning follows [Semantic Versioning](https://semver.org/).

---

## [Unreleased]

### Added
- Project scaffold: Flutter project with full directory structure
- All dependencies declared in pubspec.yaml
- iOS: camera permission, .cardstash UTType and CFBundleDocumentTypes
- Android: allowBackup disabled
- Placeholder files for all planned Dart modules
- Smoke test for app launch
- LoyaltyCard model with all fields from spec (id, name, issuer, cardNumber, barcodeType, colour, logoPath, expiryDate, usageCount, lastUsed, createdAt, notes, isFavourite, notificationIds)
- BarcodeType enum: qrCode, code128, code39, ean13, ean8, dataMatrix, pdf417, aztec, displayOnly
- Hive CE generated type adapters for LoyaltyCard and BarcodeType
- StorageService: encrypted Hive box with 256-bit key stored in device secure enclave
- CardListNotifier (Riverpod): full CRUD with sorted card list (favourites pinned, then usage count descending)
- First-launch flag via SharedPreferences for onboarding
- Unit tests for all CardProvider CRUD operations (10 tests)

### Planned for v1.0.0
- Add card via camera scan or manual entry
- Barcode display: full screen, maximum brightness, all major formats
- Card list sorted by usage count; favourites pinned
- Rename cards and add notes
- Optional expiry date with notifications (30 days, 7 days, expiry day)
- Encrypted local storage (AES-256 via Hive CE)
- Payment card detection and rejection (Luhn + BIN)
- Fuzzy search by card name or issuer
- Card colour and logo customisation

### Planned for v1.1.0
- Categories / folders
- Encrypted local backup and restore
- Home screen widget (most used card)
- Duplicate card number detection
- Biometric lock (Face ID / Touch ID / fingerprint)
