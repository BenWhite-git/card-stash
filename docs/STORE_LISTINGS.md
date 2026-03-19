# Card Stash - App Store Listings

Reference document for Apple App Store and Google Play Store submissions.

---

## Pre-Submission: Privacy Policy

Update the privacy policy at `benwhite.co/lab/privacy-policy.html` to name Card Stash explicitly. Include:

- Card Stash collects no data. No analytics, no crash reporting, no network calls.
- All card data is stored locally on the device, encrypted at rest using AES-256.
- The encryption key is stored in the device's secure enclave (iOS Keychain / Android Keystore).
- No data leaves the device unless the user explicitly exports via the share sheet.
- Exported files are encrypted with a user-chosen passphrase using Argon2id + AES-256-GCM.
- Camera access is used solely for scanning barcodes.
- No third-party SDKs that collect data are included.
- Payment card numbers are rejected and never stored.

---

## Apple App Store (App Store Connect)

### Metadata

| Field | Value |
|---|---|
| App Name | Card Stash |
| Subtitle | Private Loyalty Card Wallet |
| Primary Category | Utilities |
| Secondary Category | Lifestyle |
| Bundle ID | co.benwhite.cardstash |
| SKU | cardstash |
| Primary Language | English (UK) |
| Age Rating | 4+ |
| Price | Free |
| Privacy Policy URL | https://benwhite.co/lab/privacy-policy.html |
| Support URL | https://github.com/BenWhite-git/card-stash/issues |
| Marketing URL | https://github.com/BenWhite-git/card-stash |

### Promotional Text (170 chars, editable without new build)

Your loyalty cards, encrypted on your device. No accounts, no tracking, no ads. Scan at the till in seconds. Free and open source.

### Description (UK English)

Card Stash keeps your loyalty and membership cards on your phone - encrypted, private, and always ready to scan.

No sign-up. No cloud. No ads. No tracking. Your cards never leave your device unless you choose to export them.

SCAN AND GO
- Scan any barcode with your camera or from a saved image
- Supports QR, Code 128, Code 39, EAN-13, EAN-8, DataMatrix, PDF417, Aztec, and more
- Full-screen barcode display at maximum brightness for reliable scanning at the till

STAY ORGANISED
- Search, sort, and favourite your cards
- Add custom colours, logos, and notes to each card
- Get notified before cards expire

BUILT FOR PRIVACY
- All data encrypted at rest with AES-256
- Encryption key stored in your device's secure enclave
- Zero network calls - not even for analytics or crash reports
- Payment cards (credit/debit) are automatically detected and rejected for your safety

MOVE TO A NEW PHONE
- Export all your cards as an encrypted file protected by a passphrase you choose
- Import on your new device - merge or replace
- On iPhone, AirDrop makes migration effortless

OPEN SOURCE
Card Stash is free, open source, and MIT licensed. Inspect every line of code on GitHub.

Designed and built in Cheshire, England.

### Keywords (100 chars max)

loyalty,card,wallet,barcode,scanner,membership,reward,encrypted,private,offline

### What's New (v1.0.0)

Initial release. Scan, store, and display your loyalty and membership cards - fully encrypted and completely private.

### App Privacy

"Does this app collect any data?" - **No**

### Review Notes

This is a local-only utility app. It stores loyalty card barcodes encrypted on-device. It makes no network calls. Camera permission is used solely for barcode scanning.

---

## Google Play Store (Google Play Console)

### Metadata

| Field | Value |
|---|---|
| App Name | Card Stash |
| Default Language | English (United Kingdom) |
| App Type | App (not Game) |
| Price | Free |
| Content Rating | PEGI 3 / Everyone (answer "No" to all IARC questions) |
| Privacy Policy URL | https://benwhite.co/lab/privacy-policy.html |
| Ads | No ads |
| Target Audience | 13+ (avoids COPPA requirements) |
| Data Safety | No data collected or shared. Uses encryption (AES-256). |

### Short Description (80 chars max)

Private, encrypted wallet for your loyalty and membership cards. No ads. Free.

### Full Description

Card Stash keeps your loyalty and membership cards on your phone - encrypted, private, and always ready to scan.

No sign-up. No cloud. No ads. No tracking. Your cards never leave your device unless you choose to export them.

SCAN AND GO
Scan any barcode with your camera or from a saved image. Card Stash supports QR, Code 128, Code 39, EAN-13, EAN-8, DataMatrix, PDF417, Aztec, and more. When you need to use a card, it displays full-screen at maximum brightness for reliable scanning at the till.

STAY ORGANISED
Search, sort, and favourite your cards. Add custom colours, logos, and notes to each card. Set expiry dates and get notified before cards expire - 30 days, 7 days, and on the day.

BUILT FOR PRIVACY
All data is encrypted at rest with AES-256. The encryption key is stored in your device's secure hardware. Card Stash makes zero network calls - not even for analytics or crash reports. Payment cards (credit and debit) are automatically detected and rejected for your safety.

