# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Inkwell** is an iPad-first SwiftUI app for practicing Chinese and Japanese character handwriting (Hanzi/Kanji) with real-time stroke order, direction, and form recognition. It targets iPadOS 17+ with Apple Pencil support via PencilKit.

**Naming:** the user-facing product name is **Inkstone** ("Inkwell" was rejected by App Review under Guideline 5.2.5 — it's an Apple trademark). All user-visible strings, `CFBundleDisplayName`, the docs site, and App Store metadata say "Inkstone". The repo, Xcode project, scheme, targets, module (`@testable import Inkwell`), and bundle ID intentionally keep the internal name `Inkwell` — do not rename them, and never surface "Inkwell" in UI text.

## Build & Test Commands

```bash
# Build
xcodebuild -project Inkwell.xcodeproj -scheme Inkwell \
  -destination 'platform=iOS Simulator,name=iPad Pro (12.9-inch) (6th generation)' build

# Run all tests
xcodebuild test -project Inkwell.xcodeproj -scheme Inkwell \
  -destination 'platform=iOS Simulator,name=iPad (10th generation)' \
  -enableCodeCoverage YES

# Run a single test by name (replace TestName with e.g. testCorrectStroke)
xcodebuild test -project Inkwell.xcodeproj -scheme Inkwell \
  -destination 'platform=iOS Simulator,name=iPad (10th generation)' \
  -only-testing:InkwellTests/InkwellTests/TestName
```

The CI pipeline (`.github/workflows/swift.yml`) runs on macOS 14 with Xcode 15.4 against the iPad 10th generation simulator.

**No external package dependencies** — the project uses only built-in frameworks (SwiftUI, PencilKit, SwiftData, SQLite3, CoreGraphics).

## Architecture

### Navigation State Machine (`ContentView.swift`)

`ContentView` owns a single `ActiveScreen` enum that drives the entire app:
- `.library` → `LibraryView` (home/deck selection, stats)
- `.characterTable` → `CharacterTableView` (mastery grid)
- `.practice(CharacterDeck)` → `PracticeView` (active drawing loop)
- `.complete(CharacterDeck, results)` → `SessionCompleteView` (post-session summary)

State transitions are passed as callbacks from child views back up to `ContentView`.

### Practice Loop Data Flow

1. User draws on `PencilCanvasView` (a `UIViewRepresentable` wrapping `PKCanvasView`)
2. `PencilCanvasView.Coordinator` (the `PKCanvasViewDelegate`) captures stroke points
3. Points are mapped from screen space to 1024×1024 glyph box space via `GlyphMetrics`
4. `StrokeGrader.judge()` compares the user's polyline to the reference median
5. Result (`.correct`, `.wrongDirection`, `.wrongStroke`, `.tooShort`) drives UI feedback in `PracticeView`
6. Completed character results are persisted to `CharacterProgress` via SwiftData

### Core Modules

| File | Role |
|------|------|
| `StrokeGrader.swift` | Pure stroke validation engine — no UIKit/PencilKit dependencies |
| `StrokeReference.swift` | SQLite loader + SVG path parser; caches fetched glyphs |
| `PracticeView.swift` | Main drawing UI: canvas, real-time grading, progress |
| `LibraryView.swift` | Home screen: deck browser, custom input, lifetime stats |
| `CharacterTableView.swift` | Mastery browser for all practiced characters |
| `CharacterModels.swift` | Data structs: `CharacterDeck`, `CharacterItem`, `StrokePoint` |
| `CharacterProgress.swift` | SwiftData `@Model` for per-character mastery tracking |
| `DesignTokens.swift` | Single source of truth for all colors and typography |
| `ContentView.swift` | Root navigator / `ActiveScreen` state machine |
| `SoundEffects.swift` | Synthesized feedback sounds (no audio assets); `.ambient` session, toggled in Settings |
| `StreakTracker.swift` | Pure consecutive-correct streak counting + milestone detection |
| `InkBurstView.swift` | Streak-milestone celebration overlay (seal stamp + ink-droplet burst) |
| `InkButtonStyle.swift` | Shared press-feedback `ButtonStyle` (gentle scale + opacity dip) |

### Animation & Sound Conventions

- Every animation must respect **Reduce Motion** (`@Environment(\.accessibilityReduceMotion)`): drop offsets/scales/particles and fall back to plain opacity fades.
- All audio goes through `SoundEffects.shared.play(_:)` — sounds are synthesized on a shared pentatonic scale, use the `.ambient` session (silent-switch aware, mixes with the user's music), and are gated by the "Sound effects" toggle in Settings (`AppSettings.Key.soundEffects`).
- Celebration overlays (`InkBurstView`, the done-veil seal stamp) must never block input: keep `allowsHitTesting(false)` and let them dismiss themselves.

### Stroke Grading Algorithm (`StrokeGrader`)

The grader resamples both user and reference strokes to 16 equidistant points (arc-length resampling) then computes mean point-to-point distance. It checks the stroke both forwards and backwards to detect reversed direction:

- Mean distance ≤ 145 units → `.correct`
- Reversed mean distance ≤ 145 units → `.wrongDirection`
- Neither → `.wrongStroke`
- Stroke length < 50 units → `.tooShort`

A `leniency` multiplier (1.0 strict / 1.6 lenient) scales all thresholds. All thresholds live in `StrokeGrader.Config` — adjust there, not inline.

### Coordinate Systems

All stroke geometry (SVG paths, reference medians, grading math) operates in a **1024×1024 glyph box** space. `GlyphMetrics` handles conversion between this space and the actual on-screen canvas bounds. Never mix coordinate spaces without going through `GlyphMetrics`.

### Data Sources

Stroke geometry (SVG paths + medians) is bundled locally — no network dependency:

- **Primary:** `StrokeData.sqlite` (46 MB) — SQLite with schema `character_strokes(glyph TEXT PRIMARY KEY, strokes_json TEXT, medians_json TEXT)`
- **Fallback:** `StrokeData.json` (44 KB) — activated automatically when the database is unavailable
- **Attribution:** Make Me a Hanzi / hanzi-writer-data (LGPL / Arphic License)

`StrokeReference` caches loaded glyphs in memory to avoid repeated DB queries.

### Design Tokens (`DesignTokens.swift`)

Always use `InkTheme` constants — never use raw color values or system colors.
Every token is **appearance-adaptive**: it carries both a light and a dark value
and resolves automatically per trait collection, so views never branch on
`colorScheme`. Tokens are built from `UIColor.inkAdaptive(light:dark:)` (a
dynamic `UIColor`) and exposed as SwiftUI `Color`s.

```swift
//                    light      dark      role
InkTheme.accent   //  #c8492f   #e15d42   vermilion — primary accent
InkTheme.paper    //  #f7f4ee   #17150f   app background
InkTheme.ink      //  #2b2925   #f4efe6   primary text & strong fills
InkTheme.onInk    //  #ffffff   #17150f   content sitting on an `ink` fill
InkTheme.ink2     //  #6b665d   #b8b1a3   secondary text
InkTheme.ink3     //  #9a948a   #8a8376   tertiary / muted text
InkTheme.line     //  #e7e2d8   #39342b   borders
InkTheme.line2    //  #efebe2   #2a261f   dividers / track / chip bg
InkTheme.card     //  #fffdf9   #211d17   card surfaces
InkTheme.jade     //  #1f6f6b   #3fa39d   secondary deck accent
InkTheme.sun      //  #9a6a2f   #c89a5a   alternate deck accent
```

Key rule: a filled button uses `.background(InkTheme.ink)` paired with
`.foregroundColor(InkTheme.onInk)` — **never** a hardcoded `.white`, which
disappears against the light `ink` fill in Dark Mode. `.white` is only correct
on saturated accent/deck-color fills. For PencilKit (which needs a `UIColor`,
not a `Color`), use `InkTheme.inkUI`.

**Appearance preference:** `AppAppearance` (System / Light / Dark) is persisted
via `AppSettings.Key.appearance`, edited in `SettingsView`, and applied app-wide
through `.preferredColorScheme(_:)` on `ContentView`'s root.

Typography: `.inkSerif()` for display/headings, `.inkSans()` for UI/body.

### SwiftData Models

`CharacterProgress` is the only `@Model` type. It is keyed on `@Attribute(.unique) var glyph: String`. Access it only through the SwiftData model context — do not hold raw references across context boundaries.

## Key Conventions

- **Modular SwiftUI views** with single responsibilities; state is lifted to `ContentView`
- **Stroke grading is pure Swift** — `StrokeGrader` has zero UIKit/PencilKit imports, making it straightforward to unit-test
- **`project.pbxproj` requires care** — verify all changes to Xcode project structure; accidental file reference corruption is hard to debug
- The `design_handoff_inkpath/` directory contains React/JSX design prototype reference files — it is **not production code** and should not be modified as part of app development
