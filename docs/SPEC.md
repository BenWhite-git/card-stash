# Card Stash — Product Specification

**Version:** 1.0
**Status:** Released
**Last updated:** March 2026  


---

## Design Principles

- **Barcode fidelity over features.** If the card doesn't scan at the till, nothing else matters.
- **Local-first, privacy-by-default.** No network calls, no analytics, no accounts.
- **Zero friction add.** A card should be added in under 30 seconds.
- **Open source hygiene.** Clean architecture, well-documented, MIT licenced.

---

## Data Model

```dart
Card {
  id: UUID
  name: String                    // User-editable, e.g. "Susie's Tesco Clubcard"
  issuer: String?                 // Optional brand/retailer name
  cardNumber: String              // Raw digits or alphanumeric string
  barcodeType: BarcodeType        // Enum — see below
  colour: Color                   // User-assigned or auto-suggested
  logoPath: String?               // Local path to user-imported image
  expiryDate: DateTime?           // Optional; drives notifications if set
  usageCount: int                 // Incremented each time the card is opened
  lastUsed: DateTime?
  createdAt: DateTime
  notes: String?                  // Free text, e.g. "Joint account", "Partner's card"
  isFavourite: bool
  notificationIds: List<int>?     // Stored for cancellation on edit or delete
}

enum BarcodeType {
  qrCode,
  code128,
  code39,
  ean13,
  ean8,
  dataMatrix,
  pdf417,
  aztec,
  displayOnly                     // Shows the card number only; no barcode rendered
}
```

---

## Feature Specification

### MVP — v1.0

#### Add Card

