# Handoff: Inkpath — iPad Stroke-Order Writing App

## Overview
**Inkpath** is an iPad-first app for learning to hand-write Japanese kanji and Chinese
characters (simplified or traditional) in the **correct stroke order**, using the Apple
Pencil. The user is shown a character (by meaning/reading, or as a reference glyph) and
draws it stroke-by-stroke on a practice grid; the app validates each stroke's order and
shape in real time, then summarizes the session.

The core differentiator vs. existing apps: **iPad + Apple Pencil first**, with a calm,
"ink-on-paper" editorial aesthetic rather than a gamified language-app look.

Target user: English speakers learning to write Japanese (kanji) or Chinese.

---

## About the Design Files
The files in this bundle (`Inkpath — iPad Prototype.html` + its `.jsx` partials) are
**design references created in HTML/React** — a working prototype that demonstrates the
intended look, layout, and interaction model. **They are not production code to ship.**

The prototype proves the hard part — the stroke-order validation loop — using the
open-source **Hanzi Writer** JS library and its CDN data. That is a *prototyping shortcut*.
The production task is to **recreate these designs natively** (see Tech Recommendation) with
a properly licensed, bundled stroke dataset.

Your job: reproduce the screens and behavior below in the target environment, using its
native patterns — not to port the HTML/JS verbatim.

---

## Fidelity
**High-fidelity.** Colors, typography, spacing, and interactions are final and should be
matched closely. Exact tokens are listed under **Design Tokens**.

---

## Tech Recommendation (strong opinion, not binding)
Build **native: Swift + SwiftUI, with PencilKit** for the drawing surface.

Rationale:
- The product's entire value is Apple Pencil handwriting. **PencilKit** gives low-latency
  ink, pressure, tilt, and (M2 iPads) hover for free; `PKStroke` exposes per-stroke point
  data ideal for stroke comparison.
- Stroke-order grading = comparing the user's stroke path against reference **median**
  points per stroke. This is straightforward Swift math; no JS bridge latency.
