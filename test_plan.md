1. **Create `HeaderBar.swift` in `Inkwell/`**
   - Extract the `headerBar` implementation from `CharacterTableView.swift` and `SettingsView.swift` into a reusable `HeaderBar` struct.
   - It will take `title: String`, `subtitle: String`, and an `onBack: () -> Void` closure as properties.
2. **Update `CharacterTableView.swift`**
   - Replace the `private var headerBar` implementation with the usage of the new `HeaderBar` component: `HeaderBar(title: "Character Mastery Table", subtitle: "PROGRESS TRACKER", onBack: onBack)`.
3. **Update `SettingsView.swift`**
   - Replace the `private var headerBar` implementation with the usage of the new `HeaderBar` component: `HeaderBar(title: "Settings", subtitle: "PREFERENCES", onBack: onBack)`.
4. **Complete pre-commit steps to ensure proper testing, verification, review, and reflection are done.**
5. **Submit the change.**
