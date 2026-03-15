# Sunlight Style Guide

A portable design system derived from the [Sunlight](https://github.com/BenWhite-git/sunlight) app's visual language. Use this guide for web apps, dashboards, documentation sites, and printed documents.

The aesthetic is **minimal, warm, and precise** — deep slate backgrounds with warm amber accents in dark mode, soft ivory with stone tones in light mode. No gradients. No heavy shadows. Depth comes from borders, opacity, and subtle glow effects.

---

## Table of Contents

1. [Colour Palette](#colour-palette)
2. [Typography](#typography)
3. [Spacing & Layout](#spacing--layout)
4. [Border Radius](#border-radius)
5. [Opacity](#opacity)
6. [Shadows](#shadows)
7. [Components](#components)
   - [Tables](#tables)
   - [Buttons](#buttons)
   - [Cards](#cards)
   - [Form Inputs](#form-inputs)
   - [Links](#links)
   - [Code](#code)
   - [Alerts](#alerts)
   - [Badges](#badges)
   - [Dividers](#dividers)
8. [Accessibility](#accessibility)

---

## Colour Palette

Colours are organized by **role**, not by visual appearance. Use the role name when referring to colours — this makes theme switching seamless.

### Dark Theme

| Role | Hex | Description |
|------|-----|-------------|
| `bg-primary` | `#0F172A` | Page background |
| `bg-secondary` | `#1E293B` | Elevated surfaces, table headers |
| `bg-deep` | `#020617` | Recessed areas, code blocks |
| `night` | `#1E1B4B` | Deep indigo for decorative/semantic use |
| `twilight` | `#312E81` | Mid-indigo for info states |
| `sun` | `#FBBF24` | Warm amber for decorative emphasis |
| `text-primary` | `#F8FAFC` | Body text, headings |
| `text-secondary` | `#CBD5E1` | Supporting text, descriptions |
| `text-muted` | `#94A3B8` | Placeholders, disabled text, captions |
| `accent` | `#F59E0B` | Link text, accent text |
| `accent-fill` | `#F59E0B` | Button fills, borders, focus rings, decorative |
| `danger` | `#EF4444` | Destructive actions, critical alerts |
| `card-bg` | `#1E293B` | Card fill (apply with opacity — see [Opacity](#opacity)) |
| `card-border` | `#334155` | Card and input borders |
| `positive` | `#34D399` | Success states, gains |
| `negative` | `#FB7185` | Error states, losses |
| `divider` | `#334155` | Horizontal rules, table borders |
| `neutral` | `#E2E8F0` | Neutral indicators, secondary icons |

### Light Theme

| Role | Hex | Description |
|------|-----|-------------|
| `bg-primary` | `#FFFBF7` | Page background (warm ivory) |
| `bg-secondary` | `#FEF7ED` | Elevated surfaces (soft cream) |
| `bg-deep` | `#FFF9F0` | Recessed areas (warm off-white) |
| `night` | `#1E1B4B` | Deep indigo (same as dark) |
| `twilight` | `#6D28D9` | Brighter violet for light backgrounds |
| `sun` | `#F59E0B` | Warm amber (slightly darker than dark theme) |
| `text-primary` | `#1C1917` | Body text, headings |
| `text-secondary` | `#44403C` | Supporting text |
| `text-muted` | `#78716C` | Placeholders, disabled text |
| `accent` | `#D97706` | Link text, accent text (darker for contrast on light bg) |
| `accent-fill` | `#F59E0B` | Button fills, borders, focus rings, decorative |
| `danger` | `#DC2626` | Destructive actions |
| `card-bg` | `#FFFFFF` | Card fill (solid white) |
| `card-border` | `#E7E5E4` | Card and input borders |
| `positive` | `#059669` | Success states |
| `negative` | `#E11D48` | Error states |
| `divider` | `#D6D3D1` | Horizontal rules, table borders |
| `neutral` | `#78716C` | Neutral indicators |

### Choosing a Theme

- **Dark** is the primary theme. Prefer it for apps, dashboards, and screens used in varied lighting.
- **Light** works well for documents, print, and content-heavy reading.
- Respect `prefers-color-scheme` when possible. Offer a manual toggle.

---

## Typography

**Font family:** Inter (available on [Google Fonts](https://fonts.google.com/specimen/Inter)).
**Code font:** JetBrains Mono (available on [Google Fonts](https://fonts.google.com/specimen/JetBrains+Mono)).

### Type Scale

| Name | Size | Weight | Line Height | Letter Spacing | Use |
|------|------|--------|-------------|----------------|-----|
| Display | 48px | 300 (Light) | 1.1 | -0.02em | Hero sections, large numbers |
| H1 | 36px | 600 (Semibold) | 1.2 | -0.01em | Page titles |
| H2 | 30px | 600 | 1.25 | normal | Section headings |
| H3 | 24px | 600 | 1.3 | normal | Subsection headings |
| H4 | 20px | 600 | 1.35 | normal | Card titles, panel headers |
| H5 | 18px | 600 | 1.4 | normal | Minor headings |
| H6 | 16px | 700 (Bold) | 1.4 | normal | Inline headings |
| Body | 16px | 400 (Regular) | 1.6 | normal | Default text |
| Body Small | 14px | 400 | 1.5 | normal | Secondary content, table cells |
| Caption | 12px | 400 | 1.4 | normal | Metadata, timestamps |
| Label | 11px | 600 | 1.25 | 1.2px | Uppercase labels only |
| Code | 14px | 400 | 1.5 | normal | JetBrains Mono |

### Typography Rules

- **Paragraph spacing:** `1em` margin below paragraphs.
- **Max reading width:** `65ch` (~720px) for body text. Don't let lines run wider.
- **Heading spacing:** `1.5em` margin above headings, `0.5em` below.
- **Labels** are always uppercase and use `letter-spacing: 1.2px`. Never use the Label style for mixed-case text.
- **Display** weight is Light (300) — the only place light weight is used. Everything else is Regular (400) or Semibold (600).
- Negative letter-spacing on Display and H1 tightens large text for visual density.

---

## Spacing & Layout

**Base unit:** 4px. All spacing values are multiples of 4.

| Token | Value | Use |
|-------|-------|-----|
| `xs` | 4px | Icon-to-text gaps, tight inline spacing |
| `sm` | 8px | Related elements within a group |
| `md` | 12px | Compact card padding |
| `base` | 16px | Default padding, standard gaps |
| `lg` | 20px | Comfortable card padding |
| `xl` | 24px | Section padding, generous gaps |
| `2xl` | 32px | Between major sections |
| `3xl` | 48px | Page section breaks |
| `4xl` | 64px | Top-level layout divisions |

### Layout Widths

| Context | Max Width |
|---------|-----------|
| Reading content (prose) | 65ch (~720px) |
| App content area | 1200px |
| Wide layout (dashboards) | 1440px |
| Full bleed | no max |

---

## Border Radius

| Token | Value | Use |
|-------|-------|-----|
| `none` | 0 | Hard edges, dividers |
| `sm` | 4px | Inline code, tiny accents |
| `md` | 8px | Buttons, inputs, code blocks, alerts |
| `lg` | 12px | Medium panels, dropdown menus |
| `xl` | 16px | Standard cards, modals, dialogs |
| `2xl` | 24px | Feature cards, hero sections |
| `full` | 9999px | Pills, badges, avatar circles |

---

## Opacity

Used for layering, emphasis, and interactive states. Apply to colour values, not to entire elements (which would also fade text).

| Level | Use |
|-------|-----|
| `0.05` | Table row hover tint |
| `0.10` | Subtle accent wash, secondary button hover |
| `0.15` | Alert and badge backgrounds |
| `0.20` | Overlay backgrounds |
| `0.30` | Soft emphasis, muted fills |
| `0.40` | Dark theme card backgrounds |
| `0.50` | Medium overlays |
| `0.60` | Strong overlays, glow effects |

---

## Shadows

The Sunlight aesthetic prefers **borders and opacity** for depth over box shadows. Shadows are optional and best suited to light theme only.

| Token | Value | Use |
|-------|-------|-----|
| `sm` | `0 1px 2px rgba(0,0,0,0.05)` | Subtle lift |
| `md` | `0 4px 6px rgba(0,0,0,0.07)` | Cards, dropdowns |
| `lg` | `0 10px 15px rgba(0,0,0,0.10)` | Modals, popovers |

In **dark theme**, use `card-border` instead of shadows for element definition.

---

## Components

### Tables

Tables use minimal styling. Borders between rows, no vertical rules.

| Property | Value |
|----------|-------|
| Header background | `bg-secondary` |
| Header text | `text-primary`, semibold |
| Cell padding | `12px` horizontal, `10px` vertical |
| Row border | `1px solid divider` (between rows only) |
| Alternating rows | `bg-secondary` at opacity `0.3` (dark) or `0.5` (light) |
| Row hover | `accent-fill` at opacity `0.05` |
| Table border-radius | `8px` on the outer container |
| Cell text | Body Small (14px regular) |

Wrap the table in a container with `border-radius: 8px` and `overflow: hidden` to round the corners.

### Buttons

All buttons use `14px` semibold text, `8px` border-radius, and `150ms ease` transitions.

| Variant | Background | Text | Border |
|---------|-----------|------|--------|
| **Primary** | `accent-fill` | `bg-primary` | none |
| **Secondary** | transparent | `accent` | `1px solid accent-fill` |
| **Ghost** | transparent | `text-secondary` | none |
| **Danger** | `negative` | white | none |

**Sizes:**

| Size | Padding |
|------|---------|
| Small | `8px 16px` |
| Default | `10px 20px` |
| Large | `14px 28px` |

**States:**
- **Hover:** Primary and Danger darken 10%. Secondary fills with `accent-fill` at `0.10`. Ghost fills with `bg-secondary`.
- **Disabled:** Background `text-muted` at `0.20`, text `text-muted`. No hover change. Use `cursor: not-allowed`.
- **Focus:** See [Accessibility](#accessibility).

### Cards

| Property | Dark | Light |
|----------|------|-------|
| Background | `card-bg` at `0.40` | `card-bg` (solid white) |
| Border | `1px solid card-border` | `1px solid card-border` |
| Radius | `16px` (standard) / `24px` (feature) | same |
| Padding | `16px` (compact) / `24px` (standard) | same |
| Shadow | none | `shadow-sm` (optional) |

Cards should not be nested. If you need hierarchy within a card, use dividers or spacing.

### Form Inputs

Covers text inputs, textareas, and select elements.

| Property | Value |
|----------|-------|
| Background | `bg-secondary` (dark) / `card-bg` (light) |
| Border | `1px solid card-border` |
| Border radius | `8px` |
| Padding | `10px 12px` |
| Text | `text-primary`, Body (16px) |
| Placeholder | `text-muted` |
| Focus border | `2px solid accent-fill` |
| Focus ring | `box-shadow: 0 0 0 3px accent-fill` at `0.20` |

**Labels:** `text-secondary`, 14px semibold, `4px` margin below the label.

**Validation states:**
- Error: replace border with `1px solid negative`. Add error message in `negative` colour below the input, Caption size.
- Success: replace border with `1px solid positive` (use sparingly).

### Links

| State | Style |
|-------|-------|
| Default | `accent` colour, no underline |
| Hover | `accent` colour, underline |
| Visited | `accent` at `0.70` opacity |
| Focus | See [Accessibility](#accessibility) |

Within body text, links should be the only non-`text-primary` colour. Don't combine link colour with bold or other emphasis.

### Code

**Inline code:**

| Property | Value |
|----------|-------|
| Font | JetBrains Mono, 14px |
| Background | `bg-secondary` |
| Padding | `2px 6px` |
| Border radius | `4px` |
| Border | `1px solid card-border` |

**Code blocks:**

| Property | Dark | Light |
|----------|------|-------|
| Background | `bg-deep` | `bg-secondary` |
| Text | `text-primary` | `text-primary` |
| Padding | `16px` | `16px` |
| Border radius | `8px` | `8px` |
| Border | `1px solid card-border` | `1px solid card-border` |
| Overflow | `overflow-x: auto` | `overflow-x: auto` |

Code blocks should use the full Code type style (JetBrains Mono, 14px, line-height 1.5).

### Alerts

Structure: container with `4px` left border, tinted background, text content.

| Type | Border Colour | Background | Text/Icon Colour |
|------|--------------|------------|-----------------|
| **Info** | `twilight` | `twilight` at `0.15` | `twilight` |
| **Success** | `positive` | `positive` at `0.15` | `positive` |
| **Warning** | `accent-fill` | `accent-fill` at `0.15` | `accent` |
| **Error** | `negative` | `negative` at `0.15` | `negative` |

- Padding: `12px 16px`
- Border radius: `8px` (right side and corners only — left side is flush with the border)
- Title: Body Small, semibold, semantic colour
- Body: Body Small, `text-primary`

### Badges

Small status indicators.

| Property | Value |
|----------|-------|
| Padding | `4px 10px` |
| Border radius | `full` (9999px) |
| Font | Caption (12px), semibold |
| Colour scheme | Semantic colour for text, semantic fill colour at `0.15` for background |

### Dividers

- `1px solid divider`
- `16px` margin above and below
- Span the full width of their container

---

## Accessibility

### Focus States

All interactive elements (buttons, inputs, links, custom controls):

- `outline: 2px solid accent-fill`
- `outline-offset: 2px`
- Only visible on `:focus-visible` (keyboard navigation), not on click

### Contrast

The palette is designed with WCAG AA contrast in mind:

- `text-primary` on `bg-primary`: exceeds 4.5:1 in both themes
- `text-secondary` on `bg-primary`: meets 4.5:1
- `text-muted` on `bg-primary`: meets 3:1 (suitable for large text and non-essential info)
- `accent` on `bg-primary`: passes in both themes. In light theme, `accent` is darkened to `#D97706` specifically for text contrast.
- `accent-fill` (`#F59E0B`) is used for non-text elements (fills, borders, focus rings) where text contrast against the page background isn't a concern.

### Reduced Motion

Respect `prefers-reduced-motion`:
- Remove transitions on buttons and hover effects
- Disable glow animations if used

---

## Source

Colour values are sourced from the Sunlight app's theme system:
`lib/core/constants/theme_constants.dart` — the `SunlightColors` ThemeExtension class.# Sunlight Style Guide

A portable design system derived from the [Sunlight](https://github.com/BenWhite-git/sunlight) app's visual language. Use this guide for web apps, dashboards, documentation sites, and printed documents.

The aesthetic is **minimal, warm, and precise** — deep slate backgrounds with warm amber accents in dark mode, soft ivory with stone tones in light mode. No gradients. No heavy shadows. Depth comes from borders, opacity, and subtle glow effects.

---

## Table of Contents

1. [Colour Palette](#colour-palette)
2. [Typography](#typography)
3. [Spacing & Layout](#spacing--layout)
4. [Border Radius](#border-radius)
5. [Opacity](#opacity)
6. [Shadows](#shadows)
7. [Components](#components)
   - [Tables](#tables)
   - [Buttons](#buttons)
   - [Cards](#cards)
   - [Form Inputs](#form-inputs)
   - [Links](#links)
   - [Code](#code)
   - [Alerts](#alerts)
   - [Badges](#badges)
   - [Dividers](#dividers)
8. [Accessibility](#accessibility)

---

## Colour Palette

Colours are organized by **role**, not by visual appearance. Use the role name when referring to colours — this makes theme switching seamless.

### Dark Theme

| Role | Hex | Description |
|------|-----|-------------|
| `bg-primary` | `#0F172A` | Page background |
| `bg-secondary` | `#1E293B` | Elevated surfaces, table headers |
| `bg-deep` | `#020617` | Recessed areas, code blocks |
| `night` | `#1E1B4B` | Deep indigo for decorative/semantic use |
| `twilight` | `#312E81` | Mid-indigo for info states |
| `sun` | `#FBBF24` | Warm amber for decorative emphasis |
| `text-primary` | `#F8FAFC` | Body text, headings |
| `text-secondary` | `#CBD5E1` | Supporting text, descriptions |
| `text-muted` | `#94A3B8` | Placeholders, disabled text, captions |
| `accent` | `#F59E0B` | Link text, accent text |
| `accent-fill` | `#F59E0B` | Button fills, borders, focus rings, decorative |
| `danger` | `#EF4444` | Destructive actions, critical alerts |
| `card-bg` | `#1E293B` | Card fill (apply with opacity — see [Opacity](#opacity)) |
| `card-border` | `#334155` | Card and input borders |
| `positive` | `#34D399` | Success states, gains |
| `negative` | `#FB7185` | Error states, losses |
| `divider` | `#334155` | Horizontal rules, table borders |
| `neutral` | `#E2E8F0` | Neutral indicators, secondary icons |

### Light Theme

| Role | Hex | Description |
|------|-----|-------------|
| `bg-primary` | `#FFFBF7` | Page background (warm ivory) |
| `bg-secondary` | `#FEF7ED` | Elevated surfaces (soft cream) |
| `bg-deep` | `#FFF9F0` | Recessed areas (warm off-white) |
| `night` | `#1E1B4B` | Deep indigo (same as dark) |
| `twilight` | `#6D28D9` | Brighter violet for light backgrounds |
| `sun` | `#F59E0B` | Warm amber (slightly darker than dark theme) |
| `text-primary` | `#1C1917` | Body text, headings |
| `text-secondary` | `#44403C` | Supporting text |
| `text-muted` | `#78716C` | Placeholders, disabled text |
| `accent` | `#D97706` | Link text, accent text (darker for contrast on light bg) |
| `accent-fill` | `#F59E0B` | Button fills, borders, focus rings, decorative |
| `danger` | `#DC2626` | Destructive actions |
| `card-bg` | `#FFFFFF` | Card fill (solid white) |
| `card-border` | `#E7E5E4` | Card and input borders |
| `positive` | `#059669` | Success states |
| `negative` | `#E11D48` | Error states |
| `divider` | `#D6D3D1` | Horizontal rules, table borders |
| `neutral` | `#78716C` | Neutral indicators |

### Choosing a Theme

- **Dark** is the primary theme. Prefer it for apps, dashboards, and screens used in varied lighting.
- **Light** works well for documents, print, and content-heavy reading.
- Respect `prefers-color-scheme` when possible. Offer a manual toggle.

---

## Typography

**Font family:** Inter (available on [Google Fonts](https://fonts.google.com/specimen/Inter)).
**Code font:** JetBrains Mono (available on [Google Fonts](https://fonts.google.com/specimen/JetBrains+Mono)).

### Type Scale

| Name | Size | Weight | Line Height | Letter Spacing | Use |
|------|------|--------|-------------|----------------|-----|
| Display | 48px | 300 (Light) | 1.1 | -0.02em | Hero sections, large numbers |
| H1 | 36px | 600 (Semibold) | 1.2 | -0.01em | Page titles |
| H2 | 30px | 600 | 1.25 | normal | Section headings |
| H3 | 24px | 600 | 1.3 | normal | Subsection headings |
| H4 | 20px | 600 | 1.35 | normal | Card titles, panel headers |
| H5 | 18px | 600 | 1.4 | normal | Minor headings |
| H6 | 16px | 700 (Bold) | 1.4 | normal | Inline headings |
| Body | 16px | 400 (Regular) | 1.6 | normal | Default text |
| Body Small | 14px | 400 | 1.5 | normal | Secondary content, table cells |
| Caption | 12px | 400 | 1.4 | normal | Metadata, timestamps |
| Label | 11px | 600 | 1.25 | 1.2px | Uppercase labels only |
| Code | 14px | 400 | 1.5 | normal | JetBrains Mono |

### Typography Rules

- **Paragraph spacing:** `1em` margin below paragraphs.
- **Max reading width:** `65ch` (~720px) for body text. Don't let lines run wider.
- **Heading spacing:** `1.5em` margin above headings, `0.5em` below.
- **Labels** are always uppercase and use `letter-spacing: 1.2px`. Never use the Label style for mixed-case text.
- **Display** weight is Light (300) — the only place light weight is used. Everything else is Regular (400) or Semibold (600).
- Negative letter-spacing on Display and H1 tightens large text for visual density.

---

## Spacing & Layout

**Base unit:** 4px. All spacing values are multiples of 4.

| Token | Value | Use |
|-------|-------|-----|
| `xs` | 4px | Icon-to-text gaps, tight inline spacing |
| `sm` | 8px | Related elements within a group |
| `md` | 12px | Compact card padding |
| `base` | 16px | Default padding, standard gaps |
| `lg` | 20px | Comfortable card padding |
| `xl` | 24px | Section padding, generous gaps |
| `2xl` | 32px | Between major sections |
| `3xl` | 48px | Page section breaks |
| `4xl` | 64px | Top-level layout divisions |

### Layout Widths

| Context | Max Width |
|---------|-----------|
| Reading content (prose) | 65ch (~720px) |
| App content area | 1200px |
| Wide layout (dashboards) | 1440px |
| Full bleed | no max |

---

## Border Radius

| Token | Value | Use |
|-------|-------|-----|
| `none` | 0 | Hard edges, dividers |
| `sm` | 4px | Inline code, tiny accents |
| `md` | 8px | Buttons, inputs, code blocks, alerts |
| `lg` | 12px | Medium panels, dropdown menus |
| `xl` | 16px | Standard cards, modals, dialogs |
| `2xl` | 24px | Feature cards, hero sections |
| `full` | 9999px | Pills, badges, avatar circles |

---

## Opacity

Used for layering, emphasis, and interactive states. Apply to colour values, not to entire elements (which would also fade text).

| Level | Use |
|-------|-----|
| `0.05` | Table row hover tint |
| `0.10` | Subtle accent wash, secondary button hover |
| `0.15` | Alert and badge backgrounds |
| `0.20` | Overlay backgrounds |
| `0.30` | Soft emphasis, muted fills |
| `0.40` | Dark theme card backgrounds |
| `0.50` | Medium overlays |
| `0.60` | Strong overlays, glow effects |

---

## Shadows

The Sunlight aesthetic prefers **borders and opacity** for depth over box shadows. Shadows are optional and best suited to light theme only.

| Token | Value | Use |
|-------|-------|-----|
| `sm` | `0 1px 2px rgba(0,0,0,0.05)` | Subtle lift |
| `md` | `0 4px 6px rgba(0,0,0,0.07)` | Cards, dropdowns |
| `lg` | `0 10px 15px rgba(0,0,0,0.10)` | Modals, popovers |

In **dark theme**, use `card-border` instead of shadows for element definition.

---

## Components

### Tables

Tables use minimal styling. Borders between rows, no vertical rules.

| Property | Value |
|----------|-------|
| Header background | `bg-secondary` |
| Header text | `text-primary`, semibold |
| Cell padding | `12px` horizontal, `10px` vertical |
| Row border | `1px solid divider` (between rows only) |
| Alternating rows | `bg-secondary` at opacity `0.3` (dark) or `0.5` (light) |
| Row hover | `accent-fill` at opacity `0.05` |
| Table border-radius | `8px` on the outer container |
| Cell text | Body Small (14px regular) |

Wrap the table in a container with `border-radius: 8px` and `overflow: hidden` to round the corners.

### Buttons

All buttons use `14px` semibold text, `8px` border-radius, and `150ms ease` transitions.

| Variant | Background | Text | Border |
|---------|-----------|------|--------|
| **Primary** | `accent-fill` | `bg-primary` | none |
| **Secondary** | transparent | `accent` | `1px solid accent-fill` |
| **Ghost** | transparent | `text-secondary` | none |
| **Danger** | `negative` | white | none |

**Sizes:**

| Size | Padding |
|------|---------|
| Small | `8px 16px` |
| Default | `10px 20px` |
| Large | `14px 28px` |

**States:**
- **Hover:** Primary and Danger darken 10%. Secondary fills with `accent-fill` at `0.10`. Ghost fills with `bg-secondary`.
- **Disabled:** Background `text-muted` at `0.20`, text `text-muted`. No hover change. Use `cursor: not-allowed`.
- **Focus:** See [Accessibility](#accessibility).

### Cards

| Property | Dark | Light |
|----------|------|-------|
| Background | `card-bg` at `0.40` | `card-bg` (solid white) |
| Border | `1px solid card-border` | `1px solid card-border` |
| Radius | `16px` (standard) / `24px` (feature) | same |
| Padding | `16px` (compact) / `24px` (standard) | same |
| Shadow | none | `shadow-sm` (optional) |

Cards should not be nested. If you need hierarchy within a card, use dividers or spacing.

### Form Inputs

Covers text inputs, textareas, and select elements.

| Property | Value |
|----------|-------|
| Background | `bg-secondary` (dark) / `card-bg` (light) |
| Border | `1px solid card-border` |
| Border radius | `8px` |
| Padding | `10px 12px` |
| Text | `text-primary`, Body (16px) |
| Placeholder | `text-muted` |
| Focus border | `2px solid accent-fill` |
| Focus ring | `box-shadow: 0 0 0 3px accent-fill` at `0.20` |

**Labels:** `text-secondary`, 14px semibold, `4px` margin below the label.

**Validation states:**
- Error: replace border with `1px solid negative`. Add error message in `negative` colour below the input, Caption size.
- Success: replace border with `1px solid positive` (use sparingly).

### Links

| State | Style |
|-------|-------|
| Default | `accent` colour, no underline |
| Hover | `accent` colour, underline |
| Visited | `accent` at `0.70` opacity |
| Focus | See [Accessibility](#accessibility) |

Within body text, links should be the only non-`text-primary` colour. Don't combine link colour with bold or other emphasis.

### Code

**Inline code:**

| Property | Value |
|----------|-------|
| Font | JetBrains Mono, 14px |
| Background | `bg-secondary` |
| Padding | `2px 6px` |
| Border radius | `4px` |
| Border | `1px solid card-border` |

**Code blocks:**

| Property | Dark | Light |
|----------|------|-------|
| Background | `bg-deep` | `bg-secondary` |
| Text | `text-primary` | `text-primary` |
| Padding | `16px` | `16px` |
| Border radius | `8px` | `8px` |
| Border | `1px solid card-border` | `1px solid card-border` |
| Overflow | `overflow-x: auto` | `overflow-x: auto` |

Code blocks should use the full Code type style (JetBrains Mono, 14px, line-height 1.5).

### Alerts

Structure: container with `4px` left border, tinted background, text content.

| Type | Border Colour | Background | Text/Icon Colour |
|------|--------------|------------|-----------------|
| **Info** | `twilight` | `twilight` at `0.15` | `twilight` |
| **Success** | `positive` | `positive` at `0.15` | `positive` |
| **Warning** | `accent-fill` | `accent-fill` at `0.15` | `accent` |
| **Error** | `negative` | `negative` at `0.15` | `negative` |

- Padding: `12px 16px`
- Border radius: `8px` (right side and corners only — left side is flush with the border)
- Title: Body Small, semibold, semantic colour
- Body: Body Small, `text-primary`

### Badges

Small status indicators.

| Property | Value |
|----------|-------|
| Padding | `4px 10px` |
| Border radius | `full` (9999px) |
| Font | Caption (12px), semibold |
| Colour scheme | Semantic colour for text, semantic fill colour at `0.15` for background |

### Dividers

- `1px solid divider`
- `16px` margin above and below
- Span the full width of their container

---

## Accessibility

### Focus States

All interactive elements (buttons, inputs, links, custom controls):

- `outline: 2px solid accent-fill`
- `outline-offset: 2px`
- Only visible on `:focus-visible` (keyboard navigation), not on click

### Contrast

The palette is designed with WCAG AA contrast in mind:

- `text-primary` on `bg-primary`: exceeds 4.5:1 in both themes
- `text-secondary` on `bg-primary`: meets 4.5:1
- `text-muted` on `bg-primary`: meets 3:1 (suitable for large text and non-essential info)
- `accent` on `bg-primary`: passes in both themes. In light theme, `accent` is darkened to `#D97706` specifically for text contrast.
- `accent-fill` (`#F59E0B`) is used for non-text elements (fills, borders, focus rings) where text contrast against the page background isn't a concern.

### Reduced Motion

Respect `prefers-reduced-motion`:
- Remove transitions on buttons and hover effects
- Disable glow animations if used

---

## Source

Colour values are sourced from the Sunlight app's theme system:
`lib/core/constants/theme_constants.dart` — the `SunlightColors` ThemeExtension class.