- Stroke data can be bundled locally → fully offline, instant, no CDN dependency (the
  prototype's CDN fetch is a prototype-only compromise).

Acceptable alternative **only if Android is a hard requirement**: Flutter (better custom
`CustomPainter`/canvas performance than React Native for this use case). Avoid React Native
for the drawing surface — input latency hurts a handwriting product.

---

## Data Architecture (the "character database" problem)
A practice "deck" is really **two independent datasets**. Keep them separate.

### 1. Stroke geometry (per-stroke paths + medians)
- **Japanese:** **KanjiVG** (`CC BY-SA`) — authentic Japanese stroke order/forms, per-stroke
  SVG paths + component annotations. Or **AnimCJK** (built on KanjiVG, animation-ready).
- **Chinese:** **Make Me a Hanzi** (`makemeahanzi`, mix of `LGPL`/`Arphic` license) —
  the dataset Hanzi Writer itself uses. Provides `strokes` (SVG paths) and `medians`
  (arrays of [x,y] points) per character in a 1024×1024 grid (y-axis flipped).

The grading algorithm needs the **medians**: for each expected stroke, compare the user's
drawn polyline against the median (direction + proximity, with a leniency threshold).

**Important Japanese caveat:** the prototype currently renders *Chinese* stroke forms for
the Japanese deck (Hanzi Writer's data). In production, the Japanese decks **must** use
KanjiVG so stroke forms/order match Japanese convention (several kanji differ from Chinese).

### 2. Curriculum (which characters, meanings, readings)
- **Japanese:** **KANJIDIC2** (EDRDG, `CC BY-SA`) — meanings, on/kun readings, stroke
  counts, JLPT level, school grade for ~13k kanji. Slice decks by **JLPT** (N5→N1) or
  **Jōyō/Kyōiku** grade. **JMdict** for example vocabulary if desired.
- **Chinese:** **HSK** word lists + a CC-CEDICT-derived meaning/pinyin source.

Convert/normalize both datasets at build time into the app's own model (see **State /
Data Model**). Honor `CC BY-SA` attribution + share-alike terms.

---

## Screens / Views

### 1. Library (Home)
**Purpose:** Pick a curated deck or start custom practice.

**Layout:** Full-screen on `--paper`, 44px/48px padding. Vertical stack:
1. **Top bar** (`.lib-head`, space-between): brand lockup (vermilion seal mark "書" 34px +
   "Inkpath" wordmark in Newsreader 26px / "stroke order, by hand" tagline) on the left;
   a pill "🔥 4 day streak" on the right.
2. **Hero** (`.lib-hero`): a **2-column grid** `1fr 360px`, 40px gap, with a 1px bottom
   divider (`--line`), 38px top margin / 32px bottom padding.
   - **Left:** eyebrow "GOOD EVENING" (accent, 13px, uppercase, .12em tracking); H1 "What
     will you write today?" (Newsreader 42px, weight 400, line-height 1.05, max-width 16ch);
     a stats row — three stats ("characters practiced", "decks available", "92% avg.
     accuracy") with Newsreader 34px numerals, separated by 1px×38px dividers.
   - **Right:** the **Custom Practice panel** (see below).
3. **Deck grid** (`.deck-grid`): 3 equal columns, 22px gap. Each **deck card**:
   - Card: `--card` bg, 1px `--line` border, 20px radius, 24px padding, subtle shadow on
     hover + 4px translateY lift + a colored 4px left-edge bar (accent per deck:
     vermilion / ink / jade).
   - Top row: tag "SCRIPT · LEVEL" (12px uppercase, `--ink-3`); 3 preview glyphs in
     `--cjk` at 30px with decreasing opacity (.9/.5/.28).
   - Body: deck title (Newsreader 25px); blurb (14px, `--ink-2`, line-height 1.55).
   - Footer: progress bar (5px track, `--line-2`; fill `--ink` or accent) + "0/10" label;
     a 38px circular "→" button that fills with accent on card hover.

**The three seed decks** (see `data.jsx` for exact content):
- "First Kanji" — Japanese · JLPT N5 — 日 月 火 水 木 金 土 山 川 人 (with on/kun readings)
- "Essentials" — Chinese · HSK 1 — 你 好 我 是 不 中 国 学 人 大 (with pinyin)
- "Numbers 一–十" — Chinese · Japanese — 一…十 (with both pinyin + Japanese readings)

#### Custom Practice panel (`.custom-panel`)
**Purpose:** Practice *any* character, word, or sentence not in a curated deck.
- Card on `--card`, 18px radius, 22px padding, soft shadow.
- Eyebrow "▦ PRACTICE ANYTHING" (accent); lead line (13px `--ink-2`).
- **Input row:** a serif text field (Newsreader 21px; placeholder "Type or paste 漢字…" in
  `--cjk`; focus → accent border + white bg) + a 46px dark square submit button with an
  accent "→".
- **Meta row:** when input contains CJK, shows a live count e.g. "4 characters · phrase
  mode"; otherwise "Tries:" followed by tappable suggestion chips (愛 夢 桜 山川 一期一会 謝謝).
- **Behavior:** on submit, filter input to CJK ideographs
  (`/[\u3400-\u9FFF\uF900-\uFAFF]/`). 1 character → single custom practice; 2+ → **phrase
  mode**. Build an ad-hoc deck and route to Practice. Enter key also submits.

---

### 2. Practice (the core loop)
**Purpose:** Write the current character stroke-by-stroke with live validation.

**Layout:** Full screen, vertical:
- **Header** (`.pr-top`, 20px/32px padding, 1px bottom border): back button (42px rounded
  square) · center block with deck label ("SCRIPT · Title") + a **progress track** of dots
  (done = `--ink`, active = accent wider pill, upcoming = `--line`) · right counter
  "3 / 10" (Newsreader 22px).
- **Body** (`.pr-main`, two columns):
  - **Left** (fixed 620px, centered, 1px right border): the **pad card** — `--card`, 24px
    radius, 30px padding, big soft shadow — containing a **460×460 writing pad**:
    - A grid SVG (`.pad-grid`): rounded border + faint accent **guide lines**. Three styles
      (Tweak): `rice` (米 — center cross + diagonals), `field` (田 — center cross only),
      `blank` (border only). Lines are dashed `rgba(200,73,47,~.22)`.
    - The character target where strokes render. Drawn strokes use the accent color, ~26px
      brush; completed strokes highlight in accent.
    - Optional faint character outline guide (Tweak: "Faint character guide").
    - **Done overlay** (`.done-veil`) on completion: a 52px accent circle with a check
      (or ink circle + "→" if skipped), a Newsreader 24px word ("Perfect" / "Well written"
      / "Skipped"), and a sub-line ("clean stroke order" / "N stroke corrections" /
      "come back to this one"). Animates in (badge pops, veil fades).
  - Under the pad: a **controls row** — "▶ Show stroke order" (animates the full character
    then restarts the quiz), "↻ Redo" (clears + restarts the quiz), and a ghost "⏭ Skip"
    (before done) / "Next" (after done).
  - **Right** (`.pr-right`, centered):
    - If **phrase mode**: a **phrase strip** (`.phrase-strip`) at top — eyebrow "PHRASE ·
      CHARACTER 3 OF 4" and the full phrase in `--cjk` 30px, each char colored by state:
      upcoming (`--ink-3`, .45 opacity), written (`--ink`), **current** (accent, lifted).
    - **Prompt block:**
      - Curated deck: eyebrow "WRITE THIS CHARACTER"; **meaning** (Newsreader 42px);
        **reading** (19px `--ink-2`); meta pills ("🔊 Audio", script label).
      - Custom/phrase: eyebrow; a large **reference glyph** (`--cjk` 64px); helper line
        "Trace it in the box, in stroke order."; a "Custom practice" pill.
    - **Hint card** (`.hint-card`, `--card`, 18px radius):
      - Before done: rows "Strokes left" / "Corrections" (Newsreader 26px tabular numerals)
        + a tip line (changes based on whether stroke hints are on).
      - After done: the big glyph (`--cjk` 90px) + a dark **"Next character →"** button.
        In custom/phrase mode, also an **auto-advance indicator** ("◻▭ moving on
        automatically…") with a 1.05s depleting accent bar.

**Validation model (per stroke):**
- Quiz runs one character at a time. For each expected stroke in order, accept the user's
  drawn stroke if it matches the reference median within a **leniency** threshold
  (Tweak: strict ≈ tight tolerance, lenient ≈ looser). Out-of-order / wrong-shape strokes
  are rejected and counted as a **correction (mistake)**.
- After N misses on the same stroke (default 3), **highlight** the correct next stroke
  (Tweak: "Stroke hints" on/off → on disables this).
- On the final stroke, mark the character complete with `totalMistakes`.

**One-character-at-a-time rule (important):** even in phrase mode, grading is **always per
single character**. Phrase mode only adds context (the strip) and auto-advance; it does NOT
attempt to grade multiple characters on one canvas. This is a deliberate scope boundary to
avoid multi-glyph segmentation/grading complexity.

---

### 3. Session Complete
**Purpose:** Summarize the session and offer next action.

**Layout:** Centered card (560px) on a soft radial-light `--paper` bg:
- Seal mark (40px); eyebrow "SESSION COMPLETE"; deck title (Newsreader 38px).
- **Glyph grid** of every character attempted (58px rounded tiles, `--cjk` 30px). Perfect
  (0 mistakes, not skipped) tiles get an accent border + tinted bg + a small accent check
  badge top-right. Skipped tiles are dashed + dimmed.
- **Stats row** (4 tiles): "written" (count), "flawless" (perfect count), "first-try %"
  (perfect/total), "corrections" (total mistakes).
- A "🔥 Streak extended to 5 days" line.
- **Actions:** primary dark "Practice again" + secondary "🏠 Library".

---

## Interactions & Behavior
- **Navigation:** Library → (deck or custom) → Practice → Complete → (Library | Practice
  again). Back button in Practice returns to Library.
- **Auto-advance (custom/phrase only):** on character completion, show the done overlay
  ~1.05s, then automatically advance to the next character (or to Complete after the last).
  The depleting bar communicates the wait. The "Next character" button still advances
  immediately if tapped. Curated decks do **not** auto-advance (user may want to study the
  meaning/reading), advancing only on explicit tap.
- **Show stroke order:** cancels the quiz, shows outline, animates the character drawing
  itself, then hides it and restarts the quiz (speed is a Tweak, 0.5×–2.5×).
- **Redo:** cancels + restarts the quiz for the current character; resets stroke/mistake
  counters.
- **Skip:** marks current character skipped (counts as 0 mistakes, excluded from "flawless")
  and shows the skipped done-state.
- **Animations:** done badge pop (`scale .4→1`, ~.45s, slight overshoot), veil fade (~.4s),
  auto-advance bar `scaleX(1→0)` linear 1.05s. Respect reduced-motion in production.

---

## State Management
Suggested per-session state (in Practice):
- `idx` — current character index in the active deck.
- `done` / `skipped` — current character completion state.
- `strokesLeft` — remaining strokes (from the validator's progress callback).
- `mistakes` — corrections on the current character.
- `results: [{ char, mistakes, skipped }]` — accumulates per character; drives the
  Complete screen.
App-level: active route, active deck, and per-deck progress (set of completed characters).
The prototype keeps progress in memory only; production should persist (see below).

## Persistence (production, not in prototype)
- Per-character mastery / SRS scheduling (e.g. store last-practiced, ease, due date).
- Streak + daily goal.
- Custom-practice history (recent searches / phrases).
- All stroke data bundled on-device for offline use.

---

## Design Tokens

### Colors
| Token | Hex | Use |
|---|---|---|
| `--accent` | `#c8492f` | vermilion seal/primary accent (Tweakable) |
| `--paper` | `#f7f4ee` | app background (Tweakable: also `#f4f1ea`, `#efece3`, `#faf8f4`) |
| `--ink` | `#2b2925` | primary text, drawn strokes, dark buttons |
| `--ink-2` | `#6b665d` | secondary text |
| `--ink-3` | `#9a948a` | tertiary / muted text |
| `--line` | `#e7e2d8` | borders |
| `--line-2` | `#efebe2` | subtle dividers / track bg |
| `--card` | `#fffdf9` | card surfaces |
| `--jade` | `#1f6f6b` | secondary deck accent |
| (alt accents) | `#1f6f6b`, `#9a6a2f`, `#2b2925` | Tweak options |

### Typography
- **Sans (UI):** "Hanken Grotesk" — weights 400/500/600/700.
- **Serif (display, meanings, numerals):** "Newsreader" — 400/500, plus italic.
- **CJK glyphs:** "Noto Serif SC" — 400/500/600/700. *(Production: also load a Japanese
  serif such as Noto Serif JP for Japanese decks so kana/forms render idiomatically.)*
- Scale in use: H1 42px, deck/section titles 25–38px, meaning 42px, reference glyph 64px,
  big glyph 90px, body 13–15px, eyebrows 12–13px uppercase .1–.14em tracking.

### Spacing / Shape
- Card radius 18–24px; pills 999px; buttons 11–13px.
- Screen padding 44–48px; card padding 22–30px; grid gaps 22px (decks) / 40px (hero).
- Borders 1px `--line`. Shadows: soft, low-opacity, large-blur (e.g.
  `0 30px 60px -40px rgba(43,41,37,.5)` on the pad card).

### Device frame
- Designed for **iPad landscape**, content canvas **1194×834**, 16px black bezel,
  outer radius 42px / screen radius 28px. (This is the prototype's framing; in a real app
  the content fills the iPad screen and adapts to size classes / Stage Manager.)

### Tweakable parameters (exposed in prototype, good as Settings in production)
Guide-line style (rice/field/blank), faint character guide on/off, stroke hints on/off,
strict grading on/off, demo speed 0.5–2.5×, accent color, paper color.

---

## Assets
- **No bitmap assets.** The seal mark is a CSS square with the glyph "書". Icons are
  inline SVG (see `components.jsx` `Icon`).
- **Fonts:** Google Fonts (Hanken Grotesk, Newsreader, Noto Serif SC) — swap to bundled /
  system equivalents in production (e.g. SF Pro for UI, New York for serif on Apple
  platforms; bundle a CJK serif).
- **Stroke data:** see **Data Architecture** — must be sourced + bundled (KanjiVG /
  Make Me a Hanzi) and is the single most important asset to get right.

---

## Files (in this bundle)
- `Inkpath — iPad Prototype.html` — the prototype entry; contains all CSS (design tokens
  + every screen's styles) and loads the partials below.
- `app.jsx` — root: routing, Tweaks wiring, per-deck progress, default tweak values.
- `library.jsx` — Library + Custom Practice panel + `buildCustomDeck()`.
- `practice.jsx` — the core writing loop, validation wiring, auto-advance, phrase strip.
- `complete.jsx` — session summary.
- `components.jsx` — shared bits (Seal, Icon set, iPad frame, progress track).
- `data.jsx` — the three seed decks with meanings/readings/pinyin.
- `tweaks-panel.jsx` — the in-prototype settings panel (reference for what's configurable).

> Note: the prototype validates strokes with **Hanzi Writer** (`hanzi-writer@3.7.3`) +
> `hanzi-writer-data` over a CDN. Treat that as the *reference implementation* of the loop,
> not a production dependency — reimplement natively against bundled, properly licensed data.

---

## Open Decisions / Recommended Next Steps
1. Confirm platform: native Swift/SwiftUI + PencilKit (recommended) vs. cross-platform.
2. Source + license stroke data: KanjiVG (JP) and Make Me a Hanzi (ZH); build a converter
   to the app's stroke/median model; bundle on-device.
3. Generate curriculum from KANJIDIC2 (JP) / HSK + CEDICT (ZH); define deck slicing
   (JLPT vs. Jōyō grade).
4. Decide SRS / progress model + persistence.
5. Audio: source per-character/word pronunciation (TTS vs. recorded).
6. Accessibility: reduced-motion, Dynamic Type, VoiceOver labels for characters/readings.
