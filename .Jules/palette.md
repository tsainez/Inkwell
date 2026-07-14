## 2026-07-28 - Animate Character Completion Reward
**Learning:** Adding completion reward animations requires paying close attention to SwiftUI's `ZStack` and modifiers. Scale effects (like the hanko stamp) can be cleanly conditionalized on `isDone` with appropriate environmental awareness for reduced motion (`reduceMotion`).
**Action:** Always conditionally animate scaling effects and check `accessibilityReduceMotion` when creating UX-reward moments.
