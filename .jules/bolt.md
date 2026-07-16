## 2024-05-18 - Dictionary lookup for SwiftData queries
**Learning:** Performing a linear search using `.first(where:)` on an array returned by a SwiftData `@Query` inside a loop leads to O(N*M) performance overhead.
**Action:** Always pre-calculate a dictionary mapping of a unique property (like `glyph`) to the SwiftData model instance in O(N) time before iterating over results that require O(1) matching in O(M) loop time.
