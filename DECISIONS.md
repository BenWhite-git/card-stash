# Decisions

Append-only log of decisions made on Card Stash, numbered from D001 upwards with the newest at the bottom. Architectural rationale in prose lives in `docs/ARCHITECTURE.md`; this file records the choice, the alternatives and what it would cost to reverse.

## D001 - Schedule notifications as UTC instants and stop loading the timezone database at launch
**Date.** 2026-10-16
**Status.** Accepted
**Decision.** `NotificationService.scheduledDateFor` converts local 9am on the target day to a UTC `TZDateTime`; `main` no longer imports `timezone/data/latest_all.dart` or calls `initializeTimeZones`.
**Why.** The full database costs roughly 450 KB in the snapshot and a main-isolate deserialisation before the first frame. `tz.local` was never set, so the app already scheduled UTC instants; the change makes that explicit and removes startup work with no behaviour change. The `timezone` package stays as a dependency because `flutter_local_notifications` requires a `TZDateTime`.
**Alternatives rejected.** `latest_10y` (smaller but still unnecessary work at launch). Lazily initialising the database on first schedule (keeps dead code and a hidden ordering dependency).
**Consequences.** Alerts fire at 9am in the zone the device was in when the card was saved. Any future feature that needs named zones must initialise the database itself at the point of use.
**Reversal cost.** Trivial, restore the import and the `tz.local` call.

## D002 - Keep initialisation before `runApp` rather than showing a loading screen
**Date.** 2026-10-16
**Status.** Accepted
**Decision.** Startup still awaits storage, preferences and notification initialisation before `runApp`, but the three now run concurrently.
**Why.** A splash-first flow needs loading and error states for key retrieval failure and adds a second first frame. With parallel initialisation the wait should be short enough that a splash would not be noticed; without an on-device measurement there is no evidence it is needed.
**Alternatives rejected.** `runApp` immediately with a themed placeholder and async initialisation, deferred until measurement shows more than roughly 300 ms before the first frame (tracked in `docs/TODO.md`).
**Consequences.** The native launch window is the only thing on screen during initialisation, which is why its colour now matches the app background.
**Reversal cost.** Moderate, requires a loading widget, an error state for `StorageService.init` failures and widget tests for both.

## D003 - Require the release keystore for release builds and fail loudly without it
**Date.** 2026-10-17
**Status.** Accepted
**Decision.** `android/app/build.gradle.kts` signs release builds from `android/key.properties` and throws a `GradleException` from `taskGraph.whenReady` when a release task is requested and the file is absent. Debug builds are unaffected.
**Why.** The v1.0.0 APK on GitHub Releases was signed with the Android debug key because the template `signingConfig = debug` was never replaced. A debug-signed release cannot be updated in place by a properly signed one, and the longer it ships the more users are affected. Failing at configuration time for release tasks only is the smallest change that makes the mistake impossible to repeat.
**Alternatives rejected.** Falling back to the debug key when `key.properties` is missing (the status quo, and exactly the failure being fixed). Letting Gradle fail with its own "keystore not set" error (unclear, and reached only at the signing step after a long build). Committing an encrypted keystore to the repo (unnecessary for a single maintainer).
**Consequences.** The next release changes the signing key, so existing v1.0.0 installs must export, uninstall and import. Contributors cannot produce release builds without the maintainer's keystore, which is intended. CI builds only debug artefacts.
**Reversal cost.** Trivial to revert the Gradle change; the key change itself cannot be reversed once a signed release has shipped.

## D004 - Backup reminder thresholds: 3 cards, 30 days stale, 7 day snooze
**Date.** 2026-10-17
**Status.** Accepted
**Decision.** Show the home screen backup banner when the wallet has at least 3 cards and has never been exported, or when the last export is older than 30 days and at least one card was added since. "Later" snoozes for 7 days. State is two ISO timestamps in SharedPreferences.
**Why.** No specification existed for this; the thresholds resolve the uncertainty by picking values that avoid nagging a brand-new user (1 or 2 cards) and avoid nagging anyone whose wallet has not changed since their last export. Staleness is judged from `createdAt`, which already exists on the card model.
**Alternatives rejected.** Reminder on first card (too eager). Tracking edits via a new `modifiedAt` field (model change plus Hive migration for little benefit). A scheduled local notification (needs permission, heavier than a banner).
**Consequences.** Edits alone never trigger a reminder. Thresholds are constants, so tuning is a one-line change.
**Reversal cost.** Trivial, remove the banner and the provider; the two preference keys can be left orphaned or cleared.
