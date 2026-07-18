//
//  AppSettings.swift
//  Inkwell
//
//  Central, persisted user preferences. Values are stored in `UserDefaults`
//  via SwiftUI's `@AppStorage`, so any view can read or bind to them with the
//  keys below and changes propagate automatically. SettingsView is the single
//  place these are edited; PracticeView reads them when a session begins.
//

import SwiftUI

enum AppSettings {
    /// UserDefaults keys. Namespaced so they never collide with other storage.
    enum Key {
        static let strictGrading = "settings.strictGrading"
        static let gridStyle = "settings.gridStyle"
        static let hintThreshold = "settings.hintThreshold"
        static let appearance = "settings.appearance"
        static let soundEffects = "settings.soundEffects"
    }

    // MARK: - Defaults

    static let defaultStrictGrading = false
    static let defaultGridStyle = GuideGridStyle.rice
    static let defaultHintThreshold = 3
    static let defaultAppearance = AppAppearance.system
    static let defaultSoundEffects = true

    /// Allowed range for "wrong strokes before the next stroke is highlighted".
    static let hintThresholdRange = 1...6
}

/// User-selectable app appearance. `system` defers to the device setting; the
/// other two pin the app to a single scheme regardless of the device.
enum AppAppearance: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var title: String {
        switch self {
        case .system: return "System"
        case .light:  return "Light"
        case .dark:   return "Dark"
        }
    }

    /// The value to feed `.preferredColorScheme(_:)`. `nil` means "follow the
    /// system", which is exactly what SwiftUI expects for the system option.
    var colorScheme: ColorScheme? {
        switch self {
        case .system: return nil
        case .light:  return .light
        case .dark:   return .dark
        }
    }

    /// Resolve a stored raw value back to an appearance, falling back to default.
    init(storedRawValue: String) {
        self = AppAppearance(rawValue: storedRawValue) ?? AppSettings.defaultAppearance
    }
}

extension GuideGridStyle {
    /// Resolve a stored raw value back to a style, falling back to the default.
    init(storedRawValue: String) {
        self = GuideGridStyle(rawValue: storedRawValue) ?? AppSettings.defaultGridStyle
    }
}