- Live camera scan via `camera` + ML Kit with real-time text overlay; both barcodes and text detected simultaneously on the live feed
- Barcodes auto-accepted on detection; text-only cards show detected fields as status chips with a "Use these details" confirmation button
- Manual entry fallback: card number entered by hand, barcode type selected from list
- Colour picker for card background
- Optional logo image from camera roll (`image_picker`)
- Reject payment cards on entry (see [Payment Card Rejection](#payment-card-rejection))

#### Card Display

The most critical screen in the app. Requirements:

- Full-screen takeover on card open
- Screen brightness forced to maximum on open; restored to prior level on dismiss
- Barcode rendered at maximum safe width with correct quiet zones preserved
- Card number displayed in large text beneath barcode (manual fallback if scanner fails)
- Card name displayed at top
- Single tap to dismiss

#### Card List (Home)

- Sorted by `usageCount` descending (most used first)
- Favourites pinned to top regardless of usage count
- Expiry warning badge shown on tile if expiry is within 30 days
- Note indicator (small icon) shown on tile if `notes` is non-empty
- Fuzzy search on `name` and `issuer`
- Long press: Edit / Delete / Toggle Favourite

#### Edit Card

- Rename card (name field)
- Edit or add notes
- Change colour
- Change or remove logo
- Update expiry date
- Change barcode type
- Notifications rescheduled automatically on save

#### Expiry Notifications

Notifications scheduled per card when expiry date is set or updated. Cancelled and rescheduled on edit; cancelled on delete.

| Trigger | Message |
|---|---|
| 30 days before expiry | "Your [Card Name] expires in 30 days" |
| 7 days before expiry | "Your [Card Name] expires in 7 days" |
| Expiry day | "Your [Card Name] expired today — update or remove it" |

iOS requires explicit notification permission. Handle gracefully if denied — no expiry tracking in that case, but no crash or degraded experience.

#### Export and Import (Device Migration)

Export and import are **v1.0 requirements**, not post-launch features. Without them, a user moving to a new phone loses all their cards. The encryption key cannot leave the secure enclave, so the database alone is unrecoverable on a new device.

**Export flow:**

User navigates to Settings → Export cards. The app:

1. Decrypts the Hive box using the device key
2. Serialises all cards to JSON (see file format below)
3. Prompts the user for a passphrase (used to re-encrypt the export independently of the device key)
4. Encrypts the payload with AES-256-GCM using a key derived from the passphrase via Argon2id
5. Writes a signed `.card-stash` file
6. Hands the file to the OS share sheet via `share_plus`

On iOS the share sheet offers iCloud Drive, AirDrop, Dropbox, and anything else the user has installed. AirDrop is the recommended path for iPhone-to-iPhone migration and should be called out as a tip in the UI.

On Android the share sheet offers Google Drive, local file storage, nearby share, and so on.

**Import flow:**

User navigates to Settings → Import cards, or taps a `.card-stash` file in Files/Drive/iCloud.

1. User selects the `.card-stash` file (via `flutter_file_picker` or system file association)
2. User enters the passphrase
3. App verifies the HMAC signature (wrong passphrase or tampered file fails here with a clear error)
4. App decrypts and validates the schema version
5. User chooses merge mode:
   - **Replace all** — removes existing cards, imports all from file (clean migration)
   - **Merge** — adds cards from file, skips duplicates matched by card number
6. App re-encrypts with the new device key and stores in Hive

**Passphrase handling:**

The passphrase never leaves the device and is not stored. If the user forgets it, the export file is unrecoverable. This is stated clearly in the export UI:

> "You'll need this passphrase to restore your cards. There's no way to recover it if you forget it."

**`.card-stash` file format:**

```json
{
  "version": 1,
  "exported_at": "2026-03-14T09:41:00Z",
  "signature": "<hmac-sha256 hex>",
  "payload": "<base64 AES-256-GCM encrypted JSON blob>",
  "salt": "<base64 Argon2id salt>"
}
```

The HMAC is computed over `version + exported_at + payload` using the same passphrase-derived key. A wrong passphrase produces an HMAC mismatch before decryption is attempted.

**iOS file association:**

Registering `.card-stash` so that tapping the file in the Files app opens the import flow requires a UTType declaration in `Info.plist` and `CFBundleDocumentTypes`. See CONTRIBUTING.md.

**Individual card share (secondary):**

Each card has a Share option in its edit menu that exports a single card as a QR code or a minimal `.card-stash` file. Useful for sharing a specific card (e.g. "here's my gym membership") without a full migration.

---

#### Payment Card Rejection

Two-layer approach to prevent credit and debit cards being stored:

**Layer 1 — Luhn algorithm + BIN range detection**

Applied on manual number entry. If the number both passes the Luhn check and matches a known payment card BIN prefix, the submission is hard-rejected with the message:

> "This looks like a payment card. For your security, Card Stash doesn't store credit or debit cards. Use Apple Pay or Google Wallet instead."

BIN ranges to detect:

| Scheme | Prefix Pattern |
|---|---|
| Visa | 4xxxxxx |
| Mastercard | 51–55 / 2221–2720 |
| Amex | 34 / 37 |
| Maestro | 6304 / 6759 / 6761 |
| Discover | 6011 / 65 |

**Layer 2 — Onboarding notice**

Displayed once on first launch:

> "Card Stash is for loyalty and membership cards only. Don't store credit or debit cards — use Apple Pay or Google Wallet for those."

Accepted via a single "Got it" button; not shown again.

**Known limitation:** Luhn + BIN detection catches approximately 95% of payment cards. Some loyalty card numbers coincidentally pass Luhn. A false positive (legitimate loyalty card rejected) is annoying but recoverable — the user can select "Display Only" barcode type and enter the number. A false negative (payment card stored) is the worse outcome; the onboarding notice covers residual risk.

---

### v1.1 — Planned

- Categories / folders (e.g. groceries, travel, gym)
- ~~Duplicate card number detection~~ -- **Implemented.** On save (add or edit), card numbers are normalised (spaces/hyphens stripped) and compared against existing cards. A warning dialog names the existing card and offers Cancel or Save anyway. Edit screen excludes the card being edited from the check. See `card_number_utils.dart` and `findDuplicate` in `card_provider.dart`.
- Biometric lock (Face ID / Touch ID / fingerprint) via `local_auth`
- ~~On-device OCR via `google_mlkit_text_recognition`~~ -- **Implemented.** Extracts card numbers, expiry dates, and issuer names using on-device ML Kit. Runs on live camera frames alongside barcode detection (via `camera` + `google_mlkit_barcode_scanning`), with real-time text overlay showing detected text bounding boxes. Also runs on gallery images. See `ocr_service.dart`, `camera_frame_processor.dart`.

#### Home Screen Widget (4×2)

A 4×2 home screen widget showing the top card's barcode and a quick-swap strip for the top 3 cards.

**Layout:**

```
┌─────────────────────────────────────┐
│ Card Stash          [card name]     │
├─────────────────────────────────────┤
│                                     │
│         [barcode / QR image]        │
│                                     │
├────────────┬────────────┬───────────┤
│  [card 1]  │  [card 2]  │  [card 3] │
└────────────┴────────────┴───────────┘
```

**Platform behaviour:**

| Interaction | iOS | Android |
|---|---|---|
| Tap barcode area | Opens app → Card Display | Opens app → Card Display |
| Tap card in swap strip | Opens app → that card's Display | Updates widget barcode in-place |

Android gets genuine in-widget swap. iOS deep-links to the correct card — fast and functional, but not in-widget.

**Technical approach:**

Barcodes cannot be rendered natively in widgets. The main app pre-renders the top 3 card barcodes as PNG images and writes them to shared app group storage via `home_widget`. The widget reads and displays the cached PNG.

The widget must be framed as **quick access to open the card**, not scan-from-widget. Screen brightness cannot be forced from a widget — the user must tap through to Card Display. A "tap to scan" label makes this expectation clear.

Shared storage keys:
```
widget_card_0_barcode    # PNG bytes
widget_card_1_barcode
widget_card_2_barcode
widget_card_0_name       # String
widget_card_1_name
widget_card_2_name
widget_active_index      # int (Android only — which card is foregrounded)
```

Cache is refreshed whenever: a card is opened (usage count changes), a card is edited, or a card is deleted. If fewer than 3 cards exist, unused swap slots are hidden.

**New package:** `home_widget`

**Platform caveats:**

iOS WidgetKit requires a native Swift extension. Android requires an AppWidget provider. Both require native code beyond the Flutter layer — this is the primary complexity driver for this feature. iOS 17+ interactive widgets allow in-widget button taps; iOS 16 and below are deep-link only.

#### About Screen

Consistent with Ben White's app portfolio pattern. Accessible from Settings.

**Content:**

| Element | Value |
|---|---|
| App icon | Card Stash icon at 64×64 |
| App name | Card Stash |
| Version | Dynamic from `pubspec.yaml` |
| Description | "A private, encrypted wallet for your loyalty and membership cards." |
| Ko-fi link | `https://ko-fi.com/benwhitelabs` — "Support on Ko-fi" |
| Privacy policy | Links to hosted privacy policy page |
| Open source licences | Flutter OSS licence screen |
| GitHub | `https://github.com/BenWhite-git/card-stash` |
| Attribution | "Designed and built by Ben White" / "Cheshire, England" |
| Licence | "MIT Licence — free to use, share, and modify" |
| Copyright | "© 2026 Ben White" |

Ko-fi link uses an amber-styled button consistent with the Sunlight palette. All other links are standard settings-style rows with chevrons.

These are intentionally excluded from the roadmap:

- Cloud sync or server-side storage of any kind
- Apple Wallet / Google Wallet import (requires platform entitlements)
- Retailer integrations, offers, or price comparison
- Any form of analytics or usage tracking

---

## UX Flow

```
Launch
  └── Home (card list, sort button top right)
        ├── Search bar (fuzzy match on name/issuer)
        ├── Sort options: Most used / A-Z / Recently used / Newest first
        ├── Tap card → Card Display (full screen, max brightness)
        │     ├── Edit button (top right) → Edit Card
        │     └── Tap to dismiss
        ├── FAB → Add Card
        │     ├── Live scan → camera detects barcodes + text in real-time → auto-accept or confirm → form
        │     ├── From gallery → pick photo → detect barcode + OCR → form
        │     └── Manual → enter number → select barcode type → name + confirm
        ├── Long press card → contextual menu
        │     ├── Edit
        │     ├── Share card (single card export)
        │     ├── Toggle Favourite
        │     └── Delete (confirmation required)
        └── Settings
              ├── Appearance (System / Light / Dark)
              ├── Export cards
              │     ├── Enter passphrase → confirm passphrase
              │     └── OS share sheet (AirDrop / iCloud / Drive / etc.)
              ├── Import cards
              │     ├── File picker → .cardstash file
              │     ├── Enter passphrase
              │     └── Replace all / Merge
              └── About
                    ├── Ko-fi support link
                    ├── Privacy policy
                    ├── Open source licences
                    ├── GitHub
                    └── Version / attribution / copyright
```

---

## Project Structure

```
lib/
  theme.dart                # CardStashColors extension, light/dark theme builders
  models/
    card.dart               # Card model + BarcodeType enum
    card.g.dart             # Hive CE generated adapter
    export_manifest.dart    # .cardstash file envelope model
  providers/
    card_provider.dart      # Riverpod providers for card CRUD + sort mode
    notification_provider.dart
    first_launch_provider.dart  # First launch flag + theme mode preference
  screens/
    home_screen.dart
    add_card_screen.dart
    card_display_screen.dart
    edit_card_screen.dart
    onboarding_screen.dart
    settings_screen.dart
    export_screen.dart      # Passphrase entry + share sheet trigger
    import_screen.dart      # File pick + passphrase + merge/replace choice
    about_screen.dart       # App info, Ko-fi, licences, attribution
  widgets/
    card_tile.dart          # List tile with usage badge, expiry warning, note indicator
    barcode_view.dart       # Barcode rendering widget
    expiry_badge.dart
    passphrase_field.dart   # Shared secure text input for export/import
  services/
    storage_service.dart    # Hive CE init, encrypted box management
    scanner_service.dart    # mobile_scanner wrapper
    notification_service.dart
    brightness_service.dart # Screen brightness control
    export_service.dart     # Serialise, encrypt, sign, share
    import_service.dart     # Verify, decrypt, deserialise, merge/replace
  utils/
    luhn_validator.dart     # Pure Dart Luhn check
    bin_detector.dart       # Payment card BIN range matching
    barcode_type_helper.dart
    colour_utils.dart
    crypto_utils.dart       # Argon2id KDF, AES-256-GCM helpers, HMAC
```

---

## Known Risks

| Risk | Severity | Mitigation |
|---|---|---|
| Barcode type misidentified on scan | Medium | Allow user to change type on edit screen |
| EAN-13 quiet zones not preserved | High | Test `barcode_widget` rendering against real scanners before release |
| iOS notification permission denied | Low | Degrade gracefully; note on edit screen that notifications require permission |
| Android auto-backup includes encrypted DB without key | High | Disable auto-backup in AndroidManifest — see SECURITY.md |
| Key retrieval failure on some Android OEMs post-OS-upgrade | Medium | Warn users at first launch that data cannot be recovered if app is uninstalled |
| Luhn false positive blocks legitimate loyalty card | Low | User can bypass by selecting "Display Only" barcode type |
| User forgets export passphrase | High | Warn clearly in export UI; no recovery path exists |
| iOS `.card-stash` file association not configured correctly | Medium | Document UTType setup in CONTRIBUTING.md; test on real device |
| Argon2id KDF parameters too aggressive for low-end devices | Medium | Benchmark on minimum target device; tune memory/iteration parameters accordingly |
| Import merge produces duplicates if card number format differs | Low | Normalise card numbers (strip spaces/hyphens) before duplicate comparison |
