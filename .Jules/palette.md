## 2024-07-15 - Missing ARIA/Accessibility Labels in Reusable View Builders
**Learning:** Reusable view builder functions for icon-only buttons (like `veilButton`) often miss accessibility labels because they lack textual context and are abstracted away from their specific usage.
**Action:** Always require an accessibility label parameter when extracting icon-only buttons into reusable components to ensure screen reader support.
## 2026-07-28 - Animate Character Completion Reward
**Learning:** Adding completion reward animations requires paying close attention to SwiftUI's `ZStack` and modifiers. Scale effects (like the hanko stamp) can be cleanly conditionalized on `isDone` with appropriate environmental awareness for reduced motion (`reduceMotion`).
**Action:** Always conditionally animate scaling effects and check `accessibilityReduceMotion` when creating UX-reward moments.
## 2024-07-22 - Adding Call-To-Action in Empty State

**Learning:** When displaying empty states (e.g., due to active searches or filters returning no results), it improves UX to provide a one-tap action (e.g., "Clear filters") allowing the user to reset their view easily without modifying multiple inputs.
**Action:** When working on lists/tables with filtering and search, look for empty state views and verify if a reset action exists; if not, add it.
## 2024-10-24 - Search/Input Clear Buttons and Submission Support
**Learning:** TextFields intended for immediate input/search (like custom practice input) often lack easy ways to clear their contents on mobile/touch interfaces, or fail to support keyboard submission (Return key).
**Action:** When implementing text fields for searches or direct inputs, wrap the `TextField` in an `HStack`, add a conditional clear button (`xmark.circle.fill`) with an accessibility label when the text is not empty, and use the `.onSubmit` modifier to improve mobile and keyboard usability.
