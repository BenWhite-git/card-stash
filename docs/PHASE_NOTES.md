# Phase Notes

Pre-implementation notes for each build phase. Read the relevant section before starting work.

---

## Phase 6 - Expiry Notifications

### Before writing any code

1. Read `test/screens/edit_card_screen_test.dart` and `test/screens/home_screen_test.dart` helper patterns. Copy the `tester.runAsync()` + `pump()` pattern exactly. Use a tall test surface for any screen with scrollable content.
2. Read the `flutter_local_notifications` package docs. It needs platform-specific setup (Android channel, iOS permission request). Check what's already configured in `AndroidManifest.xml` and `Info.plist` from Phase 0.
3. The `notificationIds` field already exists on `LoyaltyCard` as `List<int>?`. No model change needed.

### Implementation order

1. Start with `NotificationService` as a pure service class. Unit test the scheduling logic (given an expiry date, what notification times are calculated?) before touching platform channels.
2. Platform notification calls use platform channels that won't work in FakeAsync. Design the service so scheduling logic is testable separately from the platform calls.
3. Wire into `CardProvider` last - `addCard`/`updateCard` call schedule, `deleteCard` calls cancel. These are the integration points that are hardest to test in widget tests (Hive + notifications + FakeAsync), so lean on unit tests for the provider logic.

### Traps to avoid

- iOS permission request is async and can be denied. Don't let a denial crash or block the save flow. The edit screen should show a note about permissions, not a blocking dialog.
- Notification IDs need to be stored back on the card after scheduling. That's an `updateCard` call inside `addCard` - make sure this doesn't trigger infinite rescheduling.
- The 30-day/7-day/expiry-day schedule means up to 3 notification IDs per card. If expiry is less than 7 days away, skip the 30-day one. If it's today, skip both.
- `cancelCardNotifications` needs to handle `notificationIds` being null (cards created before Phase 6).

### Test strategy

- Unit tests for `NotificationService` scheduling logic (date calculation, ID generation, edge cases).
- Unit tests for `CardProvider` integration (verify schedule/cancel calls happen at the right times).
- Skip widget tests for notification-triggering flows - they'll deadlock under FakeAsync for the same Hive reasons. The provider unit tests cover the logic.

---

## Phase 7 - Settings, Export and Import

### Before writing any code

1. Read existing test helpers before writing tests. Use `tester.runAsync()` for all Hive and crypto operations inside `testWidgets`.
2. Read `pointycastle` or `cryptography` package docs for Argon2id and AES-256-GCM. Check which one is already in `pubspec.yaml`.
3. Benchmark Argon2id parameters on a low-end device before shipping. Target under 1 second for KDF.

### Traps to avoid

- HMAC verification must happen before decryption. A wrong passphrase should fail at signature check, not mid-decryption.
- The passphrase is never stored anywhere on the device.
- Merge mode must normalise card numbers (strip spaces and hyphens) before duplicate comparison.
- Replace All must clear existing cards before importing - don't leave orphan notifications.
- iOS `.card-stash` file association requires UTType + CFBundleDocumentTypes in `Info.plist` - check if Phase 0 already set this up.

---

## Phase 8 - About Screen

### Before writing any code

1. Add `package_info_plus` to dependencies. Version number must be dynamic, never hardcoded.
2. Read the Ben White app portfolio pattern in CLAUDE.md for the exact layout requirements.

### Traps to avoid

- The About screen must always use light theme regardless of system theme. This is a design system requirement.
- Ko-fi link is `https://ko-fi.com/benwhitelabs` - do not guess or modify this URL.
- OSS licences screen should use Flutter's built-in `showLicensePage`.

---

## Phase 9 - Polish and Pre-Release

### Before writing any code

1. Run a full accessibility audit against WCAG 2.2 AA before making any changes.
2. Read every screen file and check for semantic labels, colour contrast, and focus order.

### Traps to avoid

- Test on real devices, not just simulators. Simulators are insufficient for camera and brightness testing.
- Export/import cycle must be tested across platforms: iOS to iOS, Android to Android, iOS to Android.
- Don't skip the barcode scanning test at a real scanner.
