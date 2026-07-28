# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Inkwell** is an iPad-only SwiftUI app for practicing Chinese and Japanese character handwriting (Hanzi/Kanji) with real-time stroke order, direction, and form recognition. It targets iPadOS 17+ (`TARGETED_DEVICE_FAMILY = 2`) with Apple Pencil support via PencilKit.

**Naming:** the user-facing product name is **Inkstone** ("Inkwell" was rejected by App Review under Guideline 5.2.5 — it's an Apple trademark). All user-visible strings, `INFOPLIST_KEY_CFBundleDisplayName`, the docs site, and App Store metadata say "Inkstone". The repo, Xcode project, scheme, targets, module (`@testable import Inkwell`), and bundle ID (`tsainez.Inkwell`) intentionally keep the internal name `Inkwell` — do not rename them, and never surface "Inkwell" in UI text.

## Build & Test Commands

```bash
# Build
xcodebuild -project Inkwell.xcodeproj -scheme Inkwell \
  -destination 'platform=iOS Simulator,name=iPad Pro (12.9-inch) (6th generation)' build

# Run all tests
xcodebuild test -project Inkwell.xcodeproj -scheme Inkwell \
  -destination 'platform=iOS Simulator,name=iPad (10th generation)' \
  -parallel-testing-enabled NO -enableCodeCoverage YES

# Run one Swift Testing suite (suites are structs, e.g. StrokeGraderUtilityTests)
xcodebuild test -project Inkwell.xcodeproj -scheme Inkwell \
  -destination 'platform=iOS Simulator,name=iPad (10th generation)' \
  -only-testing:InkwellTests/StrokeGraderUtilityTests

# Run a single test function inside a suite
xcodebuild test -project Inkwell.xcodeproj -scheme Inkwell \
  -destination 'platform=iOS Simulator,name=iPad (10th generation)' \
  -only-testing:InkwellTests/StrokeGraderUtilityTests/pathLengthEmptyArrayIsZero
```

**Xcode 16+ is required.** The project is saved in `objectVersion 77` format
with `PBXFileSystemSynchronizedRootGroup` entries — the `Inkwell/`,
`InkwellTests/`, and `InkwellUITests/` folders are *synchronized*, so a new
source file dropped into one of them joins the target automatically. Do not
hand-add file references to `project.pbxproj`; edit it only for real build
settings changes, and verify carefully when you do.

CI (`.github/workflows/swift.yml`) runs on `macos-15` (Apple Silicon, default
Xcode 16+), pipes through `xcbeautify`, and forces `-parallel-testing-enabled NO`
— parallel clones on the hosted runner spuriously fail tests in 0.000s.

**No external package dependencies** — only built-in frameworks (SwiftUI, PencilKit, SwiftData, SQLite3, CoreGraphics, AVFoundation, OSLog).

### Test frameworks

- `InkwellTests/` — **Swift Testing** (`import Testing`, `@Test`, `#expect`). Suites are plain `struct`s; there is no XCTest base class. Suite names double as the `-only-testing:` path component.
- `InkwellUITests/` — XCTest. Every UI test launches with `app.launchArguments = ["-inMemoryStore"]`, which `InkwellApp` reads to build an in-memory `ModelContainer` so runs don't pollute real SwiftData storage.
- `benchmark.swift` at the repo root is a **standalone** script (`swift benchmark.swift`) with its own mock types for profiling `CharacterTableView` filter/sort work. It is not part of any target.

## Architecture

### Navigation State Machine (`ContentView.swift`)

`ContentView` owns a single `ActiveScreen` enum that drives the entire app:
- `.library` → `LibraryView` (home/deck selection, custom glyph input, stats)
- `.characterTable` → `CharacterTableView` (mastery grid)
- `.settings` → `SettingsView`
- `.practice(CharacterDeck)` → `PracticeView` (active drawing loop)
- `.complete(CharacterDeck, [SessionResultItem])` → `SessionCompleteView` (post-session summary)

State transitions are passed as callbacks from child views back up to `ContentView`. `ContentView` also owns persistence (`saveResults`) and applies `.preferredColorScheme` for the app-wide appearance setting.

### Practice Loop Data Flow

1. User draws on `PencilCanvasView` (a `UIViewRepresentable` wrapping `PKCanvasView`)
2. `PencilCanvasView.Coordinator` (the `PKCanvasViewDelegate`) captures stroke points
3. Points are mapped from screen space to glyph-box space via `GlyphMetrics.boxPoint(canvas:)`
4. `StrokeGrader.judge()` compares the user's polyline to the reference median
5. Result (`.correct`, `.wrongDirection`, `.wrongStroke`, `.tooShort`) drives UI feedback in `PracticeView` — hints, `RejectedInk` fade-outs, `StreakTracker` milestones, sounds
6. Completed character results (`SessionResultItem`) bubble up to `ContentView`, which writes `CharacterProgress` via SwiftData

### Core Modules

| File | Role |
|------|------|
| `StrokeGrader.swift` | Pure stroke validation engine — no UIKit/PencilKit dependencies |
| `StrokeReference.swift` | SQLite loader, `GlyphMetrics` coordinate mapping, and the `SVGPath` parser; caches fetched glyphs |
| `IDSDecomposer.swift` | Synthesizes stroke data for glyphs missing from the DB by composing two component glyphs |
| `PracticeView.swift` | Main drawing UI: canvas, real-time grading, hints, palm rest, progress (largest file) |
| `GlyphOutlineView.swift` | Reference glyph rendering: ghost / completed / hint strokes plus the ink-flow reveal sweep |
| `GuideGridShape.swift` | Writing-pad guide grid (`rice` 米 / `field` 田 / `blank`) |
| `LibraryView.swift` | Home screen: deck browser, custom glyph input, character of the day, lifetime stats |
| `CharacterTableView.swift` | Mastery browser for all practiced characters (filter + sort) |
| `SettingsView.swift` | The only editor of `AppSettings` values; also progress reset and docs links |
| `AppSettings.swift` | `UserDefaults` key namespace + defaults; `AppAppearance` enum |
| `CharacterModels.swift` | `CharacterDeck`, `CharacterItem`, `StrokePoint`, `CharacterStrokeData`, `SeedData` decks |
| `CharacterProgress.swift` | SwiftData `@Model` for per-character mastery tracking |
| `DesignTokens.swift` | Single source of truth for all colors and typography |
| `ContentView.swift` | Root navigator / `ActiveScreen` state machine + result persistence |
| `SoundEffects.swift` | Synthesized feedback sounds (no audio assets); `.ambient` session, toggled in Settings |
| `StreakTracker.swift` | Pure consecutive-correct streak counting + milestone detection |
| `InkBurstView.swift` | Streak-milestone celebration overlay (seal stamp + ink-droplet burst) |
| `SealView.swift` | Vermilion hanko seal mark used in celebrations/branding |
| `InkButtonStyle.swift` | Shared press-feedback `ButtonStyle` (gentle scale + opacity dip) |

`Item.swift` is a leftover Xcode-template `@Model`. It is still registered in
`InkwellApp`'s `Schema`, so don't delete it casually — removing it changes the
store schema. `CharacterProgress` is the only model the app actually uses.

### Stroke Grading Algorithm (`StrokeGrader`)

The grader resamples both user and reference strokes to 16 equidistant points (arc-length resampling, per the $1 recognizer) then compares them forwards and reversed:

- Mean point distance ≤ 145 **and** start/end distance ≤ 215 → `.correct`
- Same thresholds met only when reversed → `.wrongDirection`
- Neither → `.wrongStroke`
- Stroke shorter than `min(50, modelLength * 0.5)` → `.tooShort` (accidental dab; **not** a miss — never feed it to `StreakTracker.recordMiss()`)

When both directions fit (short or symmetric strokes), the reverse fit must beat the forward fit by `directionMargin` (0.85) before it is called backwards.

All thresholds live in `StrokeGrader.Config` — adjust there, not inline. `leniency` scales the distance tolerances: `PracticeView` uses 1.0 for strict / 1.6 for lenient (the Settings toggle), then multiplies by a further **1.4 for `.synthesized` stroke data**, whose medians are approximate.

`StrokeGrader.indexOfBestMatch` powers "that looks like stroke N" out-of-order feedback.

### Coordinate Systems

Stroke geometry lives in the source data's **1024-unit em with a baseline at y = 900 and the y-axis pointing up**. `GlyphMetrics` is the only place that converts:

- `canvasPoint(rawX:rawY:)` — raw stroke data → on-screen canvas points (flips y)
- `boxPoint(_:)` — reference median point → grading box space (y flipped, unscaled)
- `boxPoint(canvas:)` — user pen sample → grading box space

Grading thresholds are expressed in box space, so they're independent of canvas size. Never mix coordinate spaces without going through `GlyphMetrics`.

### Data Sources & Lookup Chain

Stroke geometry is bundled locally — no network dependency. `StrokeReference.data(for:)` resolves a glyph in this order, caching the result in memory:

1. **Memory cache**
2. **`StrokeData.sqlite`** (~46 MB) — schema `character_strokes(glyph TEXT PRIMARY KEY, strokes_json TEXT, medians_json TEXT)`; produces `source == .reference` (filled brush-outline SVG paths)
3. **`IDSDecomposer.synthesize`** — looks the glyph up in `IDS_fallback.json` (operator `lr`/`tb` + exactly two component glyphs), fetches both components *from the DB only* (never recursively synthesized), and packs them into half-boxes. Produces `source == .synthesized` with open-path `M x,y L x,y` centerlines
4. **`nil`** → `PracticeView` falls back to free-practice mode

`StrokeData.json` (~44 KB) is a whole-database fallback loaded only when the SQLite file can't be opened.

`source` matters downstream: `GlyphOutlineView` strokes synthesized paths (`context.stroke`, fat round cap) instead of filling them, `PracticeView` shows a "synthesized" notice, and the grader loosens tolerances.

Attribution: Make Me a Hanzi / hanzi-writer-data (LGPL / Arphic License) — see `Inkwell/StrokeData-ATTRIBUTION.txt` and `docs/LICENSES.md`.

### Data Pipeline (`scripts/`)

Python scripts that regenerate bundled assets; not run at build time.

- `build_stroke_db.py` — builds `Inkwell/StrokeData.sqlite` from vendored animCJK / hanzi-writer datasets. Use `cursor.executemany` for bulk inserts, not per-row `execute`.
- `generate_ids_fallback.py` — builds `Inkwell/IDS_fallback.json` (needs `hanzipy`); keeps only basic-CJK glyphs absent from the DB that decompose into two spatial components both present in the DB.
- `generate_app_icon.py` — renders the 永 app-icon set (light/dark/tinted) from the DB (needs `cairosvg`).

The large vendored source datasets (`scripts/animCJK/`, `scripts/hanzi-writer-data/`) are gitignored — the scripts skip missing inputs, so re-running requires fetching them first.

### Settings & Persistence

`AppSettings.Key` is the single namespace for `@AppStorage` keys; all defaults live next to them in `AppSettings`.

| Key | Type | Read by |
|-----|------|---------|
| `settings.strictGrading` | `Bool` | `PracticeView` (leniency 1.0 vs 1.6) |
| `settings.gridStyle` | `GuideGridStyle` raw | `PracticeView` writing pad |
| `settings.hintThreshold` | `Int` (1…6) | `PracticeView` — misses before the next stroke is highlighted |
| `settings.appearance` | `AppAppearance` raw | `ContentView.preferredColorScheme` |
| `settings.soundEffects` | `Bool` | `SoundEffects` |

Enums stored raw always decode through their `init(storedRawValue:)` so an unknown string falls back to the default rather than crashing. `SettingsView` is the only place these are edited.

### SwiftData Models

`CharacterProgress` is keyed on `@Attribute(.unique) var glyph: String` and tracks `timesPracticed` / `timesFlawless` / `totalMistakes` plus first/last dates, deriving `accuracyPercentage` and `masteryLevel(threshold:)`. Access it only through the SwiftData model context — do not hold raw references across context boundaries.

When matching a `@Query` array against session results, build a `[glyph: CharacterProgress]` dictionary *once* outside the loop (see `ContentView.saveResults`) — `.first(where:)` inside a loop is O(N·M).

### Design Tokens (`DesignTokens.swift`)

Always use `InkTheme` constants — never raw color values or system colors.
Every token is **appearance-adaptive**: it carries both a light and a dark value
and resolves automatically per trait collection, so views never branch on
`colorScheme`. Tokens are built from `UIColor.inkAdaptive(_:_:)` (a dynamic
`UIColor`) and exposed as SwiftUI `Color`s.

```swift
//                        light      dark      role
InkTheme.accent      //  #c8492f   #e15d42   vermilion — primary accent
InkTheme.paper       //  #f7f4ee   #17150f   app background
InkTheme.ink         //  #2b2925   #f4efe6   primary text & strong fills
InkTheme.onInk       //  #ffffff   #17150f   content sitting on an `ink` fill
InkTheme.ink2        //  #6b665d   #b8b1a3   secondary text
InkTheme.ink3        //  #9a948a   #8a8376   tertiary / muted text
InkTheme.line        //  #e7e2d8   #39342b   borders
InkTheme.line2       //  #efebe2   #2a261f   dividers / track / chip bg
InkTheme.card        //  #fffdf9   #211d17   card surfaces
InkTheme.jade        //  #1f6f6b   #3fa39d   secondary deck accent
InkTheme.sun         //  #9a6a2f   #c89a5a   alternate deck accent
// Effect tokens — alpha baked into the hex (ARGB), because these need
// per-mode *opacity*, not just hue:
InkTheme.shadow      // #0a000000 #33000000  card elevation
InkTheme.glyphGhost  // #249a948a #40b8b1a3  faint reference glyph
InkTheme.guide       // #38c8492f #66e15d42  writing-pad guide lines
```

Key rule: a filled button uses `.background(InkTheme.ink)` paired with
`.foregroundColor(InkTheme.onInk)` — **never** a hardcoded `.white`, which
disappears against the light `ink` fill in Dark Mode. `.white` is only correct
on saturated accent/deck-color fills. For PencilKit (which needs a `UIColor`,
not a `Color`), use `InkTheme.inkUI`.

Deck accents go through `CharacterDeck.accent` (adaptive) rather than the raw
`accentColor` hex string.

Typography: `.inkSerif(size:weight:)` for display/headings, `.inkSans(size:weight:)` for UI/body.

### Animation, Sound & Accessibility Conventions

- Every animation must respect **Reduce Motion** (`@Environment(\.accessibilityReduceMotion)`): drop offsets/scales/particles and fall back to plain opacity fades or an instant final state.
- All audio goes through `SoundEffects.shared.play(_:)` — `Event` cases are `.strokeCorrect`, `.strokeRejected`, `.characterComplete`, `.streakMilestone`, `.sessionComplete`. Sounds are synthesized on a shared pentatonic scale (no audio assets), use the `.ambient` session (silent-switch aware, mixes with the user's music), and are gated by the Settings toggle.
- Celebration overlays (`InkBurstView`, the done-veil seal stamp, `GlyphOutlineView`) must never block input: keep `allowsHitTesting(false)` and let them dismiss themselves.
- Icon-only buttons require an explicit `accessibilityLabel`. Reusable icon-button builders (e.g. `PracticeView.veilButton`) take the label as a **required** parameter so it can't be forgotten at a call site.
- Log sensitive values with explicit privacy: `logger.error("… \(url.path, privacy: .private)")`. Swift's `Logger` treats interpolations as public by default, and file paths leak device/user directory structure into sysdiagnose logs.

## Privacy & Release

The app is fully offline: `PrivacyInfo.xcprivacy` declares no tracking, no collected data, and `UserDefaults` (reason `CA92.1`) as the only required-reason API. Keep it that way — adding a network call or analytics means updating the manifest, `docs/PRIVACY.md`, and App Store answers.

`docs/` is published via GitHub Pages from `main` and supplies the App Store Connect URLs (`/privacy/`, `/licenses/`, `/support/`) that `SettingsView` links to directly. `docs/RELEASE_CHECKLIST.md` tracks outstanding App Store items.

## Key Conventions

- **Modular SwiftUI views** with single responsibilities; navigation state is lifted to `ContentView`
- **Grading logic stays pure Swift** — `StrokeGrader`, `StreakTracker`, and `IDSDecomposer` have no UIKit/PencilKit imports, which is what makes them unit-testable
- **Branch naming** (`AGENTS.md`): prefix branches with the agent's name and a slash (`claude/`, `jules/`, `gemini/`) so Git clients and Xcode group them into folders
- `.jules/` and `.Jules/` hold short "learning" notes from prior agent runs (performance, security, accessibility findings) — worth skimming before touching the same areas
- The `design_handoff_inkpath/` directory contains React/JSX design prototype reference files — it is **not production code** and should not be modified as part of app development
