# Architecture

This document records the key technical decisions made in Card Stash, with rationale. It is intended for contributors who want to understand why things are built the way they are, not just how.

---

## Overview

Card Stash is a Flutter application targeting iOS and Android. It is deliberately simple: a local-only, single-user app with no backend and no network dependency.

```
┌─────────────────────────────────────┐
│              Flutter UI             │
│  (Screens, Widgets, go_router)      │
├─────────────────────────────────────┤
│          Riverpod Providers         │
│  (State management, business logic) │
├──────────────────┬──────────────────┤
│    Services      │    Services      │
│  StorageService  │  ScannerService  │
│  NotificationSvc │  BrightnessSvc   │
├──────────────────┴──────────────────┤
│         Hive CE (encrypted)         │
│   Key: iOS Keychain / Android KS    │
└─────────────────────────────────────┘
```

---

## Decision Log

### Storage: Hive CE, not Isar

**Decision:** Use `hive_ce` for local storage instead of Isar.

**Rationale:** Isar does not support native encryption. Field-level encryption layered on top of Isar was considered but rejected — it is complex, error-prone, and hard to audit. Drift with SQLCipher was considered but is meaningfully more complex than the schema requires.

Hive CE provides first-class AES-256 encryption, a simple key-value API that suits a flat card collection, and is actively maintained (the original `hive` package is essentially abandoned). For this schema there are no relational queries, no joins, and no complex indexing needs — Hive is sufficient and appropriate.

**Trade-off:** If the schema grows significantly in complexity (e.g. v2 adds card transaction history, sharing, or multi-user), Hive CE may become limiting. That is an acceptable future trade-off given the current scope.

---

### Encryption Key: Secure Enclave, not Derived from Passcode

**Decision:** Generate a random 256-bit key on first launch and store it in the device secure enclave via `flutter_secure_storage`.

**Rationale:** The alternative — deriving an encryption key from a user-defined passcode — requires implementing key derivation (e.g. PBKDF2 or Argon2), a secure passcode entry flow, and passcode change/reset logic. For a loyalty card wallet, this complexity is disproportionate and introduces more failure modes than it eliminates.

The secure enclave approach means the key is as strong as the device's lock screen. Users who do not use a device passcode already have no meaningful security for anything on the device.

**Trade-off:** Key loss is permanent and silent if the user is unaware. Mitigated by a first-launch warning and clear documentation.

---

### State Management: Riverpod

**Decision:** Use `flutter_riverpod` for state management.

**Rationale:** For a local-only app without complex async flows, the choice of state management matters less than consistency. Riverpod is well-documented, widely understood in the Flutter community (important for an open source project), and handles the storage service lifecycle cleanly. Provider is the obvious alternative; Riverpod is the modern successor and the better choice for new projects.

**What was rejected:** BLoC — disproportionate boilerplate for this scope. GetX — opinionated and less familiar to contributors. `setState` — insufficient for cross-screen state (card list sorting, notification management).

---

### Routing: go_router

**Decision:** Use `go_router` for navigation.

**Rationale:** Standard, well-maintained, and widely understood. Declarative routing makes the navigation graph auditable. The alternative (Navigator 2.0 directly) is unnecessarily verbose for this use case.

---

### Payment Card Detection: Luhn + BIN, not Barcode Analysis

**Decision:** Detect payment cards via Luhn algorithm and BIN prefix matching on the card number string, not by attempting to parse payment card barcodes.

**Rationale:** Payment cards are not typically barcoded in a format that `mobile_scanner` would encounter during normal loyalty card scanning. The real risk is a user manually entering a Visa or Mastercard number. Luhn + BIN matching is a well-understood heuristic that catches the vast majority of cases without requiring any external data.

Detection is implemented in pure Dart with no package dependency — the logic is simple enough to own.

**Known limitation:** Heuristic detection is not perfect. See [SECURITY.md](SECURITY.md) for full discussion.

---

### No Cloud Sync

**Decision:** Local-only storage; no cloud sync in any version.

**Rationale:** Cloud sync requires a backend, authentication, conflict resolution, and a privacy policy. It transforms a simple utility into a data-handling service. For a side project and open source tool, this is disproportionate and contrary to the privacy-first design principle.

If a user loses their device, their cards are gone. This is the honest consequence of local-only storage, communicated clearly in onboarding.

**Mitigation:** An encrypted local backup/restore feature (export to a file, import from a file) is implemented in v1.0 and does not require a backend.

---

### Android Auto-Backup: Disabled

