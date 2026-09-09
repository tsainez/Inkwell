## 2024-07-15 - Missing ARIA/Accessibility Labels in Reusable View Builders
**Learning:** Reusable view builder functions for icon-only buttons (like `veilButton`) often miss accessibility labels because they lack textual context and are abstracted away from their specific usage.
**Action:** Always require an accessibility label parameter when extracting icon-only buttons into reusable components to ensure screen reader support.
## 2026-07-28 - Animate Character Completion Reward
**Learning:** Adding completion reward animations requires paying close attention to SwiftUI's `ZStack` and modifiers. Scale effects (like the hanko stamp) can be cleanly conditionalized on `isDone` with appropriate environmental awareness for reduced motion (`reduceMotion`).
**Action:** Always conditionally animate scaling effects and check `accessibilityReduceMotion` when creating UX-reward moments.
## 2024-07-22 - Adding Call-To-Action in Empty State

**Learning:** When displaying empty states (e.g., due to active searches or filters returning no results), it improves UX to provide a one-tap action (e.g., "Clear filters") allowing the user to reset their view easily without modifying multiple inputs.
**Action:** When working on lists/tables with filtering and search, look for empty state views and verify if a reset action exists; if not, add it.
## 2024-11-20 - Adding isSelected trait to custom segmented controls
**Learning:** Custom segmented controls or horizontal selection lists built using basic `Button` views in SwiftUI do not automatically announce their active selection state to screen readers, leaving VoiceOver users unsure of which option is currently active.
**Action:** Always add `.accessibilityAddTraits(isSelected ? .isSelected : [])` to custom toggle/selection buttons built outside of native Pickers.
