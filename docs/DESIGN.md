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
    backgroundColor: "{colors.surface}"
    textColor: "{colors.on-surface-tertiary}"
    rounded: "{rounded.full}"
    height: 66px
---

## Overview

A soft, friendly, premium fintech look for a mobile app, 390 wide. The app tells a traveler which button to press and shows how much money that keeps. Every screen has one job and one number that is clearly the largest thing on it. The mood is calm and confident: light gray pages, white cards, one bright green, and a single 3D coin as the hero object.

There are four screen templates. Camera screens are dark, with labels placed directly on the object being scanned and a white bottom sheet for the verdict. Success screens are a full green field with the coin, one very large number and one white card. Everyday screens are a gray page with white cards. A dark card is used once per screen for the single most important suggestion.

## Colors

Green means money kept and the action to take. Use `primary` as a fill with `on-primary` text, and `primary-text` when green text sits on white. Red means overpaying: `error` for markers, `error-text` for text, `error-container` for tinted chips. Everything else is gray and white. Never use color alone to carry meaning; pair it with a word.

Gradients are allowed in four places only: the success screen background (a lighter green center), the home hero card (`primary-container` to `primary-container-end`), the glossy icon tiles (light to dark of the same hue, top to bottom), and the coin.

## Typography

Google Sans Flex for English and numbers, Noto Sans Thai for Thai. Other scripts use the device font. Titles and big numbers are weight 800 with tight letter spacing, buttons and labels 700, supporting text 400 to 500. Use tabular figures for every amount. Write amounts as "1,000 THB". Thai text needs line height 1.45 or more so tone marks are not clipped.

Copy is English, short, friendly and in sentence case. No exclamation marks. Say the result first, the reason second.

## Layout

Screen margin 16. Cards stack vertically with 12 between them. Content is left-aligned; only success screens are centered. The primary button is pinned to the bottom, full width or two thirds beside a secondary button. Leave space at the top for the system status bar but do not draw one. Minimum touch target 48.

## Elevation & Depth

Depth comes from the gray page against white cards, not from shadows. Cards have no border and no shadow. Soft shadows are used only under the floating tab bar, under the coin, and as a faint colored glow under glossy icon tiles. Glass (translucent blur) is used only for the floating tab bar and for controls on camera screens.

## Shapes

Bottom sheets 28, hero and dark cards 24, cards 20, buttons 16, small tiles 12 to 14, chips and the tab bar fully round. No other radii.

## Components

- Primary button: dark fill, white label, 56 high.
- Secondary button: light gray fill, dark label.
- Card: white, one topic per card, never a card inside a card.
- Hero card: soft green gradient with a label, one large number, a white chip and the coin on the right.
- Dark card: the one suggestion to act on, with a small green label above large white text.
- Icon tile: glossy rounded square, 44, white line glyph, in blue, orange, green or yellow.
- Price scale: a light gray track with a green segment for the usual range and a red round marker for the asked price.
- Tab bar: floating glass pill with five tabs (Home, Scan, Speak, Assistant, Records); the selected tab sits in a darker pill.
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
