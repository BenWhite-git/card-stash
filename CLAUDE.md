# Card Stash — Claude Code Instructions

This file governs how Claude Code should behave when working on this project. Read it fully before making any changes.

---

## Project Summary

App name: **Card Stash**. Bundle ID: `co.benwhite.cardstash` (suggested). GitHub repo: `card-stash`.

This is a local-first Flutter loyalty and membership card wallet for iOS and Android. It is encrypted at rest, has no network calls, and is published as an open source side project under the MIT licence.

All documentation lives in `/docs`. **Read `docs/BUILD_ORDER.md` first** — it defines the exact sequence to build the app with acceptance criteria per phase. Then refer to:

| Document | Purpose |
|---|---|
| `docs/BUILD_ORDER.md` | Exact build sequence with acceptance criteria per phase |
| `docs/SPEC.md` | Full product specification, data model, feature detail |
| `docs/ARCHITECTURE.md` | Technical decision log |
| `docs/SECURITY.md` | Security model and encryption rationale |
| `docs/CONTRIBUTING.md` | Contributor guidance |
| `docs/CHANGELOG.md` | Version history |
| `docs/mockup.html` | UI reference (open in browser) |
| `docs/sunlight-style-guide.md` | Visual design system — follow for all UI decisions |
| `docs/PHASE_NOTES.md` | Pre-implementation notes per phase — read before starting each phase |

---

## Non-Negotiable Constraints

These are hard rules. Do not work around them, do not add exceptions, do not ask whether they apply — they always do.

- **No network calls.** No HTTP clients, no Firebase, no analytics, no remote config, no CDN-hosted assets loaded at runtime.
- **No new platform permissions** without flagging it explicitly and explaining why it is necessary.
- **No weakening of payment card detection.** The Luhn + BIN check in `luhn_validator.dart` and `bin_detector.dart` must not be removed, bypassed, or made optional.
- **No disabling encryption.** The Hive CE box must always be opened with the secure key. Do not add unencrypted fallback boxes.
- **Do not re-enable Android auto-backup.** `android:allowBackup="false"` in `AndroidManifest.xml` is intentional — see docs/SECURITY.md.
- **No new dependencies without justification.** Each package added must earn its place. Prefer Dart stdlib or a small amount of owned code over a new package.

---

## Stack

| Concern | Package |
|---|---|
| Local storage | `hive_ce`, `hive_ce_flutter` |
| Encryption key | `flutter_secure_storage` |
| Card scanning | `mobile_scanner` |
| Barcode rendering | `barcode_widget` |
| Notifications | `flutter_local_notifications` |
| State management | `flutter_riverpod` |
| Image picking | `image_picker` |
| Routing | `go_router` |
| Export share sheet | `share_plus` |
| Import file picker | `flutter_file_picker` |
| Export crypto (KDF + AES) | `cryptography` |
| Home screen widget bridge | `home_widget` |

Do not introduce alternative packages for any of these concerns without updating this file and `ARCHITECTURE.md` with a decision log entry explaining the change.

---

## Project Structure

```
lib/
  models/
    card.dart               # Card model + BarcodeType enum
    card.g.dart             # Hive CE generated adapter (do not edit manually)
    export_manifest.dart    # .cardstash file envelope model
  theme.dart                # CardStashColors extension, light/dark theme builders
  providers/
    card_provider.dart      # Riverpod providers for card CRUD + sort mode
    notification_provider.dart
    first_launch_provider.dart  # First launch flag + theme mode preference
  screens/
    home_screen.dart
    add_card_screen.dart
    card_display_screen.dart
    edit_card_screen.dart
    notifications_screen.dart  # Alerts tab with expiry list
    onboarding_screen.dart
    settings_screen.dart
    export_screen.dart
    import_screen.dart
    about_screen.dart       # App info, Ko-fi, licences, attribution
  widgets/
    card_tile.dart
    card_form_fields.dart   # Shared form widgets for add/edit screens
    barcode_view.dart
    expiry_badge.dart
    passphrase_field.dart
  services/
    storage_service.dart    # Hive CE init + encrypted box management
    scanner_service.dart
    notification_service.dart
    brightness_service.dart
    export_service.dart     # Serialise, encrypt, sign, share
    import_service.dart     # Verify, decrypt, deserialise, merge/replace
    file_picker_service.dart # Thin wrapper for testable file picking
  utils/
    luhn_validator.dart
    bin_detector.dart
    barcode_type_helper.dart
    colour_utils.dart
    crypto_utils.dart       # Argon2id KDF, AES-256-GCM, HMAC
```

Maintain this structure. If a new file does not fit cleanly into an existing directory, create a new directory and update this file.

---

## Documentation Maintenance

**This is mandatory, not optional.** After any session that introduces a meaningful change, update the relevant documentation before considering the work done.

### ARCHITECTURE.md

Update when:
- A package is added, removed, or swapped
- A meaningful structural or architectural decision is made
- An approach was considered and rejected (record what and why)
- The project structure changes

Format: add a new entry to the Decision Log section. Include what was decided, why, what was rejected, and any known trade-offs.

### SPEC.md