MOVE TO A NEW PHONE
Export all your cards as an encrypted file protected by a passphrase you choose. Import on your new device with the option to merge or replace your existing cards.

OPEN SOURCE
Card Stash is free, open source, and MIT licensed. Inspect every line of code on GitHub.

Designed and built in Cheshire, England.

### Tags

Loyalty cards, Barcode scanner, Wallet, Privacy, Utilities

---

## US English Variants

For the US English listing on both platforms, apply these substitutions:

| UK English | US English |
|---|---|
| favourite | favorite |
| colours | colors |
| organised | organized |
| licenced | licensed |
| at the till | at checkout |

Keep "Cheshire, England" as-is - it is brand identity.

---

## Screenshots

### Required Sizes

- **Apple App Store:** 6.7" iPhone (1290 x 2796 px). iPad optional, skip for now.
- **Google Play:** Phone screenshots at native device resolution. Tablet optional, skip for now.

### Sequence (6 screenshots, both platforms)

| # | Screen | Headline | Details |
|---|---|---|---|
| 1 | Home screen (5-6 cards) | **Your cards, always ready** | Varied card colours, a favourite pinned to top, an expiry badge visible. Dark theme. |
| 2 | Card display (barcode) | **Scan in seconds** | Full brightness, clear barcode (EAN-13 or QR), card number below. |
| 3 | Camera scanner | **Add cards instantly** | Scanner active with a barcode visible in the viewfinder. |
| 4 | Edit card screen | **Make each card yours** | Custom colour selected, logo added, notes filled in. Colour picker visible. |
| 5 | Export screen | **Migrate with confidence** | Passphrase field and encryption messaging visible. |
| 6 | About screen | **Free. Private. Open source.** | Version, privacy-first messaging, open source badge. |

### Production Steps

1. Take raw screenshots in dark theme on iOS Simulator (iPhone 16 Pro Max) and Android phone
2. Frame each screenshot in a device mockup with a headline above
3. Background colour: Sunlight dark slate (#0F172A)
4. Headline font: Inter Bold, white or warm ivory (#FFFBF7)
5. Export at required pixel dimensions per platform

Recommended tools: screenshots.pro or Figma with a free device mockup template.

### iOS Simulator Commands

```bash
xcrun simctl boot "iPhone 16 Pro Max"
flutter run -d "iPhone 16 Pro Max"
xcrun simctl io booted screenshot ~/Desktop/screenshot_1.png
```

---

## Additional Assets

### App Icon

- **Apple:** 1024x1024 PNG, no transparency, no rounded corners
- **Google Play:** 512x512 PNG, 32-bit with alpha

Verify existing assets:
- `ios/Runner/Assets.xcassets/AppIcon.appiconset/`
- `android/app/src/main/res/`

### Feature Graphic (Google Play only)

- 1024 x 500 px PNG or JPG
- App icon centred on dark background (#0F172A)
- "Card Stash" in Inter Bold, "Private loyalty card wallet" as tagline
- Keep clean - Google overlays a play button in some contexts

---

## Submission Steps

### Apple App Store

1. `flutter build ipa --release`
2. Open the archive in Xcode, Organizer > Distribute App > App Store Connect > Upload
3. In App Store Connect: My Apps > + New App > iOS
4. Fill in App Information, Pricing (Free), App Privacy (No data collected)
5. Upload screenshots, fill version page with copy above
6. Submit for Review with the review notes above
7. Estimated review: 24-48 hours

### Google Play

1. `flutter build appbundle --release`
2. In Play Console: Create app > Card Stash > English (UK) > App > Free
3. Fill Store listing with copy above, upload screenshots and feature graphic
4. Add US English translation
5. Complete Content rating (IARC), App content (privacy policy, no ads, data safety)
6. Internal testing first, then Production release
7. Estimated review: a few hours to 3 days

---

## Pre-Submission Checklist

- [ ] Privacy policy updated to name Card Stash
- [ ] `flutter build ipa --release` succeeds
- [ ] `flutter build appbundle --release` succeeds
- [ ] App icon at 1024x1024 (iOS) and 512x512 (Android)
- [ ] 6 iOS screenshots taken (iPhone 16 Pro Max simulator)
- [ ] 6 Android screenshots taken (physical device)
- [ ] Screenshots framed with device mockups and headlines
- [ ] Feature graphic created (1024x500) for Google Play
- [ ] Apple Developer account active, bundle ID registered
- [ ] Google Play Console account active
- [ ] Store copy reviewed for UK/US English variants
- [ ] Release builds tested on physical devices

---

## Post-Submission

- Update `docs/CHANGELOG.md` with v1.0.0 release date
- Add App Store and Play Store badge links to `README.md` once live
- Note bundle ID and store listing URLs in `docs/CONTRIBUTING.md`
