# Inkwell → App Store Readiness: Dark Mode & Liquid Glass Plan

A staged roadmap from "default-styled prototype" to a polished, App Store-ready
build that (a) ships a first-class Dark Mode, (b) complies with Apple's Liquid
Glass design system, and (c) can generate promotional material for the listing.

The phases are ordered so each one is independently shippable and testable.
Phase 1 is **implemented** in this branch; later phases are scoped but not yet
built.

---

## Guiding principles

- **One source of truth.** All color flows through `InkTheme` in
  `DesignTokens.swift`. No raw `Color.white` / system colors in views.
- **Adaptive, not branched.** Tokens resolve per-trait; views never read
  `colorScheme` directly.
- **Preserve the brand.** The "sumi ink on washi paper" identity carries into
  Dark Mode (warm near-black paper, warm off-white ink, vermilion seal accent).
- **Backwards compatible.** New SDK features (Liquid Glass) are gated behind
  `if #available(...)` so the current iPadOS 17 deployment target keeps working.

---

## Phase 1 — Dark Mode foundation ✅ (this branch)

The plumbing that makes everything else possible.

- **Adaptive token engine.** `UIColor.inkAdaptive(light:dark:)` builds dynamic
  colors; every `InkTheme` token now carries a light + dark value and resolves
  automatically. (`DesignTokens.swift`)
- **New semantic token `onInk`.** Content placed on an `ink` fill. Fixes the
  core bug where filled buttons hardcoded `.white` text — invisible against the
  light `ink` fill in Dark Mode. All such buttons now use `onInk`.
- **PencilKit ink follows appearance.** `PencilCanvasView` uses the dynamic
  `InkTheme.inkUI` so wet ink is dark-on-light / light-on-dark.
- **User appearance preference.** `AppAppearance` (System / Light / Dark),
  persisted via `AppSettings`, surfaced as a Settings → Appearance segmented
  control, applied app-wide through `.preferredColorScheme` on `ContentView`.
- **Guardrail tests.** `DesignTokenTests` assert tokens actually resolve
  differently per appearance and that the appearance enum maps correctly.

**Exit criteria:** app is fully legible in Dark Mode; theme toggle works; tests
pass in CI.

---

## Phase 2 — Dark Mode polish 🔧 (in progress)

Make Dark Mode look *designed*, not merely inverted.

- ✅ **Deck accent adaptation.** Added an adaptive `CharacterDeck.accent` (mapped
  through `InkTheme`) so deck bars/progress/arrows use the brightened dark
  variants. The legacy `accentColor` hex string is kept for compatibility.
- ✅ **Adaptive elevation.** New `InkTheme.shadow` token (alpha baked per mode):
  near-invisible in light, a soft grounding in dark. Replaces the hardcoded
  `Color.black.opacity(...)` shadows on every card/pad. Depth in dark is carried
  mainly by the `card`-over-`paper` surface tint.
- ✅ **Reference-glyph contrast.** New `InkTheme.glyphGhost` token gives the faint
  traced glyph a touch more presence on the dark pad (used by `GlyphOutlineView`
  and the no-data fallback).
- ✅ **Guide-grid tuning.** New `InkTheme.guide` token: the dashed cross + rice
  diagonals keep presence on the dark pad (brighter alpha in dark) without glare
  in light.
- ✅ **Branded system controls.** Populated the (previously empty) `AccentColor`
  asset with adaptive vermilion and set `.tint(InkTheme.accent)` at the root, so
  text cursors, selection, the hint `Stepper`, the Sort menu, and the reset
  `Alert` use the brand color instead of falling back to iOS blue.
- ✅ **Root paper backdrop.** `.background(InkTheme.paper)` on the root prevents a
  system-black flash behind screen transitions.
- ✅ **Launch screen.** Auto-generated launch screen uses the adaptive system
  background — a Dark-mode device gets a dark launch, no white flash.
- ⏳ **App icon.** `AppIcon` declares light/dark/tinted slots but has no image
  files yet — needs artwork before submission (an asset task, not a runtime bug).
- ⏳ **Ambient background wash.** Optional subtle gradient/paper-texture behind
  `paper` for warmth in both modes.
