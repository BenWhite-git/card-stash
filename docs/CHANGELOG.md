# Changelog

All notable changes to Card Stash will be documented here.

Format follows [Keep a Changelog](https://keepachangelog.com/en/1.0.0/). Versioning follows [Semantic Versioning](https://semver.org/).

---

## [Unreleased]

### Added
- Scan barcode from saved photo (e.g. screenshot) via gallery picker in scan mode

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
- Duplicate card number detection
- Biometric lock (Face ID / Touch ID / fingerprint)
