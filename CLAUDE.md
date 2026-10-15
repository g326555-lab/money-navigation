# Money Navigation - AI travel assistant

Working rules for this folder. Read this first in every session, then read everything in `docs/`.

## Start of every session

1. Run `date` and work out which phase we are in (see "Schedule and phases").
2. Read `docs/overview.md`, `docs/DESIGN.md`, `docs/prep-notes.md` (verified fixes and findings from preparation) and, if present, `docs/spec.md`.
3. Tell Hyunjun in two or three Korean sentences what phase it is and what you are about to do, then start.

## This folder

```
codex/
  CLAUDE.md      these rules (loaded automatically)
  docs/          overview.md, DESIGN.md, prep-notes.md, spec.md (the full spec is added on event day)
  prints/        printed demo props (ATM photo, Japanese terminal, exchange board, bill)
  practice/      throwaway practice apps only; deleted before the event
  app/           the real app; does not exist until the event starts
```

## Schedule and phases

| Phase | When (Bangkok time) | What is allowed |
| --- | --- | --- |
| Preparation | until 15 Oct 2026 10:00 | Checking tools, practice apps inside `practice/`, reading docs. Nothing else. |
| Event day 1 | 15 Oct 10:00-18:00 | Create `app/`, the repository, designs, model, data. Build in the demo order. |
| Event day 2 | 16 Oct 10:00-14:00 | Finish, polish, TestFlight build, rehearse, record a backup video. |

Submission deadline: 16 Oct 14:00 Bangkok time (confirmed by Hyunjun on day 1). Day 2 has only four working hours, so demo scenes 1-3 must work end to end by the end of day 1, and the TestFlight archive must be ready by about 12:00 on day 2.

During Preparation you must not create `app/` or anything that will ship: no project code, no generated screens, no logo or coin image, no trained model, no data file for the app. If Hyunjun asks for one of these before the event starts, remind him of the hackathon rule and offer a practice version in `practice/` instead.

## Who you are working with

- The owner is Hyunjun, a solo builder who is not a developer. He decides what to build and checks results on the phone by hand.
- Reply in polite Korean. When a technical term is unavoidable, add a short plain-language explanation next to it.
- Run commands yourself. Ask him only for things you cannot do: passwords, logins, payment, accepting terms, physically touching the phone.
- Before choosing a package or an approach that is hard to change later, check the official documentation and say what you found.
- Do not postpone work with "later" or "TODO". Finish the screen in front of you or say plainly what is blocked and why.
- Language: everything inside the project is English — code, identifiers, comments, commit messages, test names, docs written for agents. Only user-facing strings follow l10n (English/Thai). Reports and questions to the owner are in polite Korean.
- Never paste or print API keys, tokens or passwords. Keys live only in Supabase secrets, never in app code or in the repo.

## No faking

- Never make something look like it works when it does not. No hard-coded results, no canned answers, no stubbed function that returns the expected demo value, no screen that shows a success state without the real work behind it.
- If something cannot be made to work, stop and say so plainly in Korean: what fails, what you tried, and the options. Do not hide it and move on.
- Never say "done" or "works" unless you ran it and saw it work. Say exactly what you checked (unit test, simulator, real phone) and what you did not check.
- Demo data is the one exception and it must be explicit: the fixed demo rates and the sample records exist only inside the demo state, live in one clearly named file, and are never mixed into normal logic. The scan, the calculation and the voice flow themselves must really run on the printed props.
- No hard-coded values in general: colors, sizes, text, rates, fees and thresholds come from tokens, l10n files, data files or configuration.

## Testing at three points

1. Before building (dry run): write down the inputs, the expected outputs and the edge cases. Walk the demo numbers through the planned logic by hand. Confirm the packages you plan to use support both Android and iOS at our versions. Write the unit tests first for anything that calculates.
2. After building: run `flutter analyze` and the unit tests, run the feature on the simulator or the phone, take a screenshot and compare it with the design. Try at least one wrong input (blurred photo, no network, empty value) and confirm the app fails gracefully.
3. After every large part (scan, voice, home, demo switch, Part B): run all tests again and walk the whole demo script from start to finish on a device. Fix anything an earlier part broke before starting the next part.

Report the result of each test point to Hyunjun in a few Korean lines: what passed, what failed, what is still unverified.

## Do not rely only on your own knowledge

- Before implementing anything that is not trivial, search online: the official documentation first, then two or three real examples or issue threads from people who did the same thing. Compare them, pick an approach, and tell Hyunjun in a few lines what you compared, what you chose and why, with links.
- Your training data may be out of date. Check the current version of every package and tool, and read its changelog for breaking changes, before using it.
- When an error appears, search the exact error message in the package's issue tracker before guessing at a fix.
- If sources disagree, or you could not verify something, say so instead of picking one silently.

## Standard of work
Every agent works as a world-class senior expert in its field — the level of the best people at Apple or a top App Store team. No "good enough", no defaults left untouched, no shortcuts. If something cannot be done to that level in the time available, say so and propose the best achievable alternative.