**Decision:** Disable Android auto-backup entirely.

**Rationale:** Android auto-backup would include the encrypted Hive database but not the Android Keystore key used to decrypt it. A user restoring from backup would receive an encrypted database they cannot open. Worse, they may not understand why, and may assume their data is there when it is not.

The safer behaviour is to back up nothing and be explicit with users that data cannot be recovered after uninstall.

**Implementation:** `android:allowBackup="false"` in `AndroidManifest.xml`.

---

### Export/Import: OS Share Sheet, not Cloud Provider Integration

**Decision:** Export produces an encrypted `.card-stash` file handed to the OS share sheet via `share_plus`. Import accepts a `.card-stash` file via `flutter_file_picker` or iOS file association.

**Rationale:** Integrating directly with Google Drive or iCloud requires OAuth flows, cloud SDKs, and ongoing API dependency. Using the OS share sheet delegates destination choice to the user — on iOS they get iCloud Drive, AirDrop, Dropbox, and anything else installed; on Android they get Google Drive, local storage, nearby share, etc.

AirDrop is the correct answer for iPhone-to-iPhone migration specifically — it is device-to-device, no cloud intermediary, and the encrypted file is safe in transit. This is called out as a UI tip on the export screen.

**Trade-off:** The user must manage the file themselves. This is acceptable — the export passphrase provides a second layer of protection even if the file ends up somewhere unexpected.

---

### Export Encryption: Passphrase-Derived Key, not Device Key

**Decision:** Export files are encrypted with AES-256-GCM using a key derived from a user passphrase via Argon2id, entirely separate from the device's secure enclave key.

**Rationale:** The device key cannot be exported — it is hardware-bound by design. A separate passphrase-derived key allows the file to be decrypted on any device by anyone who knows the passphrase. Argon2id is the current recommended KDF for password-based key derivation (winner of the Password Hashing Competition, resistant to GPU and side-channel attacks).

**Trade-off:** If the user forgets the passphrase, the export file is unrecoverable. This is communicated clearly in the export UI. No recovery path exists — this is the correct and honest position for a privacy-first app.

**What was rejected:** Encrypting with the device key — impossible to decrypt on a new device. Storing the passphrase in the secure enclave — defeats the purpose of the passphrase. Using PBKDF2 instead of Argon2id — PBKDF2 is weaker against GPU attacks; Argon2id is the better current choice.

### Model Name: LoyaltyCard, not Card

**Decision:** The Hive model class is named `LoyaltyCard`, not `Card`.

**Rationale:** Flutter has a built-in `Card` widget in Material. Naming the data model `Card` would require disambiguation imports throughout the codebase. `LoyaltyCard` is unambiguous and domain-specific.

---

### First-Launch Flag: SharedPreferences, not Hive

**Decision:** Store the first-launch/onboarding flag in `SharedPreferences`, separate from the encrypted Hive box.

**Rationale:** The first-launch flag needs to be readable before the encryption key is retrieved and the Hive box is opened. If key retrieval fails, the app still needs to know whether to show onboarding. Storing it in Hive creates a chicken-and-egg dependency.

---

### Provider Architecture: Synchronous NotifierProvider

**Decision:** Use `NotifierProvider` (synchronous) for the card list, not `AsyncNotifierProvider`.

**Rationale:** Hive box opening is async and happens in `StorageService.init()` before `runApp`. By the time the provider is first read, the box is already open. The provider overrides inject the initialised `StorageService`, so there is no async gap. This avoids `AsyncValue` wrapping throughout the UI layer for state that is always immediately available.

---

### Screen Brightness: screen_brightness Package

**Decision:** Use the `screen_brightness` package for programmatic brightness control on the card display screen.

**Rationale:** The card display screen must force brightness to maximum so barcodes scan reliably at the till. `screen_brightness` is the standard Flutter package for this - it supports iOS, Android, and macOS with a simple set/reset API. No real alternatives exist in the ecosystem.

**Implementation:** `BrightnessService` wraps the package behind a `ScreenBrightnessControl` interface for testability. The service is injected via Riverpod provider and the cached reference is stored in `initState` so `dispose` can restore brightness after `ref` is invalidated.

---

### Card Display: Usage Tracking by Caller, Not Screen

**Decision:** `CardDisplayScreen` does not call `incrementUsage` itself. The caller must call `CardProvider.incrementUsage()` when navigating to the screen.

