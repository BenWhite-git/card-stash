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
