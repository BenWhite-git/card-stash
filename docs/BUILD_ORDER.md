# Card Stash — Build Order

This document defines the exact sequence in which Claude Code should build the app. Do not jump ahead. Each phase has acceptance criteria that must pass before moving to the next.

The guiding principle: **get a card scanning and displaying correctly before building anything else.** Everything else is secondary.

---

## Phase 0 — Project Scaffold

**Goal:** Clean Flutter project with the correct structure, dependencies, and configuration in place.

### Tasks

1. Create Flutter project (`flutter create card_stash`)
2. Update `pubspec.yaml` with all dependencies from SPEC.md
3. Create the full directory structure from SPEC.md (`models/`, `providers/`, `screens/`, `services/`, `widgets/`, `utils/`)
4. Add empty placeholder files for all planned Dart files (no implementation yet)
5. Configure iOS `Info.plist`:
   - `NSCameraUsageDescription`
   - UTType + `CFBundleDocumentTypes` for `.cardstash` file association
6. Configure Android `AndroidManifest.xml`:
   - `android:allowBackup="false"`
   - Camera permission (handled by `mobile_scanner` but verify)
7. Add `.gitignore`, confirm no secrets or keys are committed
8. Confirm `flutter analyze` passes with zero warnings on the empty scaffold
9. Confirm `flutter run` launches without errors (blank screen is fine)

### Acceptance criteria
- `flutter analyze` — zero warnings
- `flutter run` — launches on both iOS simulator and Android emulator
- Directory structure matches SPEC.md exactly

---

## Phase 1 — Encrypted Storage Foundation

**Goal:** Hive CE encrypted database initialised with secure key management. This is the architectural foundation — everything else depends on it being correct.

### Tasks

1. Implement `StorageService`:
   - Generate 256-bit encryption key on first launch
   - Store key in device secure enclave via `flutter_secure_storage`
   - Open encrypted Hive CE box using the key
   - Handle key retrieval failure gracefully (clear error state, not a crash)
2. Implement `Card` model (`card.dart`) with all fields from SPEC.md
3. Implement `BarcodeType` enum
4. Run `dart run build_runner build` to generate `card.g.dart`
5. Implement `CardProvider` (Riverpod) with full CRUD:
   - `watchCards()` — stream sorted by `usageCount` desc, favourites pinned
   - `addCard(Card)`
   - `updateCard(Card)` 
   - `deleteCard(String id)`
   - `incrementUsage(String id)`
6. Write unit tests for `CardProvider` CRUD operations
7. Add first-launch flag (shared preferences) — used later for onboarding

### Acceptance criteria
- App launches, Hive box opens without errors
- Cards can be created, read, updated, deleted via provider in tests
- Uninstall app → reinstall → database is empty (key was destroyed)
- `flutter analyze` — zero warnings

---

## Phase 2 — Card Display Screen

**Goal:** The most critical screen. A card number renders as a correct, scannable barcode at full brightness. Everything else is polish.

### Tasks

1. Implement `BrightnessService`:
   - `setMaxBrightness()` — save current level, force to 1.0
   - `restoreBrightness()` — restore saved level
   - Must restore on: back navigation, swipe dismiss, any error path
2. Implement `BarcodeView` widget:
   - Renders barcode using `barcode_widget` at maximum safe width
   - Preserves quiet zones — do **not** add margin or padding that compresses them
   - Card number displayed in large `JetBrains Mono` text below barcode
   - `displayOnly` type shows card number only, no barcode
3. Implement `CardDisplayScreen`:
   - Full-screen takeover
   - Calls `BrightnessService.setMaxBrightness()` on `initState`
   - Calls `BrightnessService.restoreBrightness()` in `dispose`
   - Calls `CardProvider.incrementUsage()` on open
   - Single tap to dismiss
   - Shows card name, barcode, card number, last used, expiry, note
4. **Real-device test:** Scan EAN-13, Code128, and QR barcodes at a real scanner before proceeding. Fix any quiet zone or rendering issues now.

### Acceptance criteria
- EAN-13, Code128, QR all scan correctly at a real point-of-sale scanner or barcode scanner app
- Brightness restores correctly in all dismiss scenarios
- `usageCount` increments on every open

---

## Phase 3 — Home Screen (Card List)

**Goal:** Card list that sorts correctly, searches, and navigates to Card Display.

### Tasks

1. Implement `CardTile` widget:
   - Card name, note indicator (if `notes` non-empty), usage dots
   - Expiry warning badge (amber ≤30 days, red ≤7 days)
   - Favourite badge
   - Correct sort order: favourites pinned, then `usageCount` desc
