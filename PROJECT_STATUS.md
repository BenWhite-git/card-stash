# Card Stash - Project Status

## Current Phase: Phase 1 - Encrypted Storage Foundation (next)

## Phase Progress

| Phase | Description | Status |
|---|---|---|
| 0 | Project Scaffold | Done |
| 1 | Encrypted Storage Foundation | Next |
| 2 | Card Display Screen | Pending |
| 3 | Home Screen (Card List) | Pending |
| 4 | Add Card Screen | Pending |
| 5 | Edit Card Screen | Pending |
| 6 | Expiry Notifications | Pending |
| 7 | Settings, Export and Import | Pending |
| 8 | About Screen | Pending |
| 9 | Polish and Pre-Release | Pending |

## Phase 1 Plan

Decisions made before starting:
- Add `shared_preferences` for first-launch flag (independent of encrypted storage)
- Use `AsyncNotifierProvider` for card list (Hive box opening is async)
- Abstract StorageService behind a provider for testability (in-memory Hive box in tests)
- First-launch flag in shared_preferences, not Hive (avoids chicken-and-egg if key retrieval fails)

## Notes

- GitHub repo: https://github.com/BenWhite-git/card-stash (public)
- Style guide: `docs/sunlight-style-guide.md`
- All docs live in `/docs`
- No secrets, no network calls, no analytics