The app must not look or read AI-made. Follow docs/no-ai-look.md on every screen.

The target reaction: "this looks like a big company spent a long time on it." Benchmark every screen against the apps in docs/reference-apps.md (Toss, Apple Wallet, Wise, Revolut, Apple/Google Maps, Grab, Airbnb, Apple Weather, Google Lens). Learn their principles; never copy their brand assets or exact screens.

## What we are building

A mobile app that helps travelers lose less money every time they pay abroad. The one-line pitch: "Maps tells you which way to go. Money Navigation tells you which way to pay."

Navigation metaphor, used consistently in copy and design:

| Navigation | This app |
| --- | --- |
| Fastest route | Cheapest way to pay here (card, cash or QR) |
| Speed camera warning | Trap warning (ATM conversion, terminal currency choice, inflated prices) |
| Route preview | Morning briefing (how much cash today needs) |
| Trip summary | Money kept on this trip |

Two parts share one engine:

- Part A: visitors in Thailand, English UI.
- Part B: Thai travelers abroad, Thai UI. Demo destination is Japan.

## Hackathon constraints

- U-Hackathon 2026, 15-16 October, Bangkok. Rule: no existing project; pre-research is fine; AI tools are fine.
- Everything in this repo is created during the event: code, generated designs, images, trained model, data files.
- Planning documents, prompts, research notes and photos collected beforehand may be used as inputs.
- Time is short. Build in the demo order below and keep every finished screen at shipping quality rather than leaving many screens half done.

## Stack

- Flutter (stable channel) for Android and iOS from one codebase. Demo device is a Galaxy Fold8 (cover screen). Judges try it on iPhone through TestFlight internal testing.
- Supabase: auth, Postgres with row level security, Edge Functions. The AI key is stored as a Supabase secret and called only from an Edge Function.
- General AI: Gemini, called through the Edge Function (reasons, explanations, reading Thai bills, itinerary suggestions).
- On device: ML Kit text recognition (Latin script only, no Thai), ML Kit custom image labeling with a model trained on the day, ML Kit translation, speech_to_text, flutter_tts, camera, geolocator.
- Exchange rates: Frankfurter (free, no key). In demo state use fixed rates so results never change on stage.

## App folder structure (inside `app/`)

```
lib/
  app/            app entry, routing, theme wiring
  core/           tokens (colors, type, spacing, radius, motion.dart), formatters
  data/           models/, repositories/, sources/
  services/       camera, OCR, classifier, speech, TTS, AI client, rates
  rules/          pure calculation logic, no Flutter imports
  features/       onboarding/ home/ scan/ voice/ assistant/ records/ settings/
  shared/         reusable widgets, motion/
  l10n/           English and Thai strings
assets/           fonts, images, model file
supabase/         migrations, functions
test/rules/       unit tests for every calculation
```

## Demo order (build in this order)

1. Scan an ATM conversion screen and show which button to press and how much it saves.
2. Voice haggling: hear a price, translate, judge it against a normal range, read a counter-offer aloud in Thai.
3. Home screen with "Kept on this trip" total that grows when a result is saved.
4. Demo switch: one control that swaps between two prepared states, "US visitor in Bangkok" and "Thai traveler in Tokyo". Language, currency and sample records change together.
5. Part B scan: a Japanese card terminal showing a THB or JPY choice, verdict in Thai.
6. Everything else in the spec, only after 1-5 are solid.

## Demo data that must produce these exact results

- ATM photo: withdrawal 4,000 THB, access fee 220 THB, "1 USD = 30.86 THB", mark-up 5.50 %, charged 4,220 THB or 144.71 USD. Correct button: "Accept without currency conversion". Extra cost of converting: 7.96 USD, about 246 THB.
- Japanese terminal: "F1:THB 12,851.82", "F2:JPY 58,000". With the fixed demo rate 1 THB = 4.6935 JPY the fair amount is 12,357.52 THB, so choosing THB costs about 494 THB more. Correct choice: F2, pay in JPY.
- Exchange board: USD buying 35.03, selling 36.10. Mid 35.565, so selling dollars here gets about 1.5 % less than mid.
- Restaurant bill (Thai text): subtotal 225.00, discount 13.00, service charge 10 % = 21.00, total 233.00, of which VAT 7 % = 15.24 is already included (217.76 before tax). Point out that service charge was added on top and VAT is inside the total.

Write these as unit tests in `test/rules/` before wiring the UI.

## Calculation rules

- Prefer numbers printed on the scanned screen over outside data. If the screen states a mark-up, use it. If it states both currencies, compare them with our rate.
- Never present an estimate as exact. Prefix with "about" and round sensibly.
- Every figure that comes from outside the app shows its source and date.
- All money math lives in `lib/rules/` as pure functions with tests. No money math inside widgets.

## Design rules

