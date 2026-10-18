# Card Stash - To Do

Living backlog of fixes, improvements and growth ideas, ordered by priority within each section. When an item ships, remove it here and record it in `CHANGELOG.md`.

---

## Fixes

- [ ] **Sign the next GitHub Release with the release keystore.** The keystore exists and is backed up (created 18 October 2026) and a signed build has been verified locally. The signature change from the debug-signed v1.0.0 means existing installs must export, uninstall and import; the release notes must say so. Priority: high.
- [ ] **Verify `.cardstash` import on real iOS and Android hardware** after the `file_picker` 13 upgrade. The file association paths (iOS UTType, Android content provider) have only been exercised through fakes, and `file_picker` 12 rewrote the native layer. Priority: high before the next release.
- [ ] **Benchmark Argon2id export parameters on a low-end device** and tune to keep the KDF under about one second. Still an open risk in `SPEC.md`. Priority: medium.
- [ ] **Test EAN-13 quiet zones against real till scanners.** Still an open risk in `SPEC.md`. Priority: medium.
- [ ] **Manual screen-reader pass** with TalkBack and VoiceOver on the add, edit and display screens. The automated 200% text-scale layout check now runs in `test/accessibility/`, but reading order and announcements need a human. Priority: medium.

## Improvements

- [ ] **Measure cold start on a real phone** before and after the startup work. Use `flutter run --profile --trace-startup` and, on Android, `adb shell am start -W co.benwhite.card_stash/.MainActivity` for `TotalTime`. Record the numbers in `ARCHITECTURE.md`. Priority: high.
- [ ] **Splash-first startup** if measurement still shows more than ~300 ms before the first frame: call `runApp` immediately with a themed placeholder and initialise asynchronously. Deliberately not done yet, see `DECISIONS.md` D002. Priority: depends on measurement.
- [ ] **Publish split-per-ABI APKs** for the next GitHub Release (documented in `CONTRIBUTING.md`); the v1.0.0 fat APK bundles three ABIs. Priority: medium, at release time.
- [ ] **Upgrade the Android Gradle Plugin to 9.0.1 or later and Kotlin to 2.3.20 or later.** Flutter 3.47 warns that support for AGP 8.11.1 and Kotlin 2.2.20 will soon be dropped. Check the Flutter template for the current pair and verify the debug and release builds afterwards. Priority: medium.
- [ ] **`ListView.builder` on the home screen.** Tiles are built eagerly; only matters once wallets exceed roughly 50 cards. Priority: low.

## Growth

- [ ] **Google Play listing.** Copy is drafted in `STORE_LISTINGS.md`. The release keystore now exists, so this is unblocked.
- [ ] **App Store / TestFlight release.** Needs an Apple Developer account; the Team ID was removed from the Xcode project and must be set locally at archive time.
- [ ] **Categories / folders** (groceries, travel, gym). Planned in `SPEC.md` v1.1.
- [ ] **Biometric lock** via `local_auth`. Planned in `SPEC.md` v1.1. New permission on both platforms, so flag it explicitly.
- [ ] **Home screen widget** with pre-rendered barcode PNGs via `home_widget`. Planned in `SPEC.md` v1.1 and the largest piece of work (native Swift and Kotlin).
- [ ] **Share a single card** as a one-card `.cardstash` file so a household can pass a shared loyalty card between phones without exporting the whole wallet.
- [ ] **Localisation** with Flutter's `l10n` tooling. The app is English only today.
- [ ] **F-Droid submission.** MIT, no network and no trackers make it a natural fit, but ML Kit is proprietary Google code and F-Droid's inclusion policy excludes it. Would need a free barcode scanning flavour (for example a ZXing-based one) behind a build flavour. Decide whether the audience justifies maintaining two scanner backends.
- [ ] **Write-up on benwhite.co** about the local-first, zero-network design, linked from the README.

## Done since the 16 October 2026 review

Shipped on `perf/faster-startup` and `chore/backlog-fixes`; detail in `CHANGELOG.md` [Unreleased]:
startup speed-ups and themed launch windows, router no longer reset on theme change, usage count owned by the display screen, search by card number, all UI colours on theme tokens, release signing guard, GitHub Actions CI with OSV scan, `file_picker` 13 / `share_plus` 13 / `package_info_plus` 10, backup reminder banner, 200% text-scale layout fixes and automated check. Then on CI feedback: OCR temp-file race fixed, About rows on a Material surface, `pubspec.lock` committed (D005).
