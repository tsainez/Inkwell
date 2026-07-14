## 2026-02-21 - [Caching Computed Properties in Swift]
**Learning:** [Computed properties in Swift, such as array-to-dictionary transformations, re-execute entirely on every access. This can turn O(1) lookups into O(N) operations inside loops, leading to O(N * M) overall time complexity.]
**Action:** [Store computed maps/dictionaries in a local variable outside loops when they only depend on constant state, effectively resolving performance bottlenecks without complex architectural changes.]