- ⏳ **Asset-catalog option.** Evaluate migrating tokens to `.xcassets` Color Sets
  for designer-friendly editing + native Previews. (Trade-off: touches
  `project.pbxproj`; the code-token approach is currently preferred per
  `CLAUDE.md`.)

**Exit criteria:** side-by-side light/dark screenshots look intentional on every
screen.

---

## Phase 3 — Liquid Glass compliance

Adopt Apple's Liquid Glass material system (iOS/iPadOS 26 SDK, Xcode 26).
**Gated behind availability checks** to preserve the iPadOS 17 target.

- **Toolchain.** Bump CI to Xcode 26; build against the iOS 26 SDK while keeping
  the deployment target. Update `.github/workflows/swift.yml` and `CLAUDE.md`.
- **Navigation & controls.** Let standard bars/controls pick up Liquid Glass
  automatically by linking the new SDK; audit custom chrome (the hand-rolled
  header bars in Practice/Settings/Table) for the new look.
- **Glass surfaces.** Apply `.glassEffect()` / `GlassEffectContainer` to
  floating elements — the practice controls row, the custom-practice panel,
  the "Character of the Day" card, session-complete card.
- **Glass buttons.** Migrate primary actions to `.buttonStyle(.glass)` /
  `.glassProminent` where appropriate; keep `ink`/`onInk` as the fallback path.
- **Edge treatments.** Adopt scroll-edge effects and
  `backgroundExtensionEffect` so content flows under the glass chrome.
- **Concentric corners.** Use the new concentric corner APIs so nested rounded
  rectangles (cards within cards) align correctly.
- **Reduce Transparency / Reduce Motion.** Ensure glass degrades to solid
  surfaces when these accessibility settings are on.

**Exit criteria:** builds on Xcode 26, looks native on iPadOS 26, and still runs
on iPadOS 17 with graceful fallbacks.

---

## Phase 4 — Promotional material pipeline

Automate generation of the visual assets used on the App Store listing and for
demonstrating the app.

- **Deterministic demo state.** A launch argument / build config that seeds
  predictable progress, streaks, and a curated deck so marketing shots are
  consistent and flattering (no empty states).
- **Screenshot harness.** An XCUITest target that drives the app to each key
  screen (Library, Practice mid-stroke, Mastery Table, Session Complete,
  Settings) and captures screenshots at the required App Store device sizes
  (12.9" iPad Pro, 11" iPad, etc.), in both light and dark.
- **Marketing frames.** Compose captured screenshots into framed, captioned
  "hero" images (device bezel + tagline) — drives the promotional set.
- **App preview video (optional).** Scripted UI walkthrough recorded from the
  simulator for the 15–30s App Store preview.
- **Copy & metadata.** Listing title/subtitle, keywords, description, and
  per-screenshot captions, kept in-repo for review.
- **Localization-ready.** Structure captions/strings so shots can be regenerated
  per locale.

**Exit criteria:** `one command → full set of store-ready screenshots` (light +
dark, all device classes) plus draft listing copy.

---

## Cross-cutting: accessibility & QA

Tracked across all phases, blocking for release.

- **Contrast.** Verify WCAG-adequate contrast for text tokens on their surfaces
  in both appearances.
- **Dynamic Type.** Audit the many fixed `.system(size:)` fonts; move toward
  scalable text where feasible.
- **VoiceOver.** Labels for icon-only controls (some exist, e.g. Settings gear;
  audit the rest).
- **Reduce Transparency / Increase Contrast / Reduce Motion** honored,
  especially once glass + animations land.
- **CI.** Keep the test matrix green; add snapshot/screenshot checks once the
  Phase 4 harness exists.

---

## Status summary

| Phase | Scope | Status |
|------:|-------|--------|
| 1 | Dark Mode foundation (tokens, `onInk`, appearance setting, PencilKit ink, tests) | ✅ Implemented |
| 2 | Dark Mode polish (deck accents, elevation, glyph contrast done; grid/icon/launch remain) | 🔧 In progress |
| 3 | Liquid Glass adoption (Xcode 26 SDK, glass surfaces/buttons, edge effects) | ⏳ Planned |
| 4 | Promotional material pipeline (demo state, screenshot harness, copy) | ⏳ Planned |
| — | Accessibility & QA | 🔁 Ongoing |
