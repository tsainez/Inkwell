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
    }

    // MARK: - Defaults

    static let defaultStrictGrading = false
    static let defaultGridStyle = GuideGridStyle.rice
    static let defaultHintThreshold = 3

    /// Allowed range for "wrong strokes before the next stroke is highlighted".
    static let hintThresholdRange = 1...6
}

extension GuideGridStyle {
    /// Resolve a stored raw value back to a style, falling back to the default.
    init(storedRawValue: String) {
        self = GuideGridStyle(rawValue: storedRawValue) ?? AppSettings.defaultGridStyle
    }
}