2. Implement `HomeScreen`:
   - Card list from `CardProvider.watchCards()`
   - Fuzzy search on `name` and `issuer` (filter as user types)
   - Section headers: "Pinned" (if any favourites) + "Most Used"
   - Tap → `CardDisplayScreen`
   - Long press → contextual menu (Edit / Share / Toggle Favourite / Delete with confirmation)
   - FAB → `AddCardScreen` (stubbed for now)
   - Bottom nav bar (Cards / Alerts / About)
3. Empty state (no cards yet) — friendly prompt to add first card

### Acceptance criteria
- Cards sort correctly (favourites pinned, then by usage count)
- Search filters correctly as user types
- Long press menu works for all actions
- Empty state displays when no cards

---

## Phase 4 — Add Card Screen

**Goal:** User can add a card by scanning or manual entry. Payment card rejection is implemented here.

### Tasks

1. Implement `LuhnValidator` (`luhn_validator.dart`) — pure Dart, unit tested
2. Implement `BinDetector` (`bin_detector.dart`) — pure Dart, unit tested
3. Implement `ScannerService` — wraps `mobile_scanner`:
   - Returns card number + detected `BarcodeType`
   - Handles camera permission denied gracefully
4. Implement `BarcodeTypeHelper` (`barcode_type_helper.dart`):
   - Maps `mobile_scanner` format to `BarcodeType` enum
   - Default to `code128` for unrecognised formats
5. Implement `AddCardScreen`:
   - Camera scan mode (animated viewfinder, `mobile_scanner`)
   - Manual entry mode (card number field, barcode type chips, colour picker, note, expiry)
   - Payment card detection on every keystroke of card number — hard reject with correct copy if triggered
   - On scan: auto-populate card number and barcode type, prompt for name
   - On save: write to Hive via `CardProvider.addCard()`
6. Implement `OnboardingScreen`:
   - Single screen, shown once on first launch
   - Payment card warning copy
   - "Got it" button → sets first-launch flag → navigates to Home

### Acceptance criteria
- Visa, Mastercard, Amex, Maestro card numbers are rejected
- Scan correctly identifies barcode type for EAN-13, Code128, QR
- Manual entry saves and card appears in Home list
- Onboarding shown exactly once

---

## Phase 5 — Edit Card Screen

**Goal:** User can rename, annotate, and reconfigure any card.

### Tasks

1. Implement `EditCardScreen`:
   - Editable name field
   - Editable notes field
   - Colour picker
   - Logo image picker (via `image_picker`)
   - Barcode type selector (chips, same as Add)
   - Expiry date picker (optional, clearable)
   - Save → `CardProvider.updateCard()` → reschedule notifications → pop
   - Delete with confirmation → `CardProvider.deleteCard()` → cancel notifications → pop to Home
2. Wire up long-press Edit from `HomeScreen`

### Acceptance criteria
- All fields save and persist correctly
- Delete removes card and returns to Home
- Notifications rescheduled on expiry date change (Phase 6 dependency — stub if not yet built)

---

## Phase 6 — Expiry Notifications

> **Read `docs/PHASE_NOTES.md#phase-6` before starting.**

**Goal:** Scheduled local notifications for card expiry.

### Tasks

1. Implement `NotificationService`:
   - Request permission on first notification schedule (iOS)
   - `scheduleCardNotifications(Card)` — schedules at 30 days, 7 days, expiry day
   - `cancelCardNotifications(Card)` — cancels by stored `notificationIds`
   - `cancelAllNotifications()` — used on full data wipe
2. Update `CardProvider`:
   - Call `scheduleCardNotifications()` on `addCard()` and `updateCard()` when expiry set
   - Call `cancelCardNotifications()` on `deleteCard()`
3. Store `notificationIds` on the `Card` model (already in schema)
4. Handle iOS permission denial gracefully — no crash, note in Edit screen that notifications require permission

### Acceptance criteria
- Notifications fire at correct intervals on a real device
- Cancels correctly on card delete
- Reschedules correctly on expiry date edit
- iOS permission denial does not crash or degrade other functionality

---

## Phase 7 — Settings, Export and Import

> **Read `docs/PHASE_NOTES.md#phase-7` before starting.**

**Goal:** User can migrate to a new device. This is a v1.0 requirement.

### Tasks

1. Implement `CryptoUtils` (`crypto_utils.dart`):
   - Argon2id KDF — benchmark parameters on a low-end device, target <1 second
   - AES-256-GCM encrypt/decrypt
   - HMAC-SHA256 sign/verify
   - Unit tested for correctness
