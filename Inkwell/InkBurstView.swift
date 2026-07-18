//
//  InkBurstView.swift
//  Inkwell
//
//  The streak surprise: when a run of correct strokes hits a milestone, a
//  vermilion hanko-style seal slams onto the writing pad and a burst of ink
//  droplets scatters out from under it, then the whole thing fades away on its
//  own (~1.8 s). It never blocks input — hit testing is disabled — so the user
//  can keep writing straight through it.
//
//  With Reduce Motion enabled the droplets are skipped and the seal simply
//  fades in and out.
//

import SwiftUI

struct InkBurstView: View {
    /// The streak count being celebrated, shown on the seal.
    let streak: Int
    /// Called once the celebration has fully faded; the owner clears its state.
    let onFinished: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    @State private var stamped = false
    @State private var fadingOut = false
    // @State so the random layout is generated once per celebration and stays
    // stable across parent re-renders while the droplets are mid-flight.
    @State private var droplets: [InkDroplet] = InkDroplet.scatter(count: 22)

    var body: some View {
        ZStack {
            if !reduceMotion {
                ForEach(droplets) { droplet in
                    Circle()
                        .fill(droplet.color)
                        .frame(width: droplet.size, height: droplet.size)
                        .scaleEffect(stamped ? droplet.endScale : 0.4)
                        .offset(stamped ? droplet.destination : .zero)
                        .animation(.easeOut(duration: droplet.duration).delay(droplet.delay), value: stamped)
                        .opacity(stamped ? 0 : 0.85)
                        .animation(.easeIn(duration: droplet.duration).delay(droplet.delay + 0.15), value: stamped)
                }
            }

            sealBadge
        }
        .opacity(fadingOut ? 0 : 1)
        .animation(.easeIn(duration: 0.35), value: fadingOut)
        .allowsHitTesting(false)
        .onAppear { stamped = true }
        .task {
            try? await Task.sleep(nanoseconds: 1_400_000_000)
            fadingOut = true
            try? await Task.sleep(nanoseconds: 400_000_000)
            onFinished()
        }
    }

    private var sealBadge: some View {
        VStack(spacing: 2) {
            Text("\(streak)")
                .font(.inkSerif(size: 44, weight: .bold))
            Text("IN A ROW")
                .font(.inkSans(size: 11, weight: .bold))
                .tracking(1.6)
        }
        // .white is correct here: this sits on the saturated accent fill.
        .foregroundColor(.white)
        .frame(width: 116, height: 116)
        .background(RoundedRectangle(cornerRadius: 18).fill(InkTheme.accent))
        .overlay(
            // Inner keyline, like the carved border of a real seal.
            RoundedRectangle(cornerRadius: 13)
                .inset(by: 6)
                .stroke(Color.white.opacity(0.55), lineWidth: 1.5)
        )
        .shadow(color: InkTheme.shadow, radius: 14, x: 0, y: 8)
        .rotationEffect(.degrees(stamped ? -6 : 8))
        .scaleEffect(stamped || reduceMotion ? 1 : 2.3)
        .opacity(stamped ? 1 : 0)
        .animation(
            reduceMotion
                ? .easeOut(duration: 0.25)
                : .spring(response: 0.32, dampingFraction: 0.62),
            value: stamped
        )
    }
}

/// One flying ink droplet: a randomized direction, distance, and timing, fixed
/// at creation so the animation has stable targets.
private struct InkDroplet: Identifiable {
    let id = UUID()
    let color: Color
    let size: CGFloat
    let destination: CGSize
    let duration: Double
    let delay: Double
    let endScale: CGFloat

    static func scatter(count: Int) -> [InkDroplet] {
        // Mostly vermilion with the occasional jade/sun fleck, like mixed inks.
        let palette: [Color] = [InkTheme.accent, InkTheme.accent, InkTheme.accent, InkTheme.jade, InkTheme.sun]
        return (0..<count).map { index in
            let angle = Double.random(in: 0..<(2 * .pi))
            let distance = CGFloat.random(in: 70...190)
            return InkDroplet(
                color: palette[index % palette.count],
                size: .random(in: 5...14),
                destination: CGSize(width: CGFloat(cos(angle)) * distance,
                                    height: CGFloat(sin(angle)) * distance - 16),
                duration: .random(in: 0.55...0.9),
                delay: .random(in: 0...0.08),
                endScale: .random(in: 0.2...0.6)
            )
        }
    }
}

#Preview {
    ZStack {
        InkTheme.paper.ignoresSafeArea()
        InkBurstView(streak: 10, onFinished: {})
    }
}
