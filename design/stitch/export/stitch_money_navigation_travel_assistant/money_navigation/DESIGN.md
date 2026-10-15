---
name: Money Navigation
colors:
  surface: '#f8f9ff'
  surface-dim: '#d8dadf'
  surface-bright: '#f8f9ff'
  surface-container-lowest: '#ffffff'
  surface-container-low: '#f2f3f9'
  surface-container: '#eceef3'
  surface-container-high: '#e6e8ee'
  surface-container-highest: '#e1e2e8'
  on-surface: '#191c20'
  on-surface-variant: '#3c4a3e'
  inverse-surface: '#2e3135'
  inverse-on-surface: '#eff0f6'
  outline: '#6c7b6d'
  outline-variant: '#bbcbba'
  surface-tint: '#006d36'
  primary: '#006d36'
  on-primary: '#ffffff'
  primary-container: '#19d873'
  on-primary-container: '#00582a'
  inverse-primary: '#2fe27c'
  secondary: '#006d38'
  on-secondary: '#ffffff'
  secondary-container: '#74f9a1'
  on-secondary-container: '#00723b'
  tertiary: '#be0037'
  on-tertiary: '#ffffff'
  tertiary-container: '#ffa4a9'
  on-tertiary-container: '#9b002b'
  error: '#ba1a1a'
  on-error: '#ffffff'
  error-container: '#ffdad6'
  on-error-container: '#93000a'
  primary-fixed: '#61ff98'
  primary-fixed-dim: '#2fe27c'
  on-primary-fixed: '#00210c'
  on-primary-fixed-variant: '#005227'
  secondary-fixed: '#77fca4'
  secondary-fixed-dim: '#59df8a'
  on-secondary-fixed: '#00210d'
  on-secondary-fixed-variant: '#005229'
  tertiary-fixed: '#ffdada'
  tertiary-fixed-dim: '#ffb3b6'
  on-tertiary-fixed: '#40000c'
  on-tertiary-fixed-variant: '#920028'
  background: '#f8f9ff'
  on-background: '#191c20'
  surface-variant: '#e1e2e8'
typography:
  display-currency:
    fontFamily: Plus Jakarta Sans
    fontSize: 40px
    fontWeight: '700'
    lineHeight: 44px
    letterSpacing: -0.03em
  display-currency-mobile:
    fontFamily: Plus Jakarta Sans
    fontSize: 34px
    fontWeight: '700'
    lineHeight: 38px
    letterSpacing: -0.03em
  headline-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 26px
    fontWeight: '700'
    lineHeight: 32px
    letterSpacing: -0.02em
  headline-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 20px
    fontWeight: '600'
    lineHeight: 26px
    letterSpacing: -0.015em
  headline-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 17px
    fontWeight: '600'
    lineHeight: 22px
    letterSpacing: -0.01em
  body-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 16px
    fontWeight: '400'
    lineHeight: 24px
    letterSpacing: -0.005em
  body-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 14px
    fontWeight: '400'
    lineHeight: 20px
    letterSpacing: 0em
  body-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 13px
    fontWeight: '400'
    lineHeight: 18px
    letterSpacing: 0em
  label-lg:
    fontFamily: Plus Jakarta Sans
    fontSize: 15px
    fontWeight: '600'
    lineHeight: 20px
    letterSpacing: -0.005em
  label-md:
    fontFamily: Plus Jakarta Sans
    fontSize: 13px
    fontWeight: '600'
    lineHeight: 18px
    letterSpacing: 0em
  label-sm:
    fontFamily: Plus Jakarta Sans
    fontSize: 11px
    fontWeight: '500'
    lineHeight: 14px
    letterSpacing: 0.01em
rounded:
  sm: 0.25rem
  DEFAULT: 0.5rem
  md: 0.75rem
  lg: 1rem
  xl: 1.5rem
  full: 9999px
spacing:
  gutter: 1rem
  margin: 1.25rem
  space-xs: 0.25rem
  space-sm: 0.5rem
  space-md: 0.75rem
  space-lg: 1rem
  space-xl: 1.5rem
---

