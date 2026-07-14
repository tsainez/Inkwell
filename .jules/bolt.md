## 2024-05-24 - Bulk SQLite Inserts in Python
**Learning:** Accumulating data in Python memory (e.g. lists of tuples) and calling `cursor.executemany()` is significantly faster than executing N+1 individual `cursor.execute()` statements in a loop for SQLite, due to reduced I/O overhead.
**Action:** Use `cursor.executemany` for bulk insert/update operations in Python scripts instead of looping N times over single execute statements.
