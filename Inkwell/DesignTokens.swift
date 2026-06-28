//
//  DesignTokens.swift
//  Inkwell
//

import SwiftUI

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

struct InkTheme {
    static let accent = Color(hex: "#c8492f")      // vermilion
    static let paper = Color(hex: "#f7f4ee")       // app background
    static let ink = Color(hex: "#2b2925")         // primary text / dark elements
    static let ink2 = Color(hex: "#6b665d")        // secondary text
    static let ink3 = Color(hex: "#9a948a")        // tertiary / muted text
    static let line = Color(hex: "#e7e2d8")        // borders
    static let line2 = Color(hex: "#efebe2")       // dividers / track bg
    static let card = Color(hex: "#fffdf9")        // card surfaces
    static let jade = Color(hex: "#1f6f6b")        // secondary deck accent
    static let sun = Color(hex: "#9a6a2f")         // alternate deck accent
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