## Brand & Style
The design system operates at the intersection of directional navigation and high-caliber financial technology. The ethos is frictionless orientation: the interface provides turn-by-turn clarity for financial decisions abroad. The emotional objective is instantaneous relief, absolute clarity, and understated prestige, on par with Toss, Apple Wallet, and Wise.

Visually, the system is grounded in structural minimalism with tactical navigation motifs. Surfaces are calm and matte. Physical navigation metaphors (smooth unbroken transit lines, solid circular waypoints, clear direction arrows) are reinterpreted as financial signposts: which card to tap, which currency bucket to draw from, and how to dodge dynamic currency conversion traps.

### Style Directives
- **Zero Decorative Noise:** Strictly no gradients, no frosted glow, no decorative card stripes, and no arbitrary stacked gray pills.
- **Dignified AI:** No novelty sparkle icons or chatty interfaces. Intelligence is expressed entirely through precise numeric calculations, real-time FX route recommendations, and calm, confident suggestions.
- **Wayfinding Identity:** A signature 2px solid navigational path connects multi-step payment logic, foreign exchange routing, and transaction origin points.

## Colors
The palette is hyper-disciplined, relying on an architectural canvas of cool off-whites, neutral grays, deep obsidian text, and an electric navigation green.

### Palette Tokens & Application
- **Canvas (`#F2F4F6`):** The default screen background. Cool, grounded, anti-glare light gray that allows pure white cards to float cleanly.
- **Surface Elevation (`#FFFFFF`):** High-clarity foreground panels, cards, and bottom sheets.
- **Primary Accent (`#19D873`):** Vibrant route line, active transit pings, verified payment status rings, and directional vectors. Reserved strictly for graphical wayfinding and primary interactive fills.
- **Accessible Text Accent (`#00A85A`):** Used whenever directional accenting requires text legibility against `#FFFFFF` or `#F2F4F6` (e.g., positive delta spreads, currency savings, tap-ready confirmations) meeting WCAG AA contrast standards.
- **Alert / Warning (`#FF3B5C`):** High-friction markers, bad FX conversion warnings, predatory ATM fee flags, and transaction errors.
- **Text Primary (`#111418`):** Dominant ink. Heavy numbers, titles, and terminal balances.
- **Text Secondary (`#4E5968`):** Contextual explanations, merchant locations, and secondary currency indicators.
- **Text Tertiary (`#8B95A1`):** Metadata, timestamps, inactive states, and structural hairline guides.
- **Hairline Border (`#E5E8EB`):** Subtle, crisp 1px borders used on cards and dividers.

## Typography
Typography creates hierarchy entirely through scale, weight, and negative space rather than color variety or uppercase styling.

### Typographic Rules
- **Sentence Case Only:** Never apply all-caps styling to labels, buttons, or navigation bars. Dignified intelligence is quiet and confident.
- **Numbers are the Interface:** Currency amounts, exchange calculations, and fee deltas take dominant optical priority via tight negative letter spacing (`-0.03em`) and tabular numeric styling.
- **Vertical Alignment:** Pair `display-currency` with baseline-anchored ISO currency codes styled in `label-md` using Tertiary Text (`#8B95A1`).

## Layout & Spacing
The layout is optimized for high-density, single-handed portrait usage on mobile hardware (standard target: 466 x 737 pt).

### Grid & Structure
- **Columns:** 4-column fluid mobile grid anchored within a strict 20px (`1.25rem`) side margin.
- **Canvas Constraints:** Maximum layout width locked to 466pt. On wider viewports, the canvas remains centered with outer margins bleeding into `#E5E8EB`.
- **Rhythm & Stacking:** Surfaces and independent modules are spaced by `space-md` (12px) or `space-lg` (16px). Major semantic sections (e.g., Active Payment Route vs. Currency Reservoirs) use `space-xl` (24px).
- **Safe Area Insets:** A 44pt safe padding is enforced at the top status bar; bottom action anchors preserve a minimum 34pt clearance above home indicator zones.

## Elevation & Depth
Elevation is tactile yet razor-thin, avoiding heavy drops or glowing blooms. Surfaces sit close to each other, maintaining an editorial, paper-and-glass crispness.

