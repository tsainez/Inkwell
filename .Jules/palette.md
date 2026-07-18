## 2024-07-15 - Missing ARIA/Accessibility Labels in Reusable View Builders
**Learning:** Reusable view builder functions for icon-only buttons (like `veilButton`) often miss accessibility labels because they lack textual context and are abstracted away from their specific usage.
**Action:** Always require an accessibility label parameter when extracting icon-only buttons into reusable components to ensure screen reader support.
## 2026-07-28 - Animate Character Completion Reward
**Learning:** Adding completion reward animations requires paying close attention to SwiftUI's `ZStack` and modifiers. Scale effects (like the hanko stamp) can be cleanly conditionalized on `isDone` with appropriate environmental awareness for reduced motion (`reduceMotion`).
**Action:** Always conditionally animate scaling effects and check `accessibilityReduceMotion` when creating UX-reward moments.
