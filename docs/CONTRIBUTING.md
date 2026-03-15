# Contributing to Card Stash

Contributions are welcome. This document covers how to get set up, what the project values, and what to watch out for.

---

## Before You Start

Check the [open issues](https://github.com/yourname/card-stash/issues) before starting work. If you want to work on something that isn't already tracked, open an issue first to discuss it — particularly for anything that changes behaviour, adds dependencies, or touches the security model.

For small fixes (typos, documentation, obvious bugs), just open a PR directly.

---

## Setup

```bash
git clone https://github.com/yourname/card-stash.git
cd card-stash
flutter pub get
flutter run
```

### Requirements

- Flutter 3.19+
- Dart 3.3+
- iOS 13+ / Android 6.0+ (API 23+)

Test on a real device where possible, particularly for:

- Camera and barcode scanning (`mobile_scanner` has known simulator limitations)
- Secure storage (`flutter_secure_storage` behaviour differs significantly between emulators and real hardware)
- Screen brightness control on card display

---

## Project Values

**Barcode fidelity is non-negotiable.** The card display screen is the most critical part of the app. A barcode that doesn't scan at the till is a broken product. If your contribution touches barcode rendering, test against a real barcode scanner before submitting.

**No new network calls.** Card Stash is deliberately offline. Do not introduce HTTP clients, analytics SDKs, telemetry, or remote configuration — even behind a feature flag. This is a hard constraint, not a preference.

**No new permissions without justification.** Each new permission is a trust cost. If your change requires a new platform permission, explain why it's necessary in the PR description.

**Dependencies should earn their place.** Prefer the standard library or a small amount of code over adding a package. Each new dependency is a supply chain risk and a maintenance burden.

---

## Code Style

Follow standard Dart and Flutter conventions. Run the following before submitting:

```bash
dart format .
flutter analyze
flutter test
```

No PR will be merged with active `flutter analyze` warnings.

---

## Barcode Rendering — Critical Notes

- **EAN-13 quiet zones must be preserved.** The `barcode_widget` package respects these by default; do not override padding or margin on the barcode widget container.
- **Brightness must be restored on dismiss.** The `brightness_service.dart` saves and restores the user's prior brightness level. Any change to the card display lifecycle must maintain this behaviour.
- **Default to Code128 for unknown formats.** Most UK loyalty and membership cards use Code128. When in doubt, default there rather than QR.

---

## Security — What Not to Touch

- Do not modify the encryption key generation or storage logic without a thorough review and a specific issue tracking the change.
- Do not disable or weaken the payment card rejection checks (Luhn + BIN detection). If you believe there is a false positive affecting legitimate loyalty cards, open an issue with a reproducible example rather than removing the check.
- Do not enable Android auto-backup. See [SECURITY.md](SECURITY.md) for rationale.

If you find a security vulnerability, see [SECURITY.md](SECURITY.md) for how to report it.

---

## Pull Requests

- Keep PRs focused — one concern per PR
- Write a clear description of what the change does and why
- Reference the issue number if applicable (`Closes #123`)
- Include screenshots or a short screen recording for any UI changes
- Confirm you have tested on a real device if the change touches camera, storage, or notifications

---

## What We Are Not Looking For

To save everyone's time:

- Cloud sync or account features
- Apple Wallet / Google Wallet import
- Analytics, crash reporting, or telemetry
- Retailer integrations or offer feeds
- UI redesigns without prior discussion

These are intentionally out of scope — see [SPEC.md](SPEC.md) for the rationale.

---

## Licence

By contributing, you agree that your contributions will be licenced under the MIT Licence.
