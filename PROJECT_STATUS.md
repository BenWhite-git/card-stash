# Card Stash - Project Status

## Current Phase: Phase 2 - Card Display Screen (next)

## Phase Progress

| Phase | Description | Status |
|---|---|---|
| 0 | Project Scaffold | Done |
| 1 | Encrypted Storage Foundation | Done |
| 2 | Card Display Screen | Next |
| 3 | Home Screen (Card List) | Pending |
| 4 | Add Card Screen | Pending |
| 5 | Edit Card Screen | Pending |
| 6 | Expiry Notifications | Pending |
| 7 | Settings, Export and Import | Pending |
| 8 | About Screen | Pending |
| 9 | Polish and Pre-Release | Pending |

## Phase 1 Completed

Decisions made and implemented:
- Model class named `LoyaltyCard` (not `Card`) to avoid Flutter widget name collision
- `shared_preferences` added for first-launch flag (independent of encrypted storage)
- Synchronous `NotifierProvider` for card list (Hive box init completes before `runApp`)
- `StorageService` initialised in `main()` and injected via provider override
- `StorageService.fromBox()` factory for test injection (in-memory Hive box)
- 10 unit tests covering all CRUD operations and sort order
- Zero analyzer warnings

## Notes

- GitHub repo: https://github.com/BenWhite-git/card-stash (public)
- Style guide: `docs/sunlight-style-guide.md`
- All docs live in `/docs`
- No secrets, no network calls, no analytics