2. Implement `ExportManifest` model (`export_manifest.dart`) — `.cardstash` file envelope
3. Implement `ExportService`:
   - Serialise all cards to JSON
   - Encrypt with passphrase-derived key
   - Sign with HMAC
   - Write `.cardstash` file to temp directory
   - Trigger OS share sheet via `share_plus`
4. Implement `ImportService`:
   - Accept `.cardstash` file path
   - Verify HMAC signature first (fail fast on wrong passphrase)
   - Decrypt and deserialise
   - Normalise card numbers (strip spaces/hyphens) before duplicate check
   - Merge or Replace All
5. Implement `PassphraseField` widget — secure text input with show/hide toggle
6. Implement `ExportScreen`:
   - Passphrase entry + confirmation
   - Clear warning: "You'll need this passphrase to restore your cards. There's no way to recover it if you forget it."
   - AirDrop tip on iOS
   - Trigger export on confirm
7. Implement `ImportScreen`:
   - File picker (`.cardstash`)
   - Passphrase entry
   - Merge / Replace All choice with clear explanation of each
   - Progress indicator during decrypt (Argon2id is intentionally slow)
8. Implement `SettingsScreen`:
   - Export cards → `ExportScreen`
   - Import cards → `ImportScreen`
   - Link to `AboutScreen`
9. Wire Settings into bottom nav / Home screen

### Acceptance criteria
- Export → import cycle restores all cards correctly on a fresh install
- Wrong passphrase fails at HMAC verification with clear error message
- Merge skips exact duplicates (normalised card number match)
- Replace All clears existing cards before importing

---

## Phase 8 — About Screen

> **Read `docs/PHASE_NOTES.md#phase-8` before starting.**

**Goal:** Consistent with Ben White app portfolio pattern.

### Tasks

1. Add `package_info_plus` to dependencies
2. Implement `AboutScreen`:
   - App icon, name, dynamic version from `package_info_plus`
   - Description card: "A simple app to stash your loyalty and membership cards. Built in Cheshire, England."
   - Support card: Ko-fi outlined button → `https://ko-fi.com/benwhitelabs`
   - Legal card: Privacy Policy link, Open Source Licences (Flutter OSS screen), GitHub link
   - Footer: "Open source. MIT Licence." + "© 2026 Ben White. All rights reserved."
   - Always light theme regardless of system theme — matches Sunlight pattern
3. Wire About into Settings and bottom nav

### Acceptance criteria
- Version number is dynamic, not hardcoded
- Ko-fi link opens correctly
- OSS licences screen shows all dependencies
- Light theme holds regardless of device theme setting

---

## Phase 9 — Polish and Pre-Release

> **Read `docs/PHASE_NOTES.md#phase-9` before starting.**

**Goal:** App is ready for open source publication and optional store submission.

### Tasks

1. Full accessibility audit (WCAG 2.2 AA):
   - All interactive elements have semantic labels
   - Colour contrast meets 4.5:1 for normal text, 3:1 for large
   - `BarcodeView` has an accessibility label with the card number
   - Focus order is logical throughout
2. Run `flutter analyze` — zero warnings
3. Run full test suite — all passing
4. Test on real iOS device: scan EAN-13, Code128, QR at real scanner
5. Test on real Android device: same
6. Test export → import cycle across iOS → iOS, Android → Android, iOS → Android
7. Test widget barcode brightness on both platforms
8. Write `CHANGELOG.md` v1.0.0 entry
9. Tag `v1.0.0` in git
10. Write Play Store / App Store listing copy (if publishing)

---

## v1.1 Phases (Post-Launch)

Build in this order if/when pursued:

| Feature | Dependency |
|---|---|
| Biometric lock (`local_auth`) | Phase 1 (storage) |
| Duplicate card detection | Phase 3 (home screen) |
| Categories / folders | Phase 3 (home screen) |
| Home screen widget | Phase 2 (card display), Phase 1 (storage) |
| On-device OCR (`google_mlkit_text_recognition`) | Phase 4 (add card), scan-from-image |

---

## Build Rules

- **Never skip an acceptance criteria check** before moving to the next phase
- **Test on real hardware** at Phase 2 (barcodes) and Phase 9 (full regression) — simulators are insufficient for camera and brightness testing
- **Run `dart format . && flutter analyze`** before ending every session
- **Update `ARCHITECTURE.md`** if any technical decision changes during build
- **Update `CHANGELOG.md`** as features are completed, not retrospectively