Update when:
- A feature is added, changed, or descoped
- The data model changes (fields added, removed, renamed, or retyped)
- The UX flow changes
- A risk is identified, resolved, or changes severity
- A feature moves between MVP and backlog

### SECURITY.md

Update when:
- The encryption approach changes
- A new permission is added
- The payment card detection logic changes
- A new security-relevant dependency is introduced
- A vulnerability is found or fixed

### CHANGELOG.md

Update when:
- Any user-facing change is made, following [Keep a Changelog](https://keepachangelog.com/) format
- A feature moves from Unreleased to a versioned release

### README.md

Update when:
- The feature list changes
- Setup instructions change
- The stack table changes

---

## Code Standards

Run these before finishing any session:

```bash
dart format .
flutter analyze
flutter test
```

Do not leave active `flutter analyze` warnings. If a warning cannot be resolved cleanly, add a comment explaining why and flag it.

---

## Critical Implementation Notes

### Card Display Screen

This is the most important screen in the app. Requirements that must always hold:

- Screen brightness is forced to maximum on open via `brightness_service.dart`
- Prior brightness level is saved before forcing and restored exactly on dismiss — including on back navigation, swipe dismiss, and any error path
- Barcode is rendered at maximum safe width
- EAN-13 quiet zones must not be overridden — do not add padding or margin to the barcode widget container that compresses the quiet zone
- Card number is always displayed in large text below the barcode as a fallback
- `usageCount` is incremented and `lastUsed` updated each time this screen is opened

### Home Screen Widget

The widget is a v1.1 feature. Key constraints:

- Barcodes must be pre-rendered as PNG images by the main app and written to shared storage via `home_widget` — widgets cannot use `barcode_widget` directly
- Refresh the cached PNGs whenever: card is opened, edited, or deleted
- Frame the widget as a launcher ("tap to scan") not a scan surface — brightness cannot be forced from a widget
- iOS requires a native Swift WidgetKit extension; Android requires a native AppWidget provider — both require native code beyond Flutter
- Android gets genuine in-widget swap via button intents; iOS 16 and below are deep-link only; iOS 17+ can use interactive widgets
- Storage keys follow the `widget_card_N_*` pattern — see SPEC.md

### About Screen

Follows the Ben White app portfolio pattern consistently:

- App icon (64×64), name, dynamic version from `pubspec.yaml`
- Short description
- Ko-fi button styled in amber (`https://ko-fi.com/benwhitelabs`)
- Settings-style rows with chevrons: Privacy Policy, Open Source Licences, GitHub
- "Designed and built by Ben White / Cheshire, England"
- MIT licence note
- Copyright line

Version number must be pulled dynamically — never hardcoded. Use `package_info_plus` to read it from `pubspec.yaml` at runtime.

Export and import are v1.0 requirements — without them, moving to a new phone means losing all cards.

- Export encrypts with AES-256-GCM using a key derived from a user passphrase via Argon2id — completely separate from the device key
- The HMAC signature covers `version + exported_at + payload`; verify this before attempting decryption — a wrong passphrase must fail at signature check, not mid-decryption
- The passphrase is never stored anywhere on the device
- On iOS, call out AirDrop explicitly in the export UI as the recommended migration path
- Import must support both Replace All and Merge modes; normalise card numbers (strip spaces and hyphens) before duplicate comparison in Merge mode
- iOS `.card-stash` file association requires UTType + CFBundleDocumentTypes in `Info.plist` — document this in CONTRIBUTING.md and test on a real device, not the simulator
- Benchmark Argon2id parameters on a low-end target device before shipping; tune to keep KDF under ~1 second

### Notifications

- Notification IDs are stored on the `Card` model in `notificationIds`
- On card edit, all existing notifications for that card must be cancelled before rescheduling
- On card delete, all notifications must be cancelled
- If no expiry date is set, no notifications are scheduled
- iOS permission denial must be handled gracefully — no crash, no broken UI, a clear message on the edit screen that notifications require permission

### Payment Card Detection

- Luhn check and BIN detection run on every manual card number entry
- A number that passes both is hard-rejected with the specified copy — it is not stored under any circumstances
- Do not soften the rejection message or make it dismissible with a "store anyway" option
- If a legitimate loyalty card is incorrectly rejected (false positive), the correct user path is to select "Display Only" barcode type — document this in the UI

### Hive CE

- The encrypted box is opened once in `storage_service.dart` and accessed via a singleton or Riverpod provider — do not open additional boxes
- `card.g.dart` is generated — run `dart run build_runner build` after any model change, never edit it manually
- Key retrieval failure must be handled with a clear error state, not a crash

---

## Out of Scope

Do not implement, prototype, or scaffold any of the following without an explicit instruction that overrides this file:

- Cloud sync or remote storage
- User accounts or authentication beyond biometric device lock
- Apple Wallet or Google Wallet import
- Retailer integrations, offers, or price comparison
- Analytics, crash reporting, or telemetry of any kind
- Push notifications (local notifications only)

---

## Versioning

Current version: **0.1.0-dev**  
Target v1.0.0 scope: see `SPEC.md` — MVP feature set  
Target v1.1.0 scope: see `SPEC.md` — planned post-launch features

Update `pubspec.yaml` version and `CHANGELOG.md` together when cutting a release.
