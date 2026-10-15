# Depth, tactility and polish — research for the design pass (15 Oct 2026)

The owner wants every card and the whole UI to feel three-dimensional and premium, with impressive small-detail effects. This file is the researcher's evidence and the proposed spec. Part 1 covers finance, travel, Apple, Google and Duolingo. Part 2 (wider app types) is appended when it arrives.

## Part 1 — evidence

- Corners: Flutter 3.32+ has `RoundedSuperellipseBorder`, `ClipRSuperellipse`, `Canvas.drawRSuperellipse`, `Path.addRSuperellipse`. Only iOS and Android render it; elsewhere it falls back to a rounded rectangle. https://flutter.dev/blog/whats-new-in-flutter-3-32 (2025-05-20), https://api.flutter.dev/flutter/painting/RoundedSuperellipseBorder-class.html. Impeller is default on Android API 29+ (https://docs.flutter.dev/perf/impeller, 2026-05-05).
- Apple WWDC25 "Get to know the new design system" (https://developer.apple.com/videos/play/wwdc2025/356/): shapes are fixed, capsule (radius = height / 2) or concentric (inner radius = parent radius − padding). Liquid Glass is for controls and bars floating above content, not for content.
- Shadows: several layers, one light source above; higher elements get larger offset and blur but lower opacity; tint shadows with the hue beneath (black on color desaturates it, a saturated tint reads as glow). https://www.joshwcomeau.com/css/designing-shadows (2026-04-27).
- Toss motion article (https://toss.im/tossfeed/article/why-motion-in-finance, 2022-07-14): motion explains, 3D is sparing and cheap. No official TDS shadow values found.
- Springs: Apple WWDC23 "Animate with springs" (https://developer.apple.com/videos/play/wwdc2023/10158/): duration + bounce (e.g. 0.5 s / 0.15). Flutter `SpringDescription.withDurationAndBounce` maps 1:1. Material 3 Expressive: spatial springs may overshoot for hero moments; effects springs (alpha, color) never overshoot.
- Haptics: Flutter `HapticFeedback` has `successNotification`, `warningNotification`, `errorNotification`, `selectionClick`, `light/medium/heavyImpact` (https://api.flutter.dev/flutter/services/HapticFeedback-class.html). Samsung mapping unverified.
- Numbers: Robinhood Ticker odometer (https://github.com/robinhood/ticker). Build our own (~80 lines) for tabular figures and spring timing; no package needed.
- Duolingo 3D button (4 px darker bottom edge collapsing on press) is too playful for money decisions.

## Part 1 — top 10 changes, ranked

1. Superellipse corners on every shape; concentric rule for nested shapes.
2. Verdict Press card on the green field becomes a raised object: three-layer green-tinted shadow, lands with a settle spring (from y +16, scale 0.98).
3. Primary dark button: vertical gradient, top inner highlight, E1, press 0.97 with spring release, `lightImpact`.
4. Floating tab bar: specular rim (gradient stroke, brighter on top), three-layer E2, active pill slides on a spring.
5. Coin grounding: soft elliptical green-tinted contact shadow; one 600 ms settle (scale 0.92 → 1, bounce 0.2).
6. Hero number odometer roll (40 ms stagger per digit, lands about 700 ms), `successNotification` on landing; haggling "High" uses `warningNotification`.
7. Group cards lift slightly off the gray page (E0), still nearly flat.
8. Camera controls as dark glass with a top rim highlight; shutter ring subtle gradient and press sink; `selectionClick` when detection boxes lock on.
9. Bottom sheet rises on a spring (450 ms, bounce 0.08), upward E2, grabber.
10. Icon tiles: same-hue gradient, 1 px white top highlight at 30 %, hue-tinted contact shadow. Price-scale marker: white-ringed knob with E1.

## Part 1 — tokens

Shadow colors: `shadow` #111418 on page and white; new `shadow-green` #0B4F2A on the green field.

| Token | Use | Layers ((x,y), blur, spread, alpha) |
| --- | --- | --- |
| E0 | Group card on page | (0,1) 2, 0, 4 % |
| E1 | Hero card, dark card, primary button, tiles | (0,1) 2, 0, 6 %; (0,4) 10, 0, 6 %; (0,12) 24, −6, 8 % |
| E1-green | Press card on green | E1 geometry with `shadow-green` at 10 / 10 / 14 % |
| E2 | Tab bar, dock, sheet (sheet: negative y) | (0,1) 2, 0, 6 %; (0,8) 24, 0, 8 %; (0,24) 48, −12, 10 % |
| E-pressed | Any pressed raised element | keep only the first layer; others animate to 0 in 100 ms |

- Radii unchanged (28 / 24 / 20 / 16 / 12 / full), rendered as superellipse; nested inner radius = outer − inset, minimum 8.
- Highlights: dark surfaces 1 px inner top stroke white 10 % → 0 % over the top 40 %; glass rim 0.5 px white 70 % top → 20 % bottom; tiles 1 px white 30 % top.
- Gradients: dark button and dark card #1E2228 → #111418; green fill #2EE383 → #14CC6A; top-to-bottom lightness difference at most about 6 %.
- Press: scale 0.97 (buttons, cards), 0.86 (shutter disc); in 90 ms easeOut; release spring 300 ms bounce 0.2.
- Springs: `snappy` 350 ms / 0 (UI moves, tab pill); `settle` 550 ms / 0.18 (hero landings); `sheet` 450 ms / 0.08; `effects` 200 ms / 0 (opacity, color).
- Reduce motion: no roll, no settle, no scale beyond 0.98; keep haptics.

## Part 1 — Flutter notes

- `DecoratedBox(decoration: ShapeDecoration(shape: RoundedSuperellipseBorder(...), color/gradient, shadows: ...))`; `ClipRSuperellipse` for clipped content (photos, glass).
- Inner highlight: `foregroundDecoration` / `CustomPainter` stroking `Path()..addRSuperellipse(...)` with a `LinearGradient` shader (BorderSide cannot take a gradient).
- `Pressable`: one AnimationController driven by `SpringSimulation` so a mid-press release keeps velocity; `Transform.scale` plus `BoxShadow.lerpList`; haptic on confirmed tap.
- Odometer: per digit a `ClipRect` around a 0–9 column animated with a spring; tabular figures.
- `Hero` for the coin (home hero → success) and the scan thumbnail (camera → verdict), keeping the superellipse in `flightShuttleBuilder`.
- Glass: `BackdropFilter` inside `ClipRSuperellipse`, blur sigma ≤ 24 on the Fold8.

## Part 1 — rule changes

- DESIGN.md: replace "exactly two shadow tokens" with E0 / E1 / E1-green / E2 / E-pressed; "shadows are tinted with the surface beneath, never pure black on color"; group cards E0; all radii superellipse with the concentric rule; add the dark button / card and tile gradients (≤ 6 % lightness difference); add the spring table and haptics map (tab → selectionClick, primary press → lightImpact, verdict saved → successNotification, High → warningNotification, errors → errorNotification).
- no-ai-look.md: glow is banned (zero-offset colored blur, saturated tint, alpha > 15 %); low-alpha, hue-tinted, downward layered shadows are required. New tells: one identical heavy shadow on everything; neumorphism; bouncy springs on non-hero elements; chunky Duolingo buttons in money flows; mixed corner types.

## Not verified

Official Toss TDS values; official Material 3 spring numbers; Apple's `.snappy`/`.bouncy` defaults; Samsung haptic mapping; superellipse + shadow performance on the Fold8; current Revolut, Cash App, Grab, Airbnb card specs.

## Owner direction (15 Oct, after both research parts)

Hyunjun: "It is a money app, but it does not need to be too calm. Travelers use it and it is not a banking app, so standing out a bit is fine." So lean expressive and delightful, not banking-calm. Still keep trust: no pressure or gambling patterns (spin wheels, countdowns, confetti storms, Tinder fly-off on money), no neon glow, no clay 3D emoji competing with the coin.

## Part 2 — wider app types (community, dating, SNS, shopping, beauty, health, delivery, media)

Sources are weaker here (few teams publish specs); numbers below are proposals built from observed patterns.

- Dating (Tinder/Hinge): stacked cards scaled and offset behind the top card; springs start at the release velocity. Hinge gets depth from content, not chrome.
- SNS (Instagram): shared-element expand from thumbnail to detail, interactive drag to dismiss; about 400 ms full-page transitions; like heart pops to about 1.2 with a spring.
- Community (Karrot SEED, open source): press feedback motion is a design token. https://designcompass.org/2026/07/27/daangn-seed-design-system-rebranding/
- Shopping (Nike SNKRS, Apple Store, Musinsa, Coupang): cut-out products on soft contact shadows; add-to-bag item flies on an arc and the bag icon bumps.
- Health (Oura, Whoop, Calm): rings and one huge number at a glance; Calm/Headspace slow gradient light fields with breathing-paced motion.
- Media (Spotify aura): animated lava-lamp gradient whose colors map to data. https://engineering.atspotify.com/2021/12/the-audio-aura-story-mystical-to-mathematical
- Motion basis (WWDC18 Designing Fluid Interfaces): interruptible springs that start at gesture velocity; haptics mark outcomes, not every tap.

### Techniques to use (Flutter values -> where), leaning expressive per the owner

1. E1-card on white groups: #111418 3 % (0,1) blur 3 + #111418 5 % (0,6) blur 20 spread -4. Records, verdict sheet, home.
2. Hue-tinted shadow on green: #0A4D2C 14 % (0,16) blur 40 spread -8 + 10 % (0,2) blur 6. Press card on the success screen.
3. Superellipse corners everywhere (see Part 1).
4. Edge light: dark card gradient #1E232A -> #111418 with a 0.5 px white 10 % top line; glass tab bar `ImageFilter.compose(outer: ColorFilter.matrix(saturation 1.6), inner: blur 24)` with a white 55 % top hairline.
5. Press depth: scale 0.97 cards / 0.96 buttons in 90 ms easeOut; shadow tightens (y 6 -> 2, blur 20 -> 8); release spring stiffness 420, damping ratio 0.82; lightImpact on commit.
6. Living coin: idle float ±3 px on a 3.2 s sine; tilt on touch (`Matrix4..setEntry(3,2,0.0012)`, max ±8°, spring back ratio 0.7); contact shadow ellipse (0.7 × coin width, 10 high, black 20 % blur 10 + 8 % blur 28) scaling inversely with the float; landing settle then haptic.
7. Aura light field on the success screen: three radial gradients (#5BE89A, #19D873, #12C366) drifting ±6 % width over 14 s easeInOutSine; static with reduce motion.
8. Fly-to-total on "Save to trip": a 28 px coin copy follows a quadratic Bézier arc to the home total (or Records tab) in 550 ms easeInOutCubic, scaling 1 -> 0.4; target bumps 1 -> 1.10 -> 1 (spring ratio 0.6) with selectionClick.
9. Odometer digits: per digit slide 0.6 em with fade, 480 ms easeOutCubic, 30 ms stagger from the rightmost digit, tabular figures. Home total and haggling price.
10. Animated price scale: green range grows from its center in 420 ms; red marker slides in over 650 ms, overshoots 4 px and settles; 1 px white ring + #111418 18 % (0,2) blur 6 shadow; selection haptic when it crosses into red.
11. Peeking card stack on haggling: counter-offer card on top, up to two cards behind (seller phrase, translation) at scale 0.95 / 0.90, y +10 / +20, opacity 1 / 0.7; a new phrase enters as the top card with a spring (ratio 0.86, stiffness 380); no swipe-to-dismiss.
12. Sheets with real physics (stiffness 500, ratio 0.86, start at release velocity, overscroll ×0.55); skeletons shaped like the final rows (#E5E8EB with a white 35 % band every 1.2 s) only for real waits; the scan keeps its real steps.
13. (Owner direction) A restrained success moment: when money is kept, 5–7 small coins pop up from behind the hero coin and fall back with gravity in under 900 ms, once, with successNotification. Never on every screen; never on errors or warnings.
14. (Owner direction) Brighter accents: glossy icon tiles (same-hue gradient, white 30 % top line, hue-tinted contact shadow) used on home and records rows; verdict chips with stronger fills.

### Avoid

Temu-style confetti storms, spin wheels and countdowns; clay 3D emoji icons; Wrapped-style saturated duotones and gradient text; Tinder rotation and fly-off on money items; colored glows or neon; gyroscope parallax; bouncy springs on every element.
