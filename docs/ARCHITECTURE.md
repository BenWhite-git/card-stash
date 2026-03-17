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

**Future option:** An encrypted local backup/restore feature (export to a file, import from a file) is planned for v1.1 and does not require a backend.

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

- No dependency injection framework (Riverpod providers are sufficient)
- No repository pattern abstraction over Hive (unnecessary indirection for this scope)
- No remote feature flags or configuration
- No error reporting service (open source; contributors see errors locally)
