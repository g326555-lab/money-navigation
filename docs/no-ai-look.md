# No "AI-made" look

The app must look and read like it was made by a small, obsessive product team, not generated. Judges and users dismiss anything that looks AI-made as cheap. Every agent follows this file. The craft agent checks every screen against it, and the reviewer fails a screen that shows any tell below.

## Visual tells to avoid
- Default framework look: Flutter's default purple/deepPurple seed color, untouched Material 3 components, default ripple, default Roboto, default AppBar. Everything comes from our tokens in docs/DESIGN.md.
- "VibeCode purple", lavender accents, purple-to-blue gradients. Gradients in general unless DESIGN.md defines them.
- Colored glows (zero-offset colored blur, saturated tint, alpha above 15 %) and neon. Low-alpha, hue-tinted, downward layered shadows as defined in DESIGN.md are required instead.
- Glassmorphism on content. Glass is only for the floating tab bar, the action dock and camera controls.
- One identical heavy shadow on everything; neumorphism; mixed corner types (some rounded rectangles, some superellipses).
- Bouncy springs on every element; overshoot is for hero landings only.
- Chunky game-style 3D buttons, clay 3D emoji, confetti storms, spin wheels or countdowns in money flows.
- Cards with a colored top or left border stripe (the most recognizable AI tell).
- Rows of identical cards with an icon on top; every block in the same rounded card with the same shadow.
- Stat-banner rows and "1-2-3" step rows used as decoration.
- Badge/pill sitting above every headline; all-caps section labels everywhere.
- Emoji used as icons or in UI copy. Sparkle (✨) or magic-wand icons to signal "AI". "AI-powered" badges.
- Mixed icon styles; generic stock illustrations; random 3D blobs.
- Low-contrast grey body text on dark backgrounds. Body text must meet WCAG AA.
- Everything centered. Use deliberate alignment.
- Chat-bubble UI for things that are not a conversation.

## Copy tells to avoid
- Stock words: delve, seamless, streamline, unlock, elevate, empower, game-changing, revolutionize, harness, leverage, robust, furthermore, moreover, "that being said".
- Assistant voice: "Hi! I'm your AI assistant", "Great question!", "Sure! Here's…", "I hope this helps".
- Exclamation marks and celebration emoji ("Great! 🎉"). We never use them.
- Em-dashes and colons in short UI strings; long headings packed with keywords.
- Repeating the same idea in title, subtitle and body.
- Vague labels ("Submit", "OK", "Continue") instead of what happens ("Save to trip", "Pay in yen").
- Placeholder-sounding text, "Lorem", "John Doe", round fake numbers.
- Overly formal words where a plain word works.

## Motion tells to avoid
- Everything fading and sliding in on load with the same delay.
- Linear or identical easing on everything; bouncy springs on everything.
- Spinners and "Thinking…" dots instead of showing the real steps.
- Typewriter text effect for AI answers.

## What to do instead
- One strong layout idea per screen, repeated consistently. Hierarchy from type size and spacing, not boxes and shadows.
- Real content and real numbers from our demo data, written for this app's world (THB, JPY, F1/F2, service charge, VAT).
- Copy written like a calm, experienced local friend: short, specific, plain. Thai copy reviewed by a native speaker.
- Icons from one set, one stroke weight, used only where they add meaning.
- Motion only where it explains cause and effect (see .claude/agents/craft.md).
- Before finishing any screen, ask: "Would this look at home in a top App Store app made by a real team?" If not, fix it.

## Sources (checked 2026-10-14)
- AI Design Slop: 16 patterns — https://www.developersdigest.tech/blog/ai-design-slop-and-how-to-spot-it
- The AI purple problem — https://dev.to/jaainil/ai-purple-problem-make-your-ui-unmistakable-3ono
- Why every vibe-coded app looks the same — https://medium.com/plainify/why-every-vibe-coded-app-looks-the-same-and-how-a-spec-fixes-it-35316dfb42de
- What makes writing sound like AI — https://write.as/nerd-for-hire/what-exactly-makes-writing-sound-like-ai
