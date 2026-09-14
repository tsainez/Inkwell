## 2024-05-24 - Bulk SQLite Inserts in Python
**Learning:** Accumulating data in Python memory (e.g. lists of tuples) and calling `cursor.executemany()` is significantly faster than executing N+1 individual `cursor.execute()` statements in a loop for SQLite, due to reduced I/O overhead.
**Action:** Use `cursor.executemany` for bulk insert/update operations in Python scripts instead of looping N times over single execute statements.
## 2026-02-21 - [Caching Computed Properties in Swift]
**Learning:** [Computed properties in Swift, such as array-to-dictionary transformations, re-execute entirely on every access. This can turn O(1) lookups into O(N) operations inside loops, leading to O(N * M) overall time complexity.]
**Action:** [Store computed maps/dictionaries in a local variable outside loops when they only depend on constant state, effectively resolving performance bottlenecks without complex architectural changes.]
## 2024-05-18 - Dictionary lookup for SwiftData queries
**Learning:** Performing a linear search using `.first(where:)` on an array returned by a SwiftData `@Query` inside a loop leads to O(N*M) performance overhead.
**Action:** Always pre-calculate a dictionary mapping of a unique property (like `glyph`) to the SwiftData model instance in O(N) time before iterating over results that require O(1) matching in O(M) loop time.

## 2024-05-24 - [Performance] Cache Expensive Results & Fast Math
**Learning:** Found O(N) operations (like curve resampling and deduplication) being redundantly executed multiple times inside loops because helper functions didn't reuse intermediate structs. Also noticed `hypot` introduces unnecessary overhead for standard iOS UI coordinates where overflow isn't a risk.
**Action:** Always check loop bodies for function calls that re-evaluate the same state. Pass intermediate calculation results (like `FitResult` enums) to helper functions instead of discarding them. Replace `hypot` with standard square root multiplication for basic UI distance math.
## 2024-05-24 - [Caching Computed Properties in SwiftUI]
**Learning:** [Computed properties in Swift, such as array-to-dictionary transformations, re-execute entirely on every access. Inside a `LazyVStack` and `ForEach`, accessing a computed property (like `progressMap`) repeatedly for every row as it comes on-screen can result in that property being re-evaluated N times. This can turn O(1) lookups into O(N) operations inside loops, leading to O(N^2) rendering bottlenecks.]
**Action:** [Cache computationally expensive computed properties into a local variable before using them inside a `ForEach` or `LazyVStack`. This prevents O(N) properties from being continuously re-evaluated.]

## 2024-05-24 - Prevent O(N) evaluation inside computed properties
**Learning:** In SwiftUI, evaluating expensive O(N) properties (e.g. `allCharacters` flattening, or `totalMasteredCount` which iterates array items) repeatedly in computed properties slows down rendering severely. Every subview that references these properties can cause an independent O(N) evaluation.
**Action:** Extract expensive data processing into functions (`func getFilteredCharacters(...)`) that take cached maps and arrays as parameters. Inside the `body` view, fetch the dependencies (like `progressMap` or `allCharacters`), store them in local variables (`let cachedMap = ...`), process them once, and pass the results manually to subviews. This changes multiple O(N) operations to evaluate only once per render pass.
