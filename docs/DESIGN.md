---
version: alpha
name: Money Navigation
description: A travel money assistant that stops visitors to Thailand from losing money at ATMs, card terminals, exchange booths and street prices.
colors:
  primary: "#19D873"
  on-primary: "#04220F"
  primary-text: "#00A85A"
  primary-on-dark: "#19E07A"
  primary-container: "#D9FBE8"
  primary-container-end: "#BFF3D6"
  on-primary-container: "#1B5E3A"
  background: "#F2F4F6"
  surface: "#FFFFFF"
  surface-dim: "#E5E8EB"
  surface-sunken: "#F9FAFB"
  divider: "#E5E8EB"
  handle: "#D1D6DB"
  glass-fill: "#FFFFFFB8"
  shadow: "#111418"
  surface-dark: "#111418"
  on-surface: "#111418"
  on-surface-secondary: "#4E5968"
  on-surface-tertiary: "#6B7684"
  on-surface-muted: "#8B95A1"
  on-surface-dark: "#FFFFFF"
  error: "#FF3B5C"
  error-text: "#D1173A"
  error-container: "#FFE9EC"
  icon-blue: "#2463F0"
  icon-blue-light: "#5B9BFF"
  icon-orange: "#FF6A1A"
  icon-orange-light: "#FFA45C"
  icon-green: "#0CB55C"
  icon-green-light: "#4BE08F"
  icon-yellow: "#FFAE00"
  icon-yellow-light: "#FFD66B"
typography:
  display-xl:
    fontFamily: Google Sans Flex
    fontSize: 96px
    fontWeight: 800
    lineHeight: 1
    letterSpacing: -4px
  display-lg:
    fontFamily: Google Sans Flex
    fontSize: 46px
    fontWeight: 800
    lineHeight: 1.1
    letterSpacing: -1.5px
  headline:
    fontFamily: Google Sans Flex
    fontSize: 34px
    fontWeight: 800
    lineHeight: 1.25
    letterSpacing: -1px
  title:
    fontFamily: Google Sans Flex
    fontSize: 24px
    fontWeight: 800
    lineHeight: 1.25
    letterSpacing: -0.5px
  body-lg:
    fontFamily: Google Sans Flex
    fontSize: 16px
    fontWeight: 700
    lineHeight: 1.4
  body-md:
    fontFamily: Google Sans Flex
    fontSize: 15px
    fontWeight: 400
    lineHeight: 1.5
  label:
    fontFamily: Google Sans Flex
    fontSize: 14px
    fontWeight: 700
    lineHeight: 1.4
  caption:
    fontFamily: Google Sans Flex
    fontSize: 13px
    fontWeight: 500
    lineHeight: 1.4
  thai-body:
    fontFamily: Noto Sans Thai
    fontSize: 15px
    fontWeight: 400
    lineHeight: 1.6
  thai-display:
    fontFamily: Noto Sans Thai
    fontSize: 28px
    fontWeight: 700
    lineHeight: 1.45
rounded:
  sm: 12px
  md: 16px
  lg: 20px
  xl: 24px
  sheet: 28px
  full: 9999px
spacing:
  xs: 4px
  sm: 8px
  md: 12px
  lg: 16px
  xl: 20px
  xxl: 24px
  screen-margin: 16px
components:
  button-primary:
    backgroundColor: "{colors.surface-dark}"
    textColor: "{colors.on-surface-dark}"
    typography: "{typography.body-lg}"
    rounded: "{rounded.md}"
    height: 56px
  button-secondary:
    backgroundColor: "{colors.surface-dim}"
    textColor: "{colors.on-surface}"
    typography: "{typography.body-lg}"
    rounded: "{rounded.md}"
    height: 56px
  card:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.on-surface}"
    rounded: "{rounded.lg}"
    padding: 20px
  hero-card:
    backgroundColor: "{colors.primary-container}"
    textColor: "{colors.on-surface}"
    rounded: "{rounded.xl}"
    padding: 22px
  dark-card:
    backgroundColor: "{colors.surface-dark}"
    textColor: "{colors.on-surface-dark}"
    rounded: "{rounded.xl}"
    padding: 20px
  bottom-sheet:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.on-surface}"
    rounded: "{rounded.sheet}"
    padding: 28px
  chip:
    backgroundColor: "{colors.surface}"
    textColor: "{colors.on-primary-container}"
    typography: "{typography.caption}"
    rounded: "{rounded.full}"
    padding: 6px
  chip-error:
    backgroundColor: "{colors.error-container}"
    textColor: "{colors.error-text}"
    typography: "{typography.label}"
    rounded: "{rounded.full}"
    padding: 6px
  icon-tile:
    backgroundColor: "{colors.icon-blue}"
    textColor: "{colors.on-surface-dark}"
    rounded: "{rounded.sm}"
    size: 44px
  tab-bar:
    backgroundColor: "{colors.glass-fill}"
    textColor: "{colors.on-surface-tertiary}"
    rounded: "{rounded.full}"
    height: 64px
---

## Overview

A soft, friendly, premium fintech look for a mobile app, 390 wide. The app tells a traveler which button to press and shows how much money that keeps. Every screen has one job and one number that is clearly the largest thing on it. The mood is calm and confident: light gray pages, white cards, one bright green, and a single 3D coin as the hero object.

There are four screen templates. Camera screens are dark, with labels placed directly on the object being scanned and a white bottom sheet for the verdict. Success screens are a full green field with the coin, one very large number and one white card. Everyday screens are a gray page with white cards. A dark card is used once per screen for the single most important suggestion.

## Colors

Green means money kept and the action to take. Use `primary` as a fill with `on-primary` text, and `primary-text` when green text sits on white. Red means overpaying: `error` for markers, `error-text` for text, `error-container` for tinted chips. Everything else is gray and white. Never use color alone to carry meaning; pair it with a word.

