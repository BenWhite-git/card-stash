# Changelog

All notable changes to Card Stash will be documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/). Versioning follows [Semantic Versioning](https://semver.org/).

---

## [Unreleased]

### Added
- Live camera OCR with real-time text overlay - point at any card to see detected text highlighted, with status chips showing found fields
- Barcodes still auto-detected instantly on the live feed; text-only cards now work without extra taps
- Duplicate card number detection with warning dialog on add and edit screens
- Card number is now editable on the edit card screen
- Scan barcode from saved photo (e.g. screenshot) via gallery picker in scan mode
- Light, dark, and system theme support with Appearance picker in Settings
- Card list sorting (most used, A-Z, recently used, newest first) via sort button on home screen
- Custom colour picker with HSV dialog for card backgrounds
- 6 additional preset colours (Lime, Fuchsia, Stone, Sky, Purple, Rose)
- Edit button on card display screen for quicker access to editing
- Auto-capitalise words in card name field

### Changed
- Replaced `mobile_scanner` with `camera` + `google_mlkit_barcode_scanning` for direct frame access and parallel ML Kit processing
- iOS minimum deployment target raised to 15.5 for ML Kit compatibility
- About screen restyled to match the app theme instead of hardcoded light theme
- Save button moved to top of add card form for visibility without scrolling
- Removed Scan button from add card AppBar to prevent accidental taps
- Card number text darkened to black for accessibility on display screen

### Fixed
- External links (Ko-fi, Privacy Policy, GitHub) now open correctly on Android and iOS
- Android adaptive icon foreground uses transparent background for proper mask rendering

---

## [1.0.0] - 2026-03-17

### Added
- Add card via camera scan or manual entry with automatic barcode format detection
- All major barcode formats: QR, Code128, Code39, EAN-13, EAN-8, DataMatrix, PDF417, Aztec, Display Only
- Full-screen card display at maximum brightness with barcode and card number fallback
- Smart sorting: most used cards rise to the top, favourites pinned
- Rename cards, add notes, choose colour and logo
- Optional expiry date with local notifications at 30 days, 7 days, and expiry day
- Alerts tab showing all cards with expiry dates, sorted by soonest first
- Encrypted local storage (AES-256 via Hive CE, key in device secure enclave)
- Payment card detection and rejection (Luhn + BIN check)
- Fuzzy search by card name or issuer
- Encrypted export/import (.cardstash format) for device migration with passphrase-based AES-256-GCM encryption
- One-time onboarding screen with payment card safety warning
- Settings screen with export, import, and about navigation
- About screen with app info, Ko-fi support link, licences, and attribution
- Custom app icon
- WCAG 2.2 AA accessibility: tooltips, semantics labels, contrast ratios

### Security
- Hex signature validation on import (rejects odd-length hex strings)
- Encryption key length validation (detects corrupted keys from secure storage)
- Export temp file cleanup after share completes

### Planned for v1.1.0
- Categories / folders
- Home screen widget (most used card)
- Biometric lock (Face ID / Touch ID / fingerprint)
