//
//  DesignTokens.swift
//  Inkwell
//
//  Single source of truth for color and typography. Every color is defined as
//  an *adaptive* token that resolves to a light value in Light Mode and a dark
//  value in Dark Mode, so views never have to branch on `colorScheme` — they
//  just use `InkTheme.x` and the system picks the right shade per trait.
//
//  The palette keeps Inkwell's "sumi ink on washi paper" identity in both
//  appearances: warm off-white paper in light, warm near-black in dark, with
//  the vermilion seal accent carried across (slightly brightened for dark so it
//  stays legible against the deep background).
//

import SwiftUI
import UIKit

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}

extension UIColor {
    /// A color that resolves to `light` in Light Mode and `dark` in Dark Mode.
    /// Both arguments are hex strings parsed via `Color(hex:)`. The returned
    /// `UIColor` is dynamic, so it re-resolves automatically whenever the
    /// surrounding trait collection's `userInterfaceStyle` changes.
    static func inkAdaptive(_ light: String, _ dark: String) -> UIColor {
        UIColor { traits in
            UIColor(Color(hex: traits.userInterfaceStyle == .dark ? dark : light))
        }
    }
}

struct InkTheme {
    // UIKit-resolvable source of truth for the primary ink. PencilKit needs a
    // `UIColor` (not a SwiftUI `Color`) for the pen tool, and keeping it dynamic
    // means the wet ink tracks the active appearance.
    static let inkUI = UIColor.inkAdaptive("#2b2925", "#f4efe6")

    // Token                                  light        dark
    static let accent = Color(uiColor: .inkAdaptive("#c8492f", "#e15d42"))   // vermilion — primary accent
    static let paper  = Color(uiColor: .inkAdaptive("#f7f4ee", "#17150f"))   // app background
    static let ink    = Color(uiColor: inkUI)                                // primary text & strong fills
    static let onInk  = Color(uiColor: .inkAdaptive("#ffffff", "#17150f"))   // content sitting on an `ink` fill
    static let ink2   = Color(uiColor: .inkAdaptive("#6b665d", "#b8b1a3"))   // secondary text
    static let ink3   = Color(uiColor: .inkAdaptive("#9a948a", "#8a8376"))   // tertiary / muted text
    static let line   = Color(uiColor: .inkAdaptive("#e7e2d8", "#39342b"))   // borders
    static let line2  = Color(uiColor: .inkAdaptive("#efebe2", "#2a261f"))   // dividers / track / chip bg
    static let card   = Color(uiColor: .inkAdaptive("#fffdf9", "#211d17"))   // card surfaces
    static let jade   = Color(uiColor: .inkAdaptive("#1f6f6b", "#3fa39d"))   // secondary deck accent
    static let sun    = Color(uiColor: .inkAdaptive("#9a6a2f", "#c89a5a"))   // alternate deck accent
}

extension Font {
    // Custom typography tokens matching Newsreader (serif display) and Hanken Grotesk / SF Pro (UI)
    static func inkSerif(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .serif)
    }

    static func inkSans(size: CGFloat, weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .default)
    }
}