**Rationale:** `incrementUsage` writes to the Hive box, which involves disk I/O. Flutter's `testWidgets` runs in FakeAsync, which cannot process real I/O - any Hive write triggered during the widget lifecycle deadlocks the test. Moving the side effect to the caller keeps the screen as a pure display widget and makes it fully testable.

**Trade-off:** The caller must remember to call `incrementUsage`. This is wired up when the HomeScreen is built in Phase 3.

---

### Navigation: ShellRoute with Bottom Nav

**Decision:** Use `go_router`'s `ShellRoute` to wrap the bottom navigation bar around tab screens (Cards, Alerts, About), with full-screen routes (CardDisplayScreen, AddCardScreen) pushed outside the shell.

**Rationale:** ShellRoute keeps the nav bar persistent across tabs without rebuilding it on each navigation. Full-screen routes like card display break out of the shell using `parentNavigatorKey` so they cover the nav bar entirely, which is the correct UX for a barcode scanning screen.

---

### Hive I/O in Widget Tests: tester.runAsync Pattern

**Decision:** All Hive box writes in widget tests must use `tester.runAsync()` to avoid FakeAsync deadlocks.

**Rationale:** Flutter's `testWidgets` runs in FakeAsync by default. Hive's disk I/O operations (put, delete) use real timers and Futures that cannot complete inside FakeAsync, causing the test to hang indefinitely. The `tester.runAsync()` escape hatch runs code with real async, allowing Hive writes to complete. UI interactions that trigger Hive writes (e.g. toggling a favourite) cannot be wrapped in `runAsync` since the tap itself is a FakeAsync operation. These mutation effects are tested through the CardProvider unit tests instead.

---

### Router: Factory Function, not Module-Level Instance

**Decision:** The router is created via `createRouter({bool isFirstLaunch})` rather than a `final appRouter` at module level.

**Rationale:** The initial route depends on whether this is the user's first launch (onboarding vs home). A factory function accepts this parameter and creates the router with the correct initial location. Additionally, `GlobalKey<NavigatorState>` instances are scoped inside the factory, avoiding key reuse between router instances in tests.

---

### mobile_scanner BarcodeType Conflict

**Decision:** Import `card.dart` with `as model` prefix in `barcode_type_helper.dart` to resolve the name clash between our `BarcodeType` enum and `mobile_scanner`'s `BarcodeType`.

**Rationale:** Both our model and mobile_scanner export a `BarcodeType` name. A prefix import on our model cleanly resolves the ambiguity without renaming either enum. In test files, `show`/`hide` directives on the imports achieve the same disambiguation.

---

### EditCardScreen: Navigator.pop, not GoRouter Extensions

**Decision:** `EditCardScreen` uses `Navigator.of(context).pop()` for dismissal rather than `context.pop()` from go_router.

**Rationale:** `context.pop()` requires a `GoRouter` ancestor in the widget tree, which makes the screen impossible to test in isolation with a plain `Navigator`. Since the edit screen is always pushed onto the navigation stack (never navigated to via deep link), `Navigator.pop()` is functionally equivalent and testable without GoRouter in the test harness.

---

### EditCardScreen: Construct LoyaltyCard Directly, not copyWith

**Decision:** The save method constructs a new `LoyaltyCard` directly rather than using `copyWith`.

**Rationale:** The `copyWith` method cannot clear nullable fields (e.g. setting `expiryDate` back to `null`) because `null` means "keep the existing value". Constructing the card directly with immutable fields copied from the original and editable fields from form state cleanly handles nullable field clearing without adding sentinel values or modifying the model.

---

### Notification Scheduling: Pure Logic Separated from Platform Calls

**Decision:** `NotificationService.computeSchedule` is a static method that computes dates and messages without touching platform channels. The platform-specific scheduling calls are in instance methods that consume this output.

**Rationale:** Flutter's `testWidgets` runs in FakeAsync, and `flutter_local_notifications` uses platform channels that deadlock under FakeAsync. Separating the date calculation into a pure static method allows unit testing the scheduling logic (edge cases around dates, message templates) without any platform dependency. The platform integration is tested via a `StubNotificationService` that records calls.

**CardProvider re-schedule prevention:** When notification IDs are stored back on the card after scheduling, a private `_persistNotificationIds` method writes directly to the Hive box, bypassing the public `updateCard` method. This prevents infinite rescheduling loops where updateCard triggers schedule which triggers updateCard.

---

### Notification IDs: Deterministic from Card ID

**Decision:** Notification IDs are generated deterministically from `cardId.hashCode + index`, not randomly.

