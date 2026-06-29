## 2024-05-30 - Avoid Array Insertion in Resample Loop
**Learning:** `resample` function in `StrokeGrader.swift` does `points.insert(q, at: i)` repeatedly. This is O(N) array shifting inside a loop, making resampling effectively O(N^2) for the number of input points. Resampling is the core operation done multiple times per stroke grading on main thread.
**Action:** Avoid mutating `points` array while iterating in `resample`.

## 2024-05-30 - O(N^2) Array Insertion in StrokeGrader
**Learning:** `resample` function in `StrokeGrader.swift` does `points.insert(q, at: i)` repeatedly in a while loop. Since `points` is an array of `CGPoint`, `insert` shifts all subsequent elements. This makes resampling an O(N^2) operation, and resampling is performed twice (user & median) for every `fit` check (which is called for matching best stroke too).
**Action:** Refactor `resample` to avoid inserting into the array it iterates over. We can just keep track of `prev` and `curr`, calculate the new interpolated point `q`, append `q` to `result`, and then update `prev = q` without modifying the original array or advancing the loop to `curr` yet. This changes the complexity from O(N^2) to O(N).
