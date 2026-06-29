# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

**Inkwell** is an iPad-first SwiftUI app for practicing Chinese and Japanese character handwriting (Hanzi/Kanji) with real-time stroke order, direction, and form recognition. It targets iPadOS 17+ with Apple Pencil support via PencilKit.

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

Always use `InkTheme` constants — never use raw color values or system colors:

```swift
InkTheme.accent   // #c8492f  vermilion — primary actions
InkTheme.paper    // #f7f4ee  background
InkTheme.ink      // #2b2925  primary text
InkTheme.ink2     // #6b665d  secondary text
InkTheme.jade     // #1f6f6b  secondary accent
InkTheme.card     // #fffdf9  card surfaces
InkTheme.line     // #e7e2d8  borders
```

Typography: `.inkSerif()` for display/headings, `.inkSans()` for UI/body.

### SwiftData Models

`CharacterProgress` is the only `@Model` type. It is keyed on `@Attribute(.unique) var glyph: String`. Access it only through the SwiftData model context — do not hold raw references across context boundaries.

## Key Conventions

- **Modular SwiftUI views** with single responsibilities; state is lifted to `ContentView`
- **Stroke grading is pure Swift** — `StrokeGrader` has zero UIKit/PencilKit imports, making it straightforward to unit-test
- **`project.pbxproj` requires care** — verify all changes to Xcode project structure; accidental file reference corruption is hard to debug
- The `design_handoff_inkpath/` directory contains React/JSX design prototype reference files — it is **not production code** and should not be modified as part of app development