Gradients are allowed in five places only: the success screen background (a lighter green center), the home hero card (`primary-container` to `primary-container-end`), the glossy icon tiles (light to dark of the same hue, top to bottom), the coin, and the camera scrim (top of camera screens only, `shadow` from 45 % to 0 % over 120, so the status bar stays legible over a bright preview).

## Typography

Google Sans Flex for English and numbers, Noto Sans Thai for Thai. Other scripts use the device font. Titles and big numbers are weight 800 with tight letter spacing, buttons and labels 700, supporting text 400 to 500. Use tabular figures for every amount. Write amounts as "1,000 THB". Thai text needs line height 1.45 or more so tone marks are not clipped.

Copy is English, short, friendly and in sentence case. No exclamation marks. Say the result first, the reason second.

## Layout

Screen margin 16. Every screen has three zones in this order: hero zone, content zone, action zone. Gaps are never shared between levels: 32 between zones, 12 between groups inside a zone, 0 between rows inside a group (rows are divided by a hairline). Every list of two or more rows sits in one group card under a section header. Content is left-aligned; only success screens are centered. The primary button is pinned to the bottom, full width or two thirds beside a secondary button. Leave space at the top for the system status bar but do not draw one. Minimum touch target 48.

## Elevation & Depth

Depth comes from surface levels, plus exactly two shadow tokens.

| Level | Color | Use |
| --- | --- | --- |
| L0 page | background #F2F4F6 | Every everyday screen. |
| L1 group | surface #FFFFFF, radius 20 | Every set of rows. Flat, no border, no shadow. |
| L1 well | surface-sunken #F9FAFB, radius 12 | Only a numeric breakdown inside a group. Replaces cards in cards. |
| L2 floating | surface or glass | Tab bar, sticky action dock, bottom sheet. |
| Emphasis | surface-dark #111418 | The one dark card per screen. |

Shadow color is `shadow` #111418.
- E1, hero card and dark card only: (0,1) blur 2 at 4 %, plus (0,4) blur 12 at 5 %.
- E2, floating chrome only (tab bar, dock, sheet; sheets use y -8): (0,2) blur 6 at 6 %, plus (0,10) blur 30 at 12 %.

Rows inside a group are divided by a 0.5 `divider` hairline that starts at the text start (inset 20, or 72 with a 40 icon) and runs to the card edge; never above the first or below the last row. Glass (translucent blur) is used only for the floating tab bar, the sticky action dock and controls on camera screens.

Section header: outside the group, 15/700 on-surface, sentence case, 28 above, 10 below, inset 4 from the card edge; optional trailing link 14/600 on-surface-tertiary. Group card: padding 20 horizontal, 8 vertical. Row: min height 56, 14 vertical padding, title 16/600, subtitle 13/500 on-surface-tertiary, amount right-aligned in tabular figures. Footer (source and date): 12/500 on-surface-tertiary (on-surface-muted fails WCAG AA on the page), 8 below the group.

Hero zone sits directly on the page, no card: label 15/500 on-surface-secondary, the number in display weight 800, at most one chip, then 32 of space.

## Shapes

Bottom sheets 28, hero and dark cards 24, cards 20, buttons 16, small tiles 12 to 14, chips and the tab bar fully round. No other radii.

## Components

- Primary button: dark fill, white label, 56 high.
- Secondary button: light gray fill, dark label.
- Group card: white, one group per card holding one or more rows, never a card inside a card.
- Hero card: soft green gradient with a label, one large number, a white chip and the coin on the right.
- Dark card: the one suggestion to act on, with a small green label above large white text.
- Icon tile: glossy rounded square, 44, white line glyph, in blue, orange, green or yellow.
- Price scale: a light gray track with a green segment for the usual range and a red round marker for the asked price.
- Tab bar: floating glass pill, 16 from the side edges and 8 above the bottom safe area, height 64, radius 32, glass-fill over blur sigma 24, 0.5 border of shadow at 6 %, E2. Five equal tabs (Home, Scan, Speak, Assistant, Records); icons 24, outline when inactive and filled when active; labels 11/600; inactive on-surface-tertiary, active on-surface. The active tab sits on a 56-tall pill of shadow at 7 % that slides between tabs (motion standard, enter curve), never green. Selection click haptic on change. Content scrolls under it with bottom padding 64 + safe area + 24. Hidden in full-screen flows (camera, verdict, success).
- Action dock: a pinned primary button sits in a dock of background at 90 % over blur sigma 20 with a 0.5 divider hairline on top. Never stacked above a tab bar.
- Camera screen: controls are dark glass (`shadow` at 40 %, white hairline at 20 %, blur 20). With no camera available, a white "Choose photo" pill takes the shutter's place (the one inverted primary button, on black only). Shutter inner disc sinks to 0.86 while pressed.
- Motion tokens added during craft: `settle` (easeOutBack) for landing badges and the hero number, `boxStagger` 0.12 between detection boxes, `heroSettleFrom` 0.96. The hero number counts up to the real verdict value; with reduce motion it shows the final value at once.
- Bottom sheet: radius 28, E2 with y -8, 36 x 4 grabber in `handle`, overlapping a full-bleed camera.
- Coin: a 3D Thai-style bimetal coin, silver outer ring and gold center with the baht sign. At most one hero object per screen.

## Do's and Don'ts

- Do keep one number per screen clearly the largest.
- Do show the source and date under any figure that comes from outside the app.
- Do mark estimates with "about".
- Don't use purple gradients, neon glow or heavy shadows.
- Don't nest cards or wrap every line in its own card.
- Don't use emoji, stock illustrations, or real bank and brand logos.
- Don't draw a fake status bar.
- Don't center layouts except on success screens.
