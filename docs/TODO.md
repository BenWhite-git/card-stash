# Card Stash - To Do

Living backlog of fixes, improvements and growth ideas, ordered by priority within each section. When an item ships, remove it here and record it in `CHANGELOG.md`.

---

## Fixes

- [ ] **Release APK is signed with the debug keystore.** `android/app/build.gradle.kts` still uses `signingConfigs.getByName("debug")`, so the v1.0.0 APK on GitHub Releases carries a debug signature. Create a release keystore, load it from `key.properties` (already gitignored) and sign the next release with it. The signature change means existing installs must export, uninstall and import, so land this before the user base grows. Priority: high.
- [ ] **Verify `.cardstash` import on real iOS and Android hardware** after the `file_picker` 11 upgrade. The file association paths (iOS UTType, Android content provider) have only been exercised through fakes. Priority: high before the next release.
- [ ] **Usage count is incremented by the home screen, not the display screen.** `_openCard` in `home_screen.dart` calls `incrementUsage` before pushing the route, but `CLAUDE.md` requires the display screen to own this so future entry points (home widget deep links, file association) count correctly. Move it into `CardDisplayScreen.initState`. Priority: medium.
- [ ] **Hardcoded hex colours outside `theme.dart`.** `import_screen.dart`, `export_screen.dart`, `passphrase_field.dart`, `card_form_fields.dart` and `expiry_badge.dart` contain `Color(0x...)` literals. Audit each: move UI colours into `CardStashColors`, leave genuine domain colours (card preset swatches) where they are. Priority: medium.
- [ ] **Benchmark Argon2id export parameters on a low-end device** and tune to keep the KDF under about one second. Still an open risk in `SPEC.md`. Priority: medium.
- [ ] **Test EAN-13 quiet zones against real till scanners.** Still an open risk in `SPEC.md`. Priority: medium.
- [ ] **Bump `share_plus` to 13 and `package_info_plus` to 10** once `file_picker` ships with `win32 ^6.0.0`. Priority: low.

## Improvements

- [ ] **Measure cold start on a real phone** before and after the startup work (timezone database removed, parallel initialisation, single router instance, themed launch windows). Use `flutter run --profile --trace-startup` and, on Android, `adb shell am start -W co.benwhite.card_stash/.MainActivity` for `TotalTime`. Record the numbers in `ARCHITECTURE.md`. Priority: high.
- [ ] **Splash-first startup** if measurement still shows more than ~300 ms before the first frame: call `runApp` immediately with a themed placeholder and initialise asynchronously. Deliberately not done yet, see `DECISIONS.md` D002. Priority: depends on measurement.
- [ ] **Ship a smaller APK.** The GitHub release is a fat APK with three ABIs. Build with `flutter build apk --split-per-abi` and publish the `arm64-v8a` build (plus `armeabi-v7a` for older phones), or an AAB for Play. Priority: medium.
- [ ] **CI on GitHub Actions**: `dart format --set-exit-if-changed .`, `flutter analyze`, `flutter test` on every PR, plus `osv-scanner --lockfile=pubspec.lock` since Dart has no built-in vulnerability scanner. Priority: medium.
- [ ] **Periodic backup reminder.** A lost phone means lost cards. Nudge the user to export after a number of new cards or days since the last export. Priority: medium.
- [ ] **Large-font and screen-reader pass** on the add, edit and display screens at 200% text scale. Priority: medium.
- [ ] **Search by card number** as well as name and issuer. Priority: low.
- [ ] **`ListView.builder` on the home screen.** Tiles are built eagerly; only matters once wallets exceed roughly 50 cards. Priority: low.

## Growth

- [ ] **Google Play listing.** Copy is drafted in `STORE_LISTINGS.md`. Blocked on release signing (see Fixes).
- [ ] **App Store / TestFlight release.** Needs an Apple Developer account; the Team ID was removed from the Xcode project and must be set locally at archive time.
- [ ] **Categories / folders** (groceries, travel, gym). Planned in `SPEC.md` v1.1.
- [ ] **Biometric lock** via `local_auth`. Planned in `SPEC.md` v1.1. New permission on both platforms, so flag it explicitly.
- [ ] **Home screen widget** with pre-rendered barcode PNGs via `home_widget`. Planned in `SPEC.md` v1.1 and the largest piece of work (native Swift and Kotlin).
- [ ] **Share a single card** as a one-card `.cardstash` file so a household can pass a shared loyalty card between phones without exporting the whole wallet.
- [ ] **Localisation** with Flutter's `l10n` tooling. The app is English only today.
- [ ] **F-Droid submission.** MIT, no network and no trackers make it a natural fit, but ML Kit is proprietary Google code and F-Droid's inclusion policy excludes it. Would need a free barcode scanning flavour (for example a ZXing-based one) behind a build flavour. Decide whether the audience justifies maintaining two scanner backends.
- [ ] **Write-up on benwhite.co** about the local-first, zero-network design, linked from the README.