### Level Guidelines
- **Level 0 (Canvas):** `#F2F4F6`. Zero shadow, flat structural underlay.
- **Level 1 (Cards & Standard Panels):** `#FFFFFF`. Defined by a compound border-and-shadow treatment: a 1px solid border in `#E5E8EB` paired with an ultra-diffused ambient shadow: `box-shadow: 0 2px 8px rgba(17, 20, 24, 0.04)`.
- **Level 2 (Floating Guidance Sheets & Navigation Overlays):** `#FFFFFF`. Elevated above canvas operations: `box-shadow: 0 8px 24px rgba(17, 20, 24, 0.08)`, edged with a 1px `#E5E8EB` border.
- **Level 3 (Modal Alerts & Bottom Action Trays):** Direct contrast: `box-shadow: 0 16px 36px rgba(17, 20, 24, 0.12)`.

## Shapes
Geometry is disciplined and fluid, balancing accessibility with high-end device corner continuity.

### Shape Scale
- **Base Components (`rounded`, 8px):** Input fields, inline badges, status waypoints, small notification banners.
- **Containers & Cards (`rounded-lg`, 16px):** Standard card containers, transaction summary blocks, route step cards.
- **Floating Overlays & Trays (`rounded-xl`, 24px):** Top-level bottom sheets, active turn-by-turn instruction surfaces.
- **Pill Geometry (Full Radius):** Primary interactive CTAs, step navigation indicator pills, quick currency toggle selectors.

## Components

### 1. The Route Path & Waypoints (Signature Component)
- **Line Structure:** Continuous 2px solid `#19D873` stroke running vertically or horizontally to link multi-step logic (e.g., Local Card Account → FX Mid-Market Engine → Final Merchant Settlement).
- **Waypoints:** 10px circular nodes with an 8px solid white interior surrounded by a 2px stroke of `#19D873`. Intermediate non-active stops use `#8B95A1`.
- **Warning Branching:** If a route triggers a dynamic conversion fee, the path splits: optimal route stays `#19D873`, bad route breaks into a 2px dashed `#FF3B5C` segment.

### 2. Buttons & CTAs
- **Primary Route CTA:** Height 52px, full pill radius (`9999px`). Background `#111418`, text `#FFFFFF`, font `label-lg`. Tap feedback is a direct opacity drop to 0.88 without elevation change.
- **Secondary Guidance Action:** Height 48px, full pill radius. Background `#FFFFFF`, 1px border in `#E5E8EB`, text `#111418`.
- **Destructive / Alert Action:** Background `#FFFFFF`, 1px border in `#FF3B5C`, text `#FF3B5C`.

### 3. Payment Instruction Cards
- **Structure:** Pure white `#FFFFFF` surface, `rounded-lg` (16px), 1px border in `#E5E8EB`.
- **Interior Layout:** Contains the directional header ("Pay in JPY, not USD"), the real-time calculation breakdown in `display-currency`, and an instruction footer with zero decorative icons—pure typography and unambiguous contrast.

### 4. Input Fields
- **Container:** Height 56px, `rounded` (8px), background `#FFFFFF`, border 1px solid `#E5E8EB`.
- **Active State:** Border shifts cleanly to 1.5px solid `#111418` (never green, preserving green strictly for navigational correctness).
- **Typography:** Value input in `headline-md` (`#111418`), placeholder in `body-md` (`#8B95A1`).

### 5. Lists & Rows
- **Layout:** Edge-to-edge within cards; rows separated by a 1px horizontal hairline in `#F2F4F6` inset by 16px.
- **Data Pairs:** Label on the left in `body-md` (`#4E5968`); numeric value on the right in `label-md` (`#111418`), aligned to tabular baseline.

### 6. Status Chips & Waypoint Badges
- **Friction-Free (Optimal):** Background `#F2F4F6`, border 1px solid `#E5E8EB`, text `#00A85A` in `label-sm`.
- **Friction Alert (Surcharge/Risk):** Background `#FFF1F3`, border 1px solid `#FFD4DC`, text `#FF3B5C` in `label-sm`.