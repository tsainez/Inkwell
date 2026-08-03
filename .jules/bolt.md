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
## 2024-05-24 - [Caching Method Calls in SwiftUI]
**Learning:** [Calling an expensive method like `buildCustomDeck()` multiple times directly within a view's `body` property (e.g. for `disabled`, `opacity`, and `if let` blocks) causes redundant O(N) operations and object allocations on every render pass.]
**Action:** [Store the result of expensive method calls in a local variable at the top of the view's `body` property to ensure they are only computed once per render pass.]
