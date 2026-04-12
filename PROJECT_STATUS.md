# Card Stash - Project Status

## Current State: v1.0.0 shipped 2026-03-17, unreleased work in progress

## Phase Progress

| Phase | Description | Status |
|---|---|---|
| 0 | Project Scaffold | Done |
| 1 | Encrypted Storage Foundation | Done |
| 2 | Card Display Screen | Done |
| 3 | Home Screen (Card List) | Done |
| 4 | Add Card Screen | Done |
| 5 | Edit Card Screen | Done |
| 6 | Expiry Notifications | Done |
| 7 | Settings, Export and Import | Done |
| 8 | About Screen | Done |
| 9 | Polish and Pre-Release | Done |

v1.0.0 shipped 2026-03-17 with the full MVP scope. Feature detail lives in `docs/CHANGELOG.md`; per-phase history lives in `docs/BUILD_ORDER.md` and git log.

## Unreleased Work

Queued for the next release (see `docs/CHANGELOG.md` [Unreleased] for detail):

- Live camera OCR with real-time text overlay (camera + parallel ML Kit barcode and text recognition)
- Duplicate card number detection on add and edit
- Editable card number on the edit screen
- Scan barcode from saved photo via gallery picker
- Light / dark / system theme with Appearance picker
- Card list sorting modes
- Custom HSV colour picker plus six additional preset colours
- `file_picker` upgraded 10 to 11.0.2 (Android path-traversal CVE fix)

## Notes

- GitHub repo: https://github.com/BenWhite-git/card-stash (public)
- Style guide: `docs/sunlight-style-guide.md`
- All docs live in `/docs`
- No secrets, no network calls, no analytics

## Pre-Release Follow-ups

- Verify `.cardstash` import on a real iOS device and a real Android device after the `file_picker` 10 to 11 upgrade (2026-04-12). Unit tests cover the wrapper via `FakeFilePickerService`, but the real file association path (iOS UTType + Android content provider) needs hardware testing before the next release ships.
- Revisit `share_plus` 12 to 13 and `package_info_plus` 9 to 10 once `file_picker` publishes a version compatible with `win32 ^6.0.0` — both are cosmetic transitive bumps with no API changes, currently blocked by a three-way win32 conflict.
- Consider adding `osv-scanner --lockfile=pubspec.lock` to CI before the next release — Dart has no built-in vulnerability scanner and the 2026-04-12 audit flagged this as a gap.
