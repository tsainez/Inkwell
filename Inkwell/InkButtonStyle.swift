//
//  InkButtonStyle.swift
//  Inkwell
//
//  Shared press feedback for buttons: a gentle scale-down with a slight
//  opacity dip while pressed, released on a soft spring. Small enough to feel
//  tactile without drawing attention to itself. The scale is skipped under
//  Reduce Motion (the opacity dip alone still confirms the press).
//

import SwiftUI

struct InkPressButtonStyle: ButtonStyle {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var pressedScale: CGFloat = 0.96

    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed && !reduceMotion ? pressedScale : 1)
            .opacity(configuration.isPressed ? 0.85 : 1)
            .animation(.spring(response: 0.25, dampingFraction: 0.7), value: configuration.isPressed)
    }
}
