import os
import json
import sqlite3

def build_database():
    db_path = "Inkwell/StrokeData.sqlite"
    if os.path.exists(db_path):
        os.remove(db_path)

    conn = sqlite3.connect(db_path)
    cursor = conn.cursor()
    cursor.execute("""
        CREATE TABLE character_strokes (
            glyph TEXT PRIMARY KEY,
            strokes_json TEXT NOT NULL,
            medians_json TEXT NOT NULL
        )
    """)

    added_glyphs = set()
    rows_to_insert = []

    # 1. Load from animCJK graphicsJa.txt (Japanese Kanji priority)
    ja_path = "scripts/animCJK/graphicsJa.txt"
    if os.path.exists(ja_path):
        with open(ja_path, "r", encoding="utf-8") as f:
            for line in f:
                line = line.strip()
                if not line:
                    continue
                try:
                    data = json.loads(line)
                    glyph = data.get("character")
                    strokes = data.get("strokes", [])
                    medians = data.get("medians", [])
                    if glyph and strokes and medians and glyph not in added_glyphs:
                        rows_to_insert.append((glyph, json.dumps(strokes), json.dumps(medians)))
                        added_glyphs.add(glyph)
                except Exception as e:
                    pass

    # 2. Load from hanzi-writer-data (Chinese Hanzi)
    hw_dir = "scripts/hanzi-writer-data/data"
    if os.path.exists(hw_dir):
        for fname in os.listdir(hw_dir):
            if fname.endswith(".json"):
                glyph = fname[:-5]
                if glyph in added_glyphs:
                    continue
                fpath = os.path.join(hw_dir, fname)
                try:
                    with open(fpath, "r", encoding="utf-8") as f:
                        data = json.load(f)
                        strokes = data.get("strokes", [])
                        medians = data.get("medians", [])
                        if strokes and medians:
                            rows_to_insert.append((glyph, json.dumps(strokes), json.dumps(medians)))
                            added_glyphs.add(glyph)
                except Exception as e:
                    pass

    # 3. Load from animCJK graphicsZhHans.txt & graphicsZhHant.txt for any remaining characters
    for zh_file in ["graphicsZhHans.txt", "graphicsZhHant.txt", "graphicsJaKana.txt"]:
        zh_path = os.path.join("scripts/animCJK", zh_file)
        if os.path.exists(zh_path):
            with open(zh_path, "r", encoding="utf-8") as f:
                for line in f:
                    line = line.strip()
                    if not line:
                        continue
                    try:
                        data = json.loads(line)
                        glyph = data.get("character")
                        strokes = data.get("strokes", [])
                        medians = data.get("medians", [])
                        if glyph and strokes and medians and glyph not in added_glyphs:
                            rows_to_insert.append((glyph, json.dumps(strokes), json.dumps(medians)))
                            added_glyphs.add(glyph)
                    except Exception as e:
                        pass

    if rows_to_insert:
        cursor.executemany(
            "INSERT INTO character_strokes (glyph, strokes_json, medians_json) VALUES (?, ?, ?)",
            rows_to_insert
        )

    conn.commit()
    cursor.execute("SELECT COUNT(*) FROM character_strokes")
    count = cursor.fetchone()[0]
    conn.close()

    db_size = os.path.getsize(db_path) / (1024 * 1024)
    print(f"Successfully built {db_path}")
    print(f"Total unique characters indexed: {count}")
    print(f"Database file size: {db_size:.2f} MB")

if __name__ == "__main__":
    build_database()
