#!/usr/bin/env python3
"""Generate Inkwell's app icon set from the bundled stroke database.

The icon shows 永 ("eternity") mid-writing — the character calligraphers use
to practice, since its strokes cover all the basic stroke techniques (the
"Eight Principles of Yong"). Stroke 1 (the dot) is fully inked in vermilion,
like a fresh seal impression; each following stroke fades until the last is
nearly invisible, as if the ink hasn't touched the paper yet.

Outputs the three iOS 18 appearance variants into AppIcon.appiconset:
  - light:  opaque washi-paper background (App Store marketing icon; no alpha)
  - dark:   transparent background (the system supplies the dark gradient)
  - tinted: grayscale on transparent (the system applies the tint color)

Usage:  python3 scripts/generate_app_icon.py   (from the repo root)
Needs:  pip install cairosvg
"""

import json
import sqlite3
from pathlib import Path

import cairosvg

REPO = Path(__file__).resolve().parent.parent
DB = REPO / "Inkwell" / "StrokeData.sqlite"
ICONSET = REPO / "Inkwell" / "Assets.xcassets" / "AppIcon.appiconset"

GLYPH = "永"
CANVAS = 1024          # icon pixel size and glyph em size
GLYPH_SCALE = 0.76     # glyph size relative to the canvas
BASELINE = 900         # stroke data is y-up with the baseline at y = 900

# Per-stroke opacity: first stroke fully inked, last one barely there.
FADE_FROM, FADE_TO = 1.0, 0.16

VARIANTS = {
    # name      background   dot (stroke 1)  ink (later strokes)
    "light":  ("#f7f4ee",    "#c8492f",      "#2b2925"),
    "dark":   (None,         "#e15d42",      "#f4efe6"),
    "tinted": (None,         "#ffffff",      "#ffffff"),
}


def stroke_paths() -> list[str]:
    db = sqlite3.connect(DB)
    row = db.execute(
        "SELECT strokes_json FROM character_strokes WHERE glyph = ?", (GLYPH,)
    ).fetchone()
    if row is None:
        raise SystemExit(f"glyph {GLYPH!r} not found in {DB}")
    return json.loads(row[0])


def opacity(index: int, total: int) -> float:
    if total <= 1:
        return FADE_FROM
    return FADE_FROM + (FADE_TO - FADE_FROM) * index / (total - 1)


def build_svg(strokes: list[str], background: str | None,
              dot_color: str, ink_color: str) -> str:
    parts = [
        f'<svg xmlns="http://www.w3.org/2000/svg" '
        f'width="{CANVAS}" height="{CANVAS}" '
        f'viewBox="0 0 {CANVAS} {CANVAS}">'
    ]
    if background:
        parts.append(
            f'<rect width="{CANVAS}" height="{CANVAS}" fill="{background}"/>'
        )

    # Center the glyph at GLYPH_SCALE, then flip the y-up stroke data into
    # SVG's y-down space around its baseline (same math as GlyphMetrics).
    margin = CANVAS * (1 - GLYPH_SCALE) / 2
    parts.append(
        f'<g transform="translate({margin},{margin}) scale({GLYPH_SCALE}) '
        f'translate(0,{BASELINE}) scale(1,-1)">'
    )
    for i, d in enumerate(strokes):
        color = dot_color if i == 0 else ink_color
        parts.append(
            f'<path d="{d}" fill="{color}" fill-opacity="{opacity(i, len(strokes)):.3f}"/>'
        )
    parts.append("</g></svg>")
    return "".join(parts)


def main() -> None:
    strokes = stroke_paths()
    for name, (background, dot_color, ink_color) in VARIANTS.items():
        svg = build_svg(strokes, background, dot_color, ink_color)
        out = ICONSET / f"AppIcon-{name}.png"
        cairosvg.svg2png(
            bytestring=svg.encode(), write_to=str(out),
            output_width=CANVAS, output_height=CANVAS,
        )
        print(f"wrote {out.relative_to(REPO)}")


if __name__ == "__main__":
    main()
