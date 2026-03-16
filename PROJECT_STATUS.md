# Card Stash - Project Status

## Current Phase: Phase 4 Complete - Add Card Screen

## Phase Progress

| Phase | Description | Status |
|---|---|---|
| 0 | Project Scaffold | Done |
| 1 | Encrypted Storage Foundation | Done |
| 2 | Card Display Screen | Done |
| 3 | Home Screen (Card List) | Done |
| 4 | Add Card Screen | Done |
| 5 | Edit Card Screen | Next |
| 6 | Expiry Notifications | Pending |
| 7 | Settings, Export and Import | Pending |
| 8 | About Screen | Pending |
| 9 | Polish and Pre-Release | Pending |

## Phase 4 Completed

- LuhnValidator: pure Dart Luhn algorithm (payment card checksum detection)
- BinDetector: BIN range matching for Visa, Mastercard, Amex, Maestro, Discover
- BarcodeTypeHelper: maps mobile_scanner formats to BarcodeType enum
- ScannerService: wraps mobile_scanner, extracts card number and barcode type
- AddCardScreen: camera scan with viewfinder, manual entry with form fields, payment card rejection, colour picker, barcode type chips, expiry date picker
- OnboardingScreen: first-launch-only with payment card warning, sets SharedPreferences flag
- Router updated to factory function `createRouter()` with first-launch routing
- 144 total tests, all passing, zero analyzer warnings

## Phase 3 Completed

- ExpiryBadge widget with UTC date comparison (DST-safe)
- CardTile widget with colour accent, favourite star, note indicator, expiry badge
- HomeScreen with sorted list, fuzzy search, Pinned/Most Used sections, empty state
- Long-press action sheet: Edit, Share, Toggle Favourite, Delete with confirmation
- go_router with ShellRoute for bottom nav (Cards, Alerts, About)
- CardDisplayScreen pushed as full-screen overlay outside the nav shell
- Sunlight dark theme on app shell and navigation bar

## Phase 2 Completed

- BrightnessService with save/force/restore via screen_brightness
- BarcodeView widget rendering all barcode types at max safe width
- CardDisplayScreen with full-screen display, tap to dismiss
- Usage tracking delegated to caller (not screen) due to FakeAsync/Hive constraint

## Phase 1 Completed

- LoyaltyCard model, BarcodeType enum, Hive CE generated adapters
- StorageService with encrypted box, 256-bit key in secure enclave
- CardListNotifier with full CRUD, sorted by favourites then usage
- First-launch flag via SharedPreferences

## Notes

- GitHub repo: https://github.com/BenWhite-git/card-stash (public)
- Style guide: `docs/sunlight-style-guide.md`
- All docs live in `/docs`
- No secrets, no network calls, no analytics
