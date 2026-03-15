# Security

This document describes Card Stash's security model, design decisions, and known limitations.

---

## Threat Model

Card Stash is a personal utility app storing loyalty and membership card numbers. The primary threat is **unauthorised access to card data if a device is lost, stolen, or inspected**. It is not designed to protect against nation-state actors, OS-level exploits, or a compromised device.

Payment cards are explicitly out of scope and actively rejected — see [Payment Card Rejection](#payment-card-rejection).

---

## Encryption at Rest

All card data is encrypted using **AES-256** via [Hive CE](https://github.com/IO-Design-Team/hive_ce) with a `HiveCipher` backed by a securely generated key.

### Key Generation and Storage

On first launch, a 256-bit encryption key is generated and stored in the **device's secure enclave**:

- **iOS:** Apple Keychain via `flutter_secure_storage`
- **Android:** Android Keystore via `flutter_secure_storage`

The key is never written to the filesystem, never transmitted, and never included in backups.

### Key Loss

If the key cannot be retrieved (e.g. following a factory reset, app uninstall, or certain Android OEM behaviours after an OS upgrade), the encrypted database is permanently unrecoverable. This is the correct and intended behaviour.

Users are informed of this at first launch:

> "Your cards are stored securely on this device only. If you uninstall Card Stash, your data cannot be recovered."

### No Biometric Gate (v1.0)

Encryption at rest protects data on a locked or powered-off device. In v1.0, there is no secondary authentication layer — the app is accessible to anyone who can unlock the host device. Biometric lock (Face ID / Touch ID / fingerprint) is planned for v1.1 via `local_auth`.

---

## Android Auto-Backup

Android's auto-backup mechanism can back up app data to Google Drive. If it includes the encrypted Hive database without the corresponding Keystore key, the backup is useless — but worse, it may create a false sense of recoverability.

**Auto-backup must be disabled for the Hive storage directory.**

In `android/app/src/main/AndroidManifest.xml`:

```xml
<application
  android:allowBackup="false"
  ...>
```

If granular backup rules are required in future, use `android:fullBackupContent` with explicit exclusion of the Hive data directory rather than re-enabling blanket backup.

---

## Payment Card Rejection

Card Stash is not designed or permitted to store credit or debit card numbers. Two layers of protection are implemented:

**Layer 1 — Luhn algorithm + BIN range detection**

On manual card number entry, numbers that both pass the [Luhn check](https://en.wikipedia.org/wiki/Luhn_algorithm) and match known payment card BIN prefixes are hard-rejected. The user is shown:

> "This looks like a payment card. For your security, Card Stash doesn't store credit or debit cards. Use Apple Pay or Google Wallet instead."

**Layer 2 — First-launch notice**

Users are informed on first launch that Card Stash is for loyalty and membership cards only.

**Limitation:** Detection is heuristic, not perfect. A small number of loyalty card numbers may be incorrectly flagged (false positive); a very small number of payment card numbers may pass undetected (false negative). The onboarding notice covers residual risk.

If you discover a bypass or systematic failure in payment card detection, please report it — see [Reporting a Vulnerability](#reporting-a-vulnerability) below.

---

## No Network Access

Card Stash makes no network requests. There are no servers, no APIs, no analytics SDKs, and no third-party services. All functionality is on-device.

This can be verified by running the app through a proxy (e.g. Charles, mitmproxy) or inspecting network traffic with a packet capture tool.

---

## Dependencies

Card Stash relies on the following packages with security implications:

| Package | Role | Notes |
|---|---|---|
| `hive_ce` | Encrypted storage | AES-256; actively maintained community fork |
| `flutter_secure_storage` | Key storage | Wraps iOS Keychain and Android Keystore |
| `mobile_scanner` | Camera / barcode scan | Camera permission only; no network access |
| `flutter_local_notifications` | Expiry notifications | Local only; no push infrastructure |

Dependencies should be kept up to date. Run `flutter pub outdated` regularly and prioritise security-related updates.

---

## Reporting a Vulnerability

This is an open source side project. There is no formal security disclosure programme.

If you find a vulnerability — particularly anything relating to payment card detection bypass or key storage — please open a [GitHub issue](https://github.com/yourname/card-stash/issues) marked **[SECURITY]**, or contact the maintainer directly via the email listed in the repository profile.

Please do not include full exploit details in a public issue.
