#!/usr/bin/env python3
"""
generate_ids_fallback.py
------------------------
Generates Inkwell/IDS_fallback.json — the compact decomposition table used by
IDSDecomposer.swift to synthesize stroke data for CJK characters that are
missing from StrokeData.sqlite.

Requirements:
    pip install hanzipy

Usage:
    python3 scripts/generate_ids_fallback.py

The script:
  1. Reads every glyph already in StrokeData.sqlite.
  2. Parses the spatial-decomposition table shipped by hanzipy (cjk_decomp.txt).
  3. Keeps only basic-CJK characters (U+4E00–U+9FFF) that:
       - are NOT already in the DB
       - decompose into exactly 2 components via a spatial operator
       - have BOTH components present in the DB (so medians can be retrieved)
  4. Writes the result as a compact JSON map:
       { "<char>": { "op": "lr"|"tb", "parts": ["<A>", "<B>"] }, ... }

Spatial operators mapped:
    "lr" (left-right)  ← a, stl, sbl, sl, str
    "tb" (top-bottom)  ← d, st, sb
"""

import sqlite3, json, re
from pathlib import Path

REPO_ROOT   = Path(__file__).resolve().parent.parent
DB_PATH     = REPO_ROOT / "Inkwell" / "StrokeData.sqlite"
DECOMP_PATH = None   # located from installed hanzipy package automatically
OUT_PATH    = REPO_ROOT / "Inkwell" / "IDS_fallback.json"

# --- locate cjk_decomp.txt from the installed hanzipy package ---
try:
    import hanzipy as _h
    DECOMP_PATH = Path(_h.__file__).parent / "data" / "cjk_decomp.txt"
except ImportError:
    raise SystemExit("hanzipy not installed. Run: pip install hanzipy")

if not DECOMP_PATH.exists():
    raise SystemExit(f"cjk_decomp.txt not found at {DECOMP_PATH}")

# Spatial operators that map to a 2-part left-right or top-bottom split
SPATIAL_OPS = {
    'a':   'lr',   # left-right (⿰)
    'd':   'tb',   # top-bottom (⿱)
    'st':  'tb',   # surround from top → approx top-bottom
    'stl': 'lr',   # surround from top-left → approx left-right
    'sbl': 'lr',   # surround from bottom-left → approx left-right
    'sl':  'lr',   # surround from left → approx left-right
    'str': 'lr',   # surround from top-right → approx left-right
    'sb':  'tb',   # surround from bottom → approx top-bottom
}

def main():
    # 1. Glyphs in DB
    con = sqlite3.connect(str(DB_PATH))
    in_db = {row[0] for row in con.execute("SELECT glyph FROM character_strokes").fetchall()}
    con.close()
    print(f"Glyphs in StrokeData.sqlite : {len(in_db):,}")

    # 2. Parse decomposition file
    decomp_map: dict[str, dict] = {}
    with open(DECOMP_PATH, encoding='utf-8') as f:
        for line in f:
            line = line.strip()
            if not line:
                continue
            sep = line.index(':')
            ch = line[:sep]
            rest = line[sep + 1:]
            m = re.match(r'([^(/]+)(?:/[^(]+)?\((.+)\)', rest)
            if not m:
                continue
            op_raw = m.group(1)
            if op_raw not in SPATIAL_OPS:
                continue
            parts = [p.strip() for p in m.group(2).split(',') if p.strip()]
            # Require exactly 2 single-character components (no numeric back-refs)
            if len(parts) != 2:
                continue
            if any(p.isdigit() or not p for p in parts):
                continue
            decomp_map[ch] = {'op': SPATIAL_OPS[op_raw], 'parts': parts}

    print(f"Spatial decompositions found: {len(decomp_map):,}")

    # 3. Filter to synthesizable missing glyphs in the basic CJK block
    results: dict[str, dict] = {}
    for cp in range(0x4E00, 0x9FFF + 1):
        ch = chr(cp)
        if ch in in_db:
            continue
        if ch not in decomp_map:
            continue
        entry = decomp_map[ch]
        if all(p in in_db for p in entry['parts']):
            results[ch] = entry

    # 4. Write compact JSON
    OUT_PATH.parent.mkdir(parents=True, exist_ok=True)
    with open(OUT_PATH, 'w', encoding='utf-8') as f:
        json.dump(results, f, ensure_ascii=False, separators=(',', ':'))

    size_kb = OUT_PATH.stat().st_size / 1024
    print(f"Synthesizable missing chars : {len(results):,}")
    print(f"Written to                  : {OUT_PATH}  ({size_kb:.1f} KB)")

if __name__ == '__main__':
    main()
