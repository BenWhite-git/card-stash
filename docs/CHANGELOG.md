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
- BrightnessService: save/force max/restore screen brightness via screen_brightness package
- BarcodeView widget: renders all barcode types at max safe width with quiet zones preserved, card number fallback text, displayOnly mode
- CardDisplayScreen: full-screen card display with max brightness, card name, barcode, number, expiry, notes, tap to dismiss
- Widget tests for BarcodeView (12 tests), BrightnessService (7 tests), CardDisplayScreen (12 tests)
- ExpiryBadge widget: amber badge for 30 days or less, red for 7 days or less, expired state
- CardTile widget: card name, colour accent, favourite star, note indicator, expiry badge, tap and long-press callbacks
- HomeScreen: card list sorted by usage (favourites pinned), fuzzy search on name and issuer, section headers (Pinned/Most Used), empty state, long-press action sheet (Edit/Share/Toggle Favourite/Delete with confirmation), FAB to add card
- go_router navigation with bottom nav bar (Cards, Alerts, About), card display as full-screen overlay
- NotificationsScreen placeholder for Alerts tab
- Sunlight dark theme applied to app shell and navigation bar
- Widget tests for ExpiryBadge (10 tests), CardTile (9 tests), HomeScreen (12 tests)
- LuhnValidator: pure Dart Luhn algorithm for payment card number detection
- BinDetector: BIN range matching for Visa, Mastercard, Amex, Maestro, Discover
- BarcodeTypeHelper: maps mobile_scanner formats to BarcodeType enum (defaults to Code 128 for unknown formats)
- ScannerService: wraps mobile_scanner, returns card number and detected barcode type
- AddCardScreen: camera scan mode with viewfinder overlay, manual entry mode with card name, number, barcode type chips, colour picker, expiry date picker, notes field
- Payment card rejection: real-time Luhn + BIN check on card number input with hard rejection and error message
- OnboardingScreen: first-launch-only screen with payment card warning and "Got it" dismissal
- Router updated to show onboarding on first launch, then navigate to home
- Unit tests for LuhnValidator (13 tests), BinDetector (20 tests), BarcodeTypeHelper (11 tests)
- Widget tests for AddCardScreen (12 tests), OnboardingScreen (8 tests)
- EditCardScreen: edit card name, notes, colour, barcode type, expiry date, logo; card number displayed read-only
- Delete card with confirmation dialog from edit screen
- Long-press Edit action on HomeScreen wired to EditCardScreen
- Route: /cards/:id/edit added to go_router (full-screen, outside shell)
- Widget tests for EditCardScreen (14 tests)
- NotificationService: expiry notification scheduling at 30 days, 7 days, and expiry day with correct edge case handling (past dates, near-expiry cards)
- NotificationProvider: Riverpod provider wrapping NotificationService for dependency injection
- CardProvider integration: addCard schedules notifications and stores IDs, updateCard cancels and reschedules, deleteCard cancels
- EditCardScreen: notification permission check with informational note when iOS notifications are denied
- Timezone initialization for scheduled notification delivery at 9:00 AM local time
- Shared StubNotificationService test helper for widget tests
- Unit tests for notification scheduling logic (13 tests), CardProvider notification integration (7 tests)
- CryptoUtils: Argon2id KDF with dual-key derivation, AES-256-GCM encrypt/decrypt, HMAC-SHA256 sign/verify
- ExportManifest model for .cardstash file envelope with version, timestamp, signature, encrypted payload, and salt
- Card serialisation: toExportJson/fromExportJson on LoyaltyCard (excludes logoPath and notificationIds)
- PassphraseField widget: secure text input with show/hide toggle for export/import
- ExportService: serialise all cards, encrypt with passphrase, sign with HMAC, write .cardstash file, share via OS share sheet
- ImportService: verify HMAC first (fail-fast on wrong passphrase), decrypt, deserialise, merge or replace-all modes with card number normalisation
- SettingsScreen: export cards, import cards, about navigation
- ExportScreen: passphrase entry with confirmation, validation (match + 8 char min), warning about passphrase recovery, AirDrop tip on iOS
- ImportScreen: file picker, passphrase entry, replace-all/merge mode selection with explanations, result and error display
- Settings tab replaces About in bottom nav (About accessible from Settings)
- Routes: /settings, /settings/export, /settings/import, /settings/about
- Android intent-filter for .cardstash file association
- FilePickerService wrapper for testability
- Replaced pointycastle with cryptography package (better Argon2id/AES-GCM/HMAC support)
- Unit tests for CryptoUtils (16 tests), ExportManifest (9 tests), card serialisation (9 tests), ExportService (4 tests), ImportService (14 tests)
- Widget tests for PassphraseField (6 tests), SettingsScreen (5 tests), ExportScreen (9 tests), ImportScreen (9 tests)
- AboutScreen: app info, version (via package_info_plus), description, Ko-fi support link, legal rows (Privacy Policy, Open Source Licences, GitHub), MIT licence footer, copyright
- Always-light Sunlight theme on About screen using Theme widget override
- Custom app icon: cropped from source, generated launcher icons for iOS and Android via flutter_launcher_icons
- Widget tests for AboutScreen (13 tests)

### Planned for v1.0.0
- Add card via camera scan or manual entry
- Barcode display: full screen, maximum brightness, all major formats
- Rename cards and add notes
- Optional expiry date with notifications (30 days, 7 days, expiry day)
- Encrypted local storage (AES-256 via Hive CE)
- Payment card detection and rejection (Luhn + BIN)
- Fuzzy search by card name or issuer
- Card colour and logo customisation
- Encrypted export/import for device migration

### Planned for v1.1.0
- Categories / folders
- Home screen widget (most used card)
- Duplicate card number detection
- Biometric lock (Face ID / Touch ID / fingerprint)