**Rationale:** Deterministic IDs mean the same card always produces the same notification IDs, making cancellation reliable even if stored IDs are lost. For a personal app with a handful of cards, collision risk from hashCode is negligible. IDs are also stored in `notificationIds` on the card model as a belt-and-suspenders measure.

---

### Crypto Package: cryptography, not pointycastle

**Decision:** Use the `cryptography` package for export/import encryption instead of `pointycastle`.

**Rationale:** `pointycastle` was added speculatively in Phase 0 but its Argon2id support is undocumented and its AES-GCM API requires significantly more boilerplate. The `cryptography` package provides first-class `Argon2id`, `AesGcm.with256bits()`, and `Hmac.sha256()` classes with clean async APIs. It is pure Dart on non-web platforms and actively maintained.

**What was rejected:** Keeping `pointycastle` and working around sparse documentation. Also considered using both packages (pointycastle for AES-GCM, cryptography for Argon2id) but mixing packages for the same concern increases surface area.

---

### Export Encryption: Dual-Key Derivation

**Decision:** Derive two separate 256-bit keys from a single passphrase using Argon2id: one for AES-256-GCM encryption, one for HMAC-SHA256 signing.

**Rationale:** Using the same key for both encryption and signing is a cryptographic anti-pattern. Argon2id produces 64 bytes in a single derivation; splitting into two 32-byte keys (bytes 0-31 for AES, 32-63 for HMAC) avoids key reuse with no additional KDF cost. The 16-byte random salt is stored in the export manifest (it is not secret).

---

### Export Manifest: Salt Storage

**Decision:** Add a `salt` field to the `.cardstash` file format, deviating from the original spec which omitted it.

**Rationale:** Without the salt, the import side cannot re-derive the same Argon2id keys from the passphrase. The salt is not secret - it prevents precomputed attacks on the passphrase. Storing it alongside the encrypted payload is standard practice for password-based encryption.

---

### Bottom Nav: Settings Replaces About

**Decision:** The bottom navigation bar shows Cards, Alerts, Settings instead of Cards, Alerts, About. The About screen is accessed from within Settings.

**Rationale:** Phase 7 adds Export and Import functionality that needs a natural home. Settings is the conventional location for these actions. About is a leaf screen with no sub-navigation, while Settings groups export/import/about into a cohesive section.

---

### Theme System: CardStashColors Extension

**Decision:** Define app colours in a `CardStashColors` ThemeExtension with light and dark palettes, accessed via `context.colors`. All UI element colours reference named theme variables, never hardcoded hex values.

**Rationale:** The app originally used hardcoded dark theme colours throughout. Adding light/dark/system theme support required decoupling colours from the UI code. A `ThemeExtension` is the Flutter-native approach - it integrates with `MaterialApp`'s `theme`/`darkTheme`/`themeMode` system and supports `lerp` for animated transitions. The `BuildContext` extension (`context.colors`) provides a concise API.

**What was rejected:** Defining colours as top-level constants with a global "current palette" variable. This doesn't integrate with Flutter's theme system and breaks when the platform brightness changes.

**Theme mode persistence:** Stored in `SharedPreferences` via `ThemeModeNotifier`, read before the first frame. Default is `ThemeMode.system`.

---

### About Screen: App Theme, not Hardcoded Light

**Decision:** The About screen uses the app's current theme (light or dark) via `context.colors`, matching the rest of the app.

**Rationale:** The original spec called for a light "portfolio pattern" About screen, but on-device testing showed it looked like a different app. Consistency across screens is more important than matching an external portfolio pattern.

---

### App Icon: flutter_launcher_icons

**Decision:** Use `flutter_launcher_icons` as a dev dependency to generate platform launcher icons from a single 1024x1024 source.

**Rationale:** Manually creating and placing icons at every required resolution for both iOS and Android is tedious and error-prone. The package generates all required sizes, adaptive icon XML for Android, and strips alpha channels for iOS App Store compliance. It runs once as a build step and has no runtime cost.

---

### About Screen: package_info_plus and url_launcher

**Decision:** Use `package_info_plus` to read the app version at runtime and `url_launcher` to open external URLs (Ko-fi, Privacy Policy, GitHub).

**Rationale:** The CLAUDE.md spec requires the version number to be pulled dynamically, never hardcoded. `package_info_plus` reads from the platform's app manifest. `url_launcher` is the standard Flutter package for opening URLs in the system browser. Both are maintained by the Flutter community team and have no viable alternatives.

---

### Riverpod 3 Upgrade