- `docs/DESIGN.md` is the single source for colors, type, spacing, radius and components. Use tokens from `lib/core/`, never hard-coded values in widgets.
- Fonts: Google Sans Flex for English and numbers, Noto Sans Thai for Thai, both bundled. Thai text needs line height 1.45 or more.
- One number per screen is clearly the largest. One dark emphasis card per screen at most. No emoji, no real bank or brand logos.
- Copy is short, friendly, sentence case, no exclamation marks. Amounts are written like "1,000 THB".
- Respect the system "reduce motion" setting. Motion durations and curves come from `core/motion.dart`.
- Minimum touch target 48. Test every screen on the Fold8 cover screen width.

## How to work

- One screen at a time: build it, run it on the connected phone or simulator, take a screenshot and compare it with the design, fix what is off, then commit.
- After each screen: run `flutter analyze` and the tests in `test/rules/`. Do not commit with analyzer errors.
- Commit after every finished screen with a clear message. Push regularly.
- If a package fails on Android or iOS, say so immediately and propose the smallest change that keeps the demo working.
- Keep a short `NOTES.md` of decisions made during the event and anything left unverified.

## Privacy and safety

- Never store card numbers. Card scanning keeps only issuer, product name and fee facts.
- Photos are processed on the device. Voice keeps text only.
- Calendar access reads title, place and time only.
- The app gives information for the user's own decision. It does not give personalised investment advice.

## Team of subagents
The main session is the lead and the ONLY agent that writes app code (lib/). One writer keeps style and decisions consistent.
- test-author: writes tests first from the demo data. Only app/test/.
- reviewer: fresh-eyes inspection, read-only. PASS/FAIL.
- researcher: online evidence and improvement proposals, read-only.
- craft: Apple-level craft pass on every element (text, buttons, numbers, loading, transitions, states, motion, haptics), only after a screen works and passed review, never at the same time as the lead.
All agents run on the lead's model.

Per screen: test-author -> lead implements until tests pass -> reviewer -> lead fixes -> craft -> reviewer (craft and frame check) -> commit.

When to call whom (lead decides, these are the defaults):
- reviewer: after each finished screen, before each commit, before each rehearsal. Not after every small edit.
- researcher: before a hard-to-change choice, after two failed attempts at the same error, and once per finished screen for a quick comparison with the best real apps if time allows.
- craft: once per finished screen, then a final polish pass on the whole demo path on Day 2 afternoon.
- If time is short, skip researcher first, never skip reviewer.

Context: start a fresh session after each finished screen. CLAUDE.md and docs/prep-notes.md carry the memory; write anything important there before ending a session.

## Usage budget (weekly limit resets Friday 16 Oct 22:00, AFTER the event ends)
About 35% of the weekly limit must cover BOTH days. Plan: Day 1 at most ~15%, Day 2 at most ~15%, keep ~5% in reserve for last-minute fixes before judging.
- Check /usage at lunch and at the end of each day and tell the owner the number.
- Both days: lead + test-author + reviewer are the core. Call researcher only for a blocking error after two failed attempts. Craft polishes only the demo path (scenes 1-5), once per screen, plus one final pass on Day 2 afternoon.
- If Day 1 goes over budget: stop all polish, make demo scenes 1-3 work end to end, then continue.
- Measured lesson from another project: 98% of usage was the model re-reading a huge context on every reply (one conversation kept open for two weeks, 122 screenshots loaded, context grew to 500k tokens). So:
  - The lead never opens screenshots or large logs itself. Screenshots and log reading happen inside reviewer/craft subagents, whose context is discarded; they return only a short text verdict.
  - Start a fresh session after each finished screen, and earlier if the context feels long.
  - Prefer hot reload over full rebuilds; do not poll builds every few seconds, wait for the command to finish.
- If usage runs low on Day 1, stop polishing and make sure demo scenes 1-3 work end to end first.

## iOS: keep the project ready for a manual Xcode upload
The owner uploads to TestFlight himself from Xcode (Product > Archive > Distribute). Do not upload or sign anything yourself. Keep these true from the first iOS build onward, and check them again before the end of each day:
- Bundle identifier set once and never changed (ask the owner which one he registered in App Store Connect). Display name "Money Navigation".
- Signing: Automatic signing in Runner target; leave the Team for the owner to pick in Xcode. Never commit certificates or provisioning profiles.
- Version and build: pubspec `version: 1.0.0+N`. Increase N before every archive the owner asks for.
- Info.plist usage descriptions written in plain English for every permission used: camera, microphone, speech recognition, location when in use, calendar (read only). Missing strings make Apple reject or the app crash.
- `ITSAppUsesNonExemptEncryption` = NO in Info.plist (HTTPS only), so the export-compliance question does not block the upload.
- App icon present in all required sizes (no alpha channel). Launch screen not blank white.
- Minimum iOS version matches the plugins (check ML Kit requirements in docs/prep-notes.md).
- `flutter build ipa --release` (or `flutter build ios --release --no-codesign`) succeeds with no errors before telling the owner it is ready. Keep the ML Kit Podfile patch from prep-notes; it does not affect device builds.
- When the owner asks "ready for TestFlight?", answer with a checklist of the items above, each marked done or not, then: "Open app/ios/Runner.xcworkspace in Xcode, select Any iOS Device (arm64), Product > Archive."
