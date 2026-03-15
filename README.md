# Card Stash

A clean, local-first loyalty and membership card wallet for iOS and Android.

Built with Flutter. No accounts. No analytics. No network calls. Your cards stay on your device, encrypted.

---

## Features

- **Scan or enter cards manually** — camera scanning detects barcode format automatically
- **All major barcode formats** — QR, Code128, Code39, EAN-13, EAN-8, DataMatrix, PDF417, Aztec
- **Full-screen card display** — maximum brightness, correct barcode rendering, card number as fallback
- **Smart sorting** — most used cards rise to the top; favourites pinned
- **Rename and annotate** — label a card "Susie's Waitrose" and add notes
- **Optional expiry tracking** — notifications at 30 days, 7 days, and on expiry day
- **Encrypted at rest** — AES-256 via Hive CE, key stored in device secure enclave
- **Payment card rejection** — detects and blocks storage of credit and debit cards

---

## Privacy

Card Stash stores all data locally on your device. There are no servers, no accounts, no telemetry, and no third-party SDKs that phone home.

Your data is encrypted using a 256-bit key stored in your device's secure enclave (iOS Keychain / Android Keystore). If you uninstall the app, your data cannot be recovered.

**Do not use Card Stash to store credit or debit cards.** Use Apple Pay or Google Wallet for payment cards.

---

## Getting Started

### Requirements

- Flutter 3.19+
- Dart 3.3+
- iOS 13+ / Android 6.0+ (API 23+)

### Setup

```bash
git clone https://github.com/yourname/card-stash.git
cd card-stash
flutter pub get
flutter run
```

### iOS — Camera Permissions

Add the following to `ios/Runner/Info.plist`:

```xml
<key>NSCameraUsageDescription</key>
<string>Card Stash uses the camera to scan loyalty and membership cards.</string>
```

### Android — Camera Permissions

`mobile_scanner` handles camera permissions automatically. No manual manifest changes required.

### Android — Disable Auto-Backup

Add the following to `android/app/src/main/AndroidManifest.xml` to prevent encrypted Hive data being backed up without its key:

```xml
<application
  android:allowBackup="false"
  ...>
```

See [SECURITY.md](SECURITY.md) for full rationale.

---

## Tech Stack

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

---

## Roadmap

See [SPEC.md](SPEC.md) for the full product specification and planned future features.

---

## Contributing

Contributions are welcome. Please read [CONTRIBUTING.md](CONTRIBUTING.md) before opening a pull request.

---

## Licence

MIT — see [LICENSE](LICENSE)