**Decision:** Upgrade from `flutter_riverpod` 2.x to 3.x.

**Rationale:** The codebase already uses `Notifier`/`NotifierProvider` (the Riverpod 3 pattern), with no `StateNotifier` usage. The upgrade required no code changes to providers or consumers - only a pubspec.yaml version bump. Staying on 2.x would mean missing out on bug fixes and eventually hitting a maintenance cliff.

---

### Dependency Updates (v1.0.0)

**Decision:** Update all dependencies to latest stable before release. `flutter_local_notifications` 18 to 21, `flutter_secure_storage` 9 to 10, `go_router` 15 to 17, `share_plus` 10 to 12, `file_picker` 9 to 10, `package_info_plus` 8 to 9, `timezone` 0.10 to 0.11.

**Breaking changes handled:**
- `flutter_local_notifications` v21: `initialize`, `zonedSchedule`, and `cancel` switched from positional to named parameters; `uiLocalNotificationDateInterpretation` parameter removed.
- `share_plus` v12: `Share.shareXFiles` replaced by `SharePlus.instance.share(ShareParams(...))`.
- `flutter_secure_storage` v10: `IOSOptions`/`MacOsOptions` replaced by `AppleOptions`.
- `cupertino_icons` removed (zero imports in lib/).

---

### Code Deduplication: Shared Form Widgets

**Decision:** Extract duplicated form widgets from `add_card_screen.dart` and `edit_card_screen.dart` into `card_form_fields.dart`.

**Rationale:** Both screens had identical implementations of text fields, barcode type chips, colour picker, expiry picker, label widget, and barcode type label function. Extracting these into reusable widgets reduces duplication by approximately 200 lines and ensures visual consistency between add and edit flows. The `confirmDeleteDialog` helper was also extracted since it was duplicated between edit screen and home screen.

---

### Alerts Tab: Expiry List

**Decision:** Replace the Alerts tab placeholder with a sorted expiry list that reads from existing card data.

**Rationale:** A card wallet needs a way to see which cards are expiring soon without scrolling through the full list. The Alerts tab reads from `cardListProvider` (no new storage or state), filters to cards with expiry dates, and sorts soonest first. Each row shows the card name, formatted expiry date, and an `ExpiryBadge`.

---

### On-Device OCR: google_mlkit_text_recognition

**Decision:** Use `google_mlkit_text_recognition` for on-device text recognition to extract card names, expiry dates, and card numbers from camera images.

**Rationale:** When scanning a card, the barcode scanner detects the barcode value and type, but the user must manually type the card name and expiry. OCR fills these fields automatically. It also handles cards with no barcode at all - the user photographs the card and OCR extracts the number.

`google_mlkit_text_recognition` was chosen because it runs entirely on-device (no network calls, consistent with the app's zero-network constraint), ships with minimal binary size impact (~260KB), and leverages the same ML Kit infrastructure already present via `mobile_scanner`. Alternatives considered: `tesseract_ocr` (larger binary, more complex setup, lower accuracy on mobile), building custom regex extraction from barcode raw values (only works if the barcode encodes the text, which loyalty cards rarely do).

The OCR text parsing logic (`parseText`) is pure Dart with no ML Kit dependency, making it fully unit-testable without device or emulator.

**Trade-off:** Adds a native dependency that increases build time slightly. OCR accuracy varies with image quality and card design - results are used as suggestions that the user can edit, not trusted blindly.

---

### Duplicate Card Number Detection

**Decision:** Soft warning dialog on save, not a hard block. Normalise card numbers (strip whitespace and hyphens) before comparison.

**Rationale:** Legitimate cases exist for duplicate numbers (e.g. same physical card stored under different names). A hard block would frustrate users. The warning names the existing card so the user can make an informed choice. Normalisation was already used in the import merge path - extracted to `card_number_utils.dart` for shared use.

**Also:** Made card numbers editable on the edit screen. They were previously read-only, which prevented correcting manual entry mistakes.

---

### Editable Card Number on Edit Screen

**Decision:** Replace the read-only card number display with an editable text field, including payment card rejection (same check as add screen).

**Rationale:** Users who manually enter a card number may make typos. Having no way to correct the number without deleting and re-adding the card was a UX gap. Payment card rejection is applied consistently on both add and edit paths.

---

- No dependency injection framework (Riverpod providers are sufficient)
- No repository pattern abstraction over Hive (unnecessary indirection for this scope)
- No remote feature flags or configuration
- No error reporting service (open source; contributors see errors locally)
