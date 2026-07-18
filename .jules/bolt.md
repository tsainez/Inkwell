## 2026-02-21 - [Caching Computed Properties in Swift]
**Learning:** [Computed properties in Swift, such as array-to-dictionary transformations, re-execute entirely on every access. This can turn O(1) lookups into O(N) operations inside loops, leading to O(N * M) overall time complexity.]
**Action:** [Store computed maps/dictionaries in a local variable outside loops when they only depend on constant state, effectively resolving performance bottlenecks without complex architectural changes.]
## 2024-05-18 - Dictionary lookup for SwiftData queries
**Learning:** Performing a linear search using `.first(where:)` on an array returned by a SwiftData `@Query` inside a loop leads to O(N*M) performance overhead.
**Action:** Always pre-calculate a dictionary mapping of a unique property (like `glyph`) to the SwiftData model instance in O(N) time before iterating over results that require O(1) matching in O(M) loop time.
