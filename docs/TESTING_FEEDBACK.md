# Card Stash - Testing and Feedback

Tracker for issues found during hands-on device testing.

---

## Item 1: Save button position and accidental Scan trigger

**Screen:** Add Card (manual/post-scan mode)
**Problem:** Save Card button is at the bottom, requiring scroll. The "Scan" button in the AppBar is too easy to hit by accident when editing fields after a scan, losing entered data.
**Fix:** Move Save Card button to the top of the form. Remove the "Scan" AppBar action entirely.
**Status:** Fixed

## Item 2: More colour options including custom picker

**Screen:** Add Card / Edit Card
**Problem:** Limited colour palette. No way to pick a custom colour.
**Fix:** Expand preset colours (16 total) and add a custom HSV colour picker dialog via rainbow circle button.
**Status:** Fixed

## Item 3: Card number text too light on display screen

**Screen:** Card Display
**Problem:** The card number below the barcode is not dark enough. Fails accessibility contrast requirements. Especially bad for Display Only cards where the number is the primary content.
**Fix:** Set card number text to `Colors.black` with `FontWeight.w600` for both barcode and displayOnly modes.
**Status:** Fixed

## Item 4: Card name field should auto-capitalise words

**Screen:** Add Card / Edit Card
**Problem:** Keyboard doesn't capitalise each word when typing the card name.
**Fix:** Set `textCapitalization: TextCapitalization.words` on the card name field in both add and edit screens.
**Status:** Fixed

## Item 5: Android adaptive icon shows square logo in white circle

**Screen:** Home screen / app drawer
**Problem:** The square app icon doesn't work with Android's adaptive icon system, resulting in the logo being placed inside a white circle.
**Fix:** Removed baked-in dark background from foreground PNGs, making them transparent. The background colour is already set via `@color/ic_launcher_background` in the adaptive icon XML.
**Status:** Fixed

## Item 6: Card number field should show number keyboard

**Screen:** Add Card
**Problem:** Tapping the card number field shows the full text keyboard instead of the number keyboard.
**Fix:** N/A - design decision to keep alphanumeric keyboard. Some loyalty card numbers contain letters (e.g. "ABC123"), so a numeric keyboard would prevent valid input.
**Status:** Closed (by design)

## Item 7: About screen uses wrong theme

**Screen:** About
**Problem:** About screen uses a hardcoded light theme (cream/white cards) while the rest of the app is dark slate. Looks like a completely different app.
**Fix:** Restyled to use `context.colors` from CardStashColors theme extension. Matches dark/light theme automatically.
**Status:** Fixed

## Item 8: Ko-fi and external links don't work

**Screen:** About
**Problem:** Ko-fi button, Privacy Policy, and GitHub links do nothing when tapped. Missing platform configuration for url_launcher.
**Fix:** Added `<queries><intent>` for https URLs in AndroidManifest.xml. Added `LSApplicationQueriesSchemes` with "https" to iOS Info.plist.
**Status:** Fixed

## Item 9: Light/dark/system theme option

**Screen:** Settings
**Problem:** App is dark-only. Users should be able to choose light, dark, or follow system theme.
**Fix:** Created CardStashColors theme extension with light/dark palettes. Added ThemeModeNotifier persisted to SharedPreferences. Added Appearance picker in Settings. Updated all screens to use `context.colors` instead of hardcoded hex values.
**Status:** Fixed

## Item 10: Card list sorting options

**Screen:** Home
**Problem:** Cards are sorted by usage count only. Users have no control over sort order.
**Fix:** Added CardSortMode enum (Most used, A-Z, Recently used, Newest first). Sort button on home screen opens bottom sheet picker. Favourites always pinned to top regardless of sort mode.
**Status:** Fixed

## Item 11: Home screen widget

**Screen:** N/A (native widget)
**Problem:** Widget was planned for v1.1 but not yet started. Requires native Swift (iOS WidgetKit) and Kotlin/XML (Android AppWidget) code.
**Fix:** Already documented in SPEC.md and BUILD_ORDER.md under v1.1 phases. Requires pre-rendered barcode PNGs via home_widget package.
**Status:** Open (v1.1 scope)
