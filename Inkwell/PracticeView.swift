//
//  PracticeView.swift
//  Inkwell
//

import SwiftUI
import PencilKit

struct SessionResultItem: Hashable {
    let glyph: String
    let mistakes: Int
    let skipped: Bool
}

struct PracticeView: View {
    let deck: CharacterDeck
    let onExit: ([SessionResultItem]) -> Void
    let onFinish: ([SessionResultItem]) -> Void

    @State private var currentIndex: Int = 0
    @State private var isDone: Bool = false
    @State private var isSkipped: Bool = false
    @State private var mistakes: Int = 0
    @State private var canvasView = PKCanvasView()
    @State private var results: [SessionResultItem] = []

    // Persisted user preferences (edited in Settings).
    @AppStorage(AppSettings.Key.strictGrading) private var strict: Bool = AppSettings.defaultStrictGrading
    @AppStorage(AppSettings.Key.gridStyle) private var gridStyleRaw: String = AppSettings.defaultGridStyle.rawValue
    @AppStorage(AppSettings.Key.hintThreshold) private var hintThreshold: Int = AppSettings.defaultHintThreshold

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    // Quiz state
    @State private var expectedIndex: Int = 0          // next stroke the user must write
    @State private var missesOnCurrentStroke: Int = 0  // misses since the last correct stroke
    @State private var hintIndex: Int? = nil           // stroke highlighted as a hint
    @State private var demoIndex: Int? = nil           // stroke highlighted by "Show stroke order"
    @State private var feedback: String? = nil         // transient correction message
    @State private var demoTask: Task<Void, Never>? = nil

    // Feedback state
    @State private var streak = StreakTracker()        // consecutive corrects, session-wide
    @State private var streakBurst: Int? = nil         // milestone being celebrated, if any
    @State private var rejectedInks: [RejectedInk] = [] // snapshots of rejected strokes, fading out

    // The palm-rest guide starts prominent and dims for the rest of the
    // session once the user has actually put pen to canvas.
    @State private var handGuideDimmed: Bool = false

    // Geometry of the writing pad. The outline, the reference medians, and the
    // user's pen samples all share this coordinate space so grading is fair.
    private let padSide: CGFloat = 440
    private let glyphInset: CGFloat = 32

    private var currentItem: CharacterItem { deck.chars[currentIndex] }
    private var strokeData: CharacterStrokeData? { StrokeReference.shared.data(for: currentItem.glyph) }
    private var totalStrokes: Int { strokeData?.strokes.count ?? 0 }
    private var metrics: GlyphMetrics { GlyphMetrics(size: padSide, inset: glyphInset) }
    private var gridStyle: GuideGridStyle { GuideGridStyle(storedRawValue: gridStyleRaw) }
    private var leniency: CGFloat { strict ? 1.0 : 1.6 }
    private var strokesLeft: Int { max(0, totalStrokes - expectedIndex) }

    /// A single-character session loops forever: the done state offers replay
    /// instead of advancing, and the user leaves via "Finish session".
    private var isEndless: Bool { deck.chars.count == 1 }

    var body: some View {
        VStack(spacing: 0) {
            header

            // Prompt sits centered on the screen regardless of device width.
            // ZStack so the outgoing and incoming prompts overlap while they
            // crossfade instead of stacking in the VStack.
            ZStack {
                promptBlock
                    .id(currentItem.glyph)
                    .transition(promptTransition)
            }
            .padding(.top, 20)
            .padding(.horizontal, 40)

            // Writing pad stays left-of-center; the open zone beside it is
            // where the writing hand rests.
            HStack(spacing: 40) {
                writingColumn
                handRestZone
            }
            .padding(.horizontal, 40)
            .padding(.top, 12)

            Spacer(minLength: 8)

            // Stats / done card is centered on the screen as well.
            statsCard
                .frame(width: 460)
                .padding(.bottom, 20)
        }
        .background(InkTheme.paper.ignoresSafeArea())
        .onAppear { setupCharacter() }
        .onChange(of: currentIndex) { _, _ in setupCharacter() }
        .onDisappear { demoTask?.cancel() }
    }

    /// Outgoing prompt drifts left as the new one drifts in from the right —
    /// a page turning. Plain crossfade under Reduce Motion.
    private var promptTransition: AnyTransition {
        reduceMotion
            ? .opacity
            : .asymmetric(
                insertion: .opacity.combined(with: .offset(x: 24)),
                removal: .opacity.combined(with: .offset(x: -24))
            )
    }

    // MARK: - Header

    private var header: some View {
        HStack {
            Button(action: { onExit(results) }) {
                Image(systemName: "chevron.left")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(InkTheme.ink)
                    .frame(width: 42, height: 42)
                    .background(InkTheme.card)
                    .cornerRadius(10)
                    .overlay(RoundedRectangle(cornerRadius: 10).stroke(InkTheme.line, lineWidth: 1))
            }
            .buttonStyle(InkPressButtonStyle())
            .accessibilityLabel("Back to Library")

            Spacer()

            VStack(spacing: 6) {
                Text("\(deck.script.uppercased()) · \(deck.title.uppercased())")
                    .font(.inkSans(size: 11, weight: .bold))
                    .foregroundColor(InkTheme.ink3)
                    .tracking(1.0)

                HStack(spacing: 6) {
                    ForEach(0..<deck.chars.count, id: \.self) { i in
                        Capsule()
                            .fill(i < currentIndex ? InkTheme.ink : (i == currentIndex ? InkTheme.accent : InkTheme.line2))
                            .frame(width: i == currentIndex ? 24 : 8, height: 8)
                    }
                }
                // The active dot stretches and slides on a spring instead of snapping.
                .animation(reduceMotion ? .default : .spring(response: 0.4, dampingFraction: 0.7),
                           value: currentIndex)
            }

            Spacer()

            if isEndless {
                Text("Endless practice")
                    .font(.inkSans(size: 13, weight: .semibold))
                    .foregroundColor(InkTheme.ink3)
            } else {
                HStack(spacing: 2) {
                    Text("\(currentIndex + 1)")
                        .font(.inkSerif(size: 22, weight: .bold))
                        .foregroundColor(InkTheme.ink)
                    Text(" / \(deck.chars.count)")
                        .font(.inkSerif(size: 22))
                        .foregroundColor(InkTheme.ink3)
                }
            }
        }
        .padding(.horizontal, 32)
        .padding(.vertical, 20)
        .background(InkTheme.paper)
        .overlay(VStack { Spacer(); Divider().background(InkTheme.line) })
    }

    // MARK: - Writing pad column

    private var writingColumn: some View {
        VStack(spacing: 16) {
            ZStack {
                RoundedRectangle(cornerRadius: 24)
                    .fill(InkTheme.card)
                    .overlay(RoundedRectangle(cornerRadius: 24).stroke(InkTheme.line, lineWidth: 1))
                    .shadow(color: InkTheme.shadow, radius: 20, x: 0, y: 8)

                // Grid + reference outline + drawing surface, all sharing one square.
                ZStack {
                    GuideGridView(style: gridStyle)

                    if let data = strokeData {
                        GlyphOutlineView(
                            strokeData: data,
                            metrics: metrics,
                            completedCount: expectedIndex,
                            highlightIndex: demoIndex ?? hintIndex
                        )
                    } else {
                        // Fallback ghost if reference data is unavailable.
                        Text(currentItem.glyph)
                            .font(.system(size: 320, weight: .regular, design: .serif))
                            .foregroundColor(InkTheme.glyphGhost)
                    }

                    PencilCanvasView(canvasView: $canvasView, onStrokeFinished: handleStroke)

                    // Rejected strokes fade off the paper here, above the live canvas.
                    ForEach(rejectedInks) { ink in
                        FadingInkView(image: ink.image) {
                            rejectedInks.removeAll { $0.id == ink.id }
                        }
                    }
                }
                .frame(width: padSide, height: padSide)

                if isDone {
                    doneVeil
                        .transition(.opacity)
                }

                // Streak surprise — sits above everything, never blocks input.
                if let burst = streakBurst {
                    InkBurstView(streak: burst) { streakBurst = nil }
                        .id(burst)
                }
            }
            .frame(width: 480, height: 480)

            controlsRow
        }
    }

    private var doneVeil: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 24)
                .fill(InkTheme.card.opacity(0.92))

            VStack(spacing: 12) {
                // Endless (single-character) practice loops via replay; a deck
                // offers both replay and advancing to the next character.
                HStack(spacing: 16) {
                    if isEndless {
                        veilButton(icon: "arrow.counterclockwise", prominent: true, action: restartCurrent)
                    } else {
                        veilButton(icon: "arrow.counterclockwise", prominent: false, action: restartCurrent)
                        veilButton(icon: "arrow.right", prominent: true, action: nextCharacter)
                    }
                }

                Text(isSkipped ? "Skipped" : (mistakes == 0 ? "Perfect" : "Well written"))
                    .font(.inkSerif(size: 28, weight: .bold))
                    .foregroundColor(InkTheme.ink)

                Text(isSkipped
                     ? (isEndless ? "replay to try it again" : "come back to this one")
                     : (mistakes == 0
                        ? "clean stroke order"
                        : "\(mistakes) stroke correction\(mistakes == 1 ? "" : "s")"))
                    .font(.inkSans(size: 14))
                    .foregroundColor(InkTheme.ink2)
            }
        }
        .overlay(alignment: .bottomTrailing) {
            // A finished character earns its hanko, stamped into the corner.
            if !isSkipped {
                SealStampView()
                    .padding(26)
            }
        }
    }

    private func veilButton(icon: String, prominent: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Circle()
                .fill(prominent ? InkTheme.accent : InkTheme.line2)
                .frame(width: 56, height: 56)
                .overlay(
                    Image(systemName: icon)
                        .font(.system(size: 22, weight: .bold))
                        // .white is correct on the saturated accent fill only.
                        .foregroundColor(prominent ? .white : InkTheme.ink)
                )
        }
        .buttonStyle(InkPressButtonStyle(pressedScale: 0.92))
    }

    private var controlsRow: some View {
        HStack(spacing: 12) {
            Button(action: showStrokeOrder) {
                HStack(spacing: 6) {
                    Image(systemName: "play.fill").font(.system(size: 12))
                    Text("Show stroke order").font(.inkSans(size: 13, weight: .semibold))
                }
                .foregroundColor(InkTheme.ink)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(InkTheme.line2)
                .cornerRadius(10)
            }
            .buttonStyle(InkPressButtonStyle())
            .accessibilityLabel("Show stroke order animation")
            .disabled(isDone || strokeData == nil)

            Button(action: restartCurrent) {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.clockwise").font(.system(size: 12))
                    Text("Redo").font(.inkSans(size: 13, weight: .semibold))
                }
                .foregroundColor(InkTheme.ink)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(InkTheme.line2)
                .cornerRadius(10)
            }
            .buttonStyle(InkPressButtonStyle())
            .accessibilityLabel("Restart current character")

            Spacer()

            Button(action: isDone ? nextCharacter : skipCharacter) {
                HStack(spacing: 6) {
                    Image(systemName: "forward.fill").font(.system(size: 12))
                    Text(isDone ? (isEndless ? "Finish" : "Next") : "Skip").font(.inkSans(size: 13, weight: .semibold))
                }
                .foregroundColor(InkTheme.ink2)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.clear)
            }
            .buttonStyle(InkPressButtonStyle())
            .accessibilityLabel(isDone ? "Next character" : "Skip character")
        }
        .frame(width: 480)
    }

    // MARK: - Prompt (centered on screen)

    private var promptBlock: some View {
        VStack(spacing: 10) {
            Text("WRITE THIS CHARACTER")
                .font(.inkSans(size: 12, weight: .bold))
                .foregroundColor(InkTheme.accent)
                .tracking(1.2)

            Text(currentItem.meaning.isEmpty ? "Reference Glyph" : currentItem.meaning)
                .font(.inkSerif(size: 42, weight: .bold))
                .foregroundColor(InkTheme.ink)

            if !currentItem.reading.isEmpty {
                Text(currentItem.reading)
                    .font(.inkSans(size: 20))
                    .foregroundColor(InkTheme.ink2)
            }

            Text(deck.lang == .chinese ? "Simplified" : "Japanese")
                .font(.inkSans(size: 12, weight: .medium))
                .foregroundColor(InkTheme.ink3)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(InkTheme.line2.opacity(0.5))
                .cornerRadius(16)
        }
        .multilineTextAlignment(.center)
        .frame(maxWidth: .infinity)
    }

    // MARK: - Hand-rest zone

    /// The open region beside the writing pad, reserved for the writing hand.
    private var handRestZone: some View {
        ZStack {
            if !isDone {
                HandRestGuideView()
                    .opacity(handGuideDimmed ? 0.35 : 1.0)
                    .animation(.easeOut(duration: 0.6), value: handGuideDimmed)
                    .accessibilityHidden(true)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    /// Shown when stroke data was assembled via IDS decomposition rather than
    /// loaded directly from the reference database. Grading still works but uses
    /// wider tolerances because the medians are approximate.
    private var synthesizedNotice: some View {
        HStack(spacing: 8) {
            Image(systemName: "puzzlepiece.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(InkTheme.ink3)
            Text("Approximated guide")
                .font(.inkSans(size: 12, weight: .semibold))
                .foregroundColor(InkTheme.ink3)
        }
        .padding(.bottom, 4)
    }

    /// Shown when no reference stroke data exists for the current glyph, so the
    /// grader has nothing to compare against. The pad still shows a faint ghost
    /// of the character; the user can trace it freely but no grading occurs.
    private var freePracticeNotice: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(spacing: 8) {
                Image(systemName: "scribble.variable")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(InkTheme.accent)
                Text("Free practice")
                    .font(.inkSans(size: 15, weight: .bold))
                    .foregroundColor(InkTheme.ink)
            }

            Text("No stroke guide is available for this character, so strokes can't be graded. Trace it freely over the faint reference, then tap Skip to move on.")
                .font(.inkSans(size: 13))
                .foregroundColor(InkTheme.ink2)
                .lineSpacing(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var statsCard: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !isDone {
                if strokeData == nil {
                    freePracticeNotice
                } else {
                    if strokeData?.source == .synthesized {
                        synthesizedNotice
                    }
                    HStack {
                        Text("Strokes left")
                            .font(.inkSans(size: 14))
                            .foregroundColor(InkTheme.ink2)
                        Spacer()
                        Text(totalStrokes == 0 ? "—" : "\(strokesLeft)")
                            .font(.inkSerif(size: 24, weight: .bold))
                            .foregroundColor(InkTheme.ink)
                    }

                    Divider().background(InkTheme.line)

                    HStack {
                        Text("Corrections")
                            .font(.inkSans(size: 14))
                            .foregroundColor(InkTheme.ink2)
                        Spacer()
                        Text("\(mistakes)")
                            .font(.inkSerif(size: 24, weight: .bold))
                            .foregroundColor(mistakes == 0 ? InkTheme.ink : InkTheme.accent)
                    }

                    if let feedback {
                        Text(feedback)
                            .font(.inkSans(size: 13, weight: .semibold))
                            .foregroundColor(InkTheme.accent)
                            .lineSpacing(2)
                            .fixedSize(horizontal: false, vertical: true)
                    } else {
                        Text("Draw each stroke in order. Wrong strokes won't stick — after a few misses the next stroke is highlighted.")
                            .font(.inkSans(size: 13))
                            .foregroundColor(InkTheme.ink3)
                            .lineSpacing(2)
                    }
                }
            } else {
                VStack(spacing: 16) {
                    Text(currentItem.glyph)
                        .font(.system(size: 90, weight: .regular, design: .serif))
                        .foregroundColor(InkTheme.ink)

                    Button(action: nextCharacter) {
                        HStack(spacing: 8) {
                            Text(currentIndex + 1 >= deck.chars.count ? "Finish session" : "Next character")
                                .font(.inkSans(size: 16, weight: .bold))
                            Image(systemName: "arrow.right").font(.system(size: 16, weight: .bold))
                        }
                        .foregroundColor(InkTheme.onInk)
                        .frame(maxWidth: .infinity)
                        .frame(height: 52)
                        .background(InkTheme.ink)
                        .cornerRadius(12)
                    }
                    .buttonStyle(InkPressButtonStyle())
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(InkTheme.card)
        .cornerRadius(18)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(InkTheme.line, lineWidth: 1))
        // Ease the card's height change when a correction message comes or goes.
        .animation(.easeInOut(duration: 0.2), value: feedback)
    }

    // MARK: - Grading

    /// Grade a finished user stroke against the expected next stroke.
    private func handleStroke(_ canvasPoints: [CGPoint]) {
        guard !isDone else { return }
        if !handGuideDimmed { handGuideDimmed = true }
        guard let data = strokeData, expectedIndex < data.medians.count else { return }

        let userBox = canvasPoints.map { metrics.boxPoint(canvas: $0) }
        let expectedMedian = data.medians[expectedIndex].map { metrics.boxPoint($0) }

        var config = StrokeGrader.Config()
        config.leniency = leniency
        // Synthesized medians are approximate (assembled from components), so
        // give the grader more room — otherwise correct strokes get rejected.
        if data.source == .synthesized { config.leniency *= 1.4 }

        switch StrokeGrader.judge(user: userBox, median: expectedMedian, config: config) {
        case .correct:
            handleCorrectStroke()

        case .tooShort:
            // An accidental dab — remove it but don't penalize.
            rejectLastStroke()

        case .wrongDirection:
            handleMistake(feedbackMessage: "Wrong direction — start that stroke from the other end.")

        case .wrongStroke:
            let feedbackMessage: String
            if let other = matchesAnotherStroke(userBox, data: data) {
                feedbackMessage = "Out of order — that looks like stroke \(other + 1). Write stroke \(expectedIndex + 1) first."
            } else {
                feedbackMessage = "Not quite — try stroke \(expectedIndex + 1) again."
            }
            handleMistake(feedbackMessage: feedbackMessage)
        }
    }

    private func handleCorrectStroke() {
        expectedIndex += 1
        missesOnCurrentStroke = 0
        hintIndex = nil
        feedback = nil

        let milestone = streak.recordCorrect()
        if let milestone {
            streakBurst = milestone
            SoundEffects.shared.play(.streakMilestone)
        } else {
            SoundEffects.shared.play(.strokeCorrect)
        }

        if expectedIndex >= totalStrokes {
            // If a streak fanfare just fired, it owns this moment — skip the chime.
            completeCharacter(mistakesCount: mistakes, withChime: milestone == nil)
        }
    }

    private func handleMistake(feedbackMessage: String) {
        mistakes += 1
        missesOnCurrentStroke += 1
        streak.recordMiss()
        rejectLastStroke()
        SoundEffects.shared.play(.strokeRejected)
        feedback = feedbackMessage
        if missesOnCurrentStroke >= hintThreshold { hintIndex = expectedIndex }
    }

    /// Does the user's stroke actually match a different stroke of this glyph?
    private func matchesAnotherStroke(_ userBox: [CGPoint], data: CharacterStrokeData) -> Int? {
        var config = StrokeGrader.Config()
        config.leniency = leniency
        for index in data.medians.indices where index != expectedIndex {
            let median = data.medians[index].map { metrics.boxPoint($0) }
            if StrokeGrader.judge(user: userBox, median: median, config: config) == .correct {
                return index
            }
        }
        return nil
    }

    /// Remove the most recent (rejected) stroke from the canvas, leaving a
    /// snapshot of its ink to fade out (~0.35 s) so the rejection reads as
    /// "the paper didn't take it" rather than a glitch. Deferred to the next
    /// runloop tick to avoid mutating the drawing from inside its own change
    /// callback.
    private func rejectLastStroke() {
        DispatchQueue.main.async {
            guard let rejected = canvasView.drawing.strokes.last else { return }
            var drawing = canvasView.drawing
            drawing.strokes.removeLast()
            canvasView.drawing = drawing

            // Under Reduce Motion the stroke simply disappears, as before.
            guard !reduceMotion else { return }
            let rect = CGRect(x: 0, y: 0, width: padSide, height: padSide)
            let scale = max(canvasView.traitCollection.displayScale, 2)
            var snapshot: UIImage?
            // Render under a pinned-light trait to match the canvas, which is
            // pinned .light so PencilKit never remaps stroke colors itself.
            UITraitCollection(userInterfaceStyle: .light).performAsCurrent {
                snapshot = PKDrawing(strokes: [rejected]).image(from: rect, scale: scale)
            }
            if let snapshot {
                rejectedInks.append(RejectedInk(image: snapshot))
            }
        }
    }

    // MARK: - Stroke-order demo

    private func showStrokeOrder() {
        guard let data = strokeData else { return }
        demoTask?.cancel()
        demoTask = Task { @MainActor in
            feedback = nil
            for index in data.strokes.indices {
                demoIndex = index
                try? await Task.sleep(nanoseconds: 650_000_000)
                if Task.isCancelled { break }
            }
            demoIndex = nil
        }
    }

    // MARK: - Lifecycle

    private func setupCharacter() {
        demoTask?.cancel()
        demoIndex = nil
        canvasView.drawing = PKDrawing()
        expectedIndex = 0
        missesOnCurrentStroke = 0
        mistakes = 0
        hintIndex = nil
        feedback = nil
        isDone = false
        isSkipped = false
        rejectedInks = []
    }

    private func completeCharacter(mistakesCount: Int, withChime: Bool = true) {
        // The reward moment: the veil fades in and the seal stamps itself into
        // the corner (SealStampView) a beat later, with a soft two-note chime.
        withAnimation(.easeOut(duration: 0.3)) {
            isDone = true
        }
        if withChime {
            SoundEffects.shared.play(.characterComplete)
        }
        results.append(SessionResultItem(glyph: currentItem.glyph, mistakes: mistakesCount, skipped: false))
    }

    private func skipCharacter() {
        demoTask?.cancel()
        withAnimation(.easeOut(duration: 0.25)) {
            isDone = true
            isSkipped = true
        }
        results.append(SessionResultItem(glyph: currentItem.glyph, mistakes: 0, skipped: true))
    }

    private func restartCurrent() {
        withAnimation(.easeInOut(duration: 0.25)) {
            setupCharacter()
        }
    }

    private func nextCharacter() {
        if currentIndex + 1 >= deck.chars.count {
            onFinish(results)
        } else {
            // Animates the prompt crossfade, the progress-dot spring, the veil
            // fading out, and the pad's ink returning to ghost for the new glyph.
            withAnimation(.easeInOut(duration: 0.35)) {
                currentIndex += 1   // triggers setupCharacter() via onChange
            }
        }
    }
}

// MARK: - Completion seal stamp

/// The hanko moment on the done veil: the seal springs down onto the paper
/// from above (large → resting size) with a slight, randomized tilt, like a
/// real seal never landing perfectly straight twice.
private struct SealStampView: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var stamped = false
    @State private var tilt = Double.random(in: -8 ... -2)

    var body: some View {
        SealView(size: 46)
            .rotationEffect(.degrees(stamped ? tilt : 0))
            .scaleEffect(stamped || reduceMotion ? 1 : 2.4)
            .opacity(stamped ? 1 : 0)
            .onAppear {
                let stamp: Animation = reduceMotion
                    ? .easeOut(duration: 0.2)
                    : .spring(response: 0.3, dampingFraction: 0.55)
                withAnimation(stamp.delay(0.15)) {
                    stamped = true
                }
            }
            .accessibilityHidden(true)
    }
}

// MARK: - Rejected-ink fade

/// A snapshot of a stroke the grader rejected, held in place over the canvas
/// while it fades away.
private struct RejectedInk: Identifiable {
    let id = UUID()
    let image: UIImage
}

private struct FadingInkView: View {
    let image: UIImage
    let onFinished: () -> Void

    @State private var visible = true

    var body: some View {
        Image(uiImage: image)
            .resizable()
            .opacity(visible ? 1 : 0)
            .allowsHitTesting(false)
            .accessibilityHidden(true)
            .task {
                withAnimation(.easeOut(duration: 0.35)) { visible = false }
                try? await Task.sleep(nanoseconds: 450_000_000)
                onFinished()
            }
    }
}

// MARK: - Palm-rest guide

/// Ergonomic hint for the deliberately asymmetric practice layout: the open
/// region beside the writing pad exists so the writing hand has somewhere to
/// land, and this guide makes that affordance visible. Purely decorative —
/// the drawing surface only covers the pad itself, so a hand resting here
/// never produces strokes.
struct HandRestGuideView: View {
    var body: some View {
        VStack(spacing: 18) {
            PalmRestShape()
                .stroke(
                    InkTheme.ink3,
                    style: StrokeStyle(lineWidth: 1.5, lineCap: .round, dash: [6, 6])
                )
                .background(PalmRestShape().fill(InkTheme.line2.opacity(0.4)))
                .frame(width: 170, height: 195)
                .rotationEffect(.degrees(-12))   // lean the hand toward the pad

            VStack(spacing: 8) {
                Image(systemName: "hand.draw")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(InkTheme.ink3)

                Text("REST YOUR PALM HERE")
                    .font(.inkSans(size: 11, weight: .bold))
                    .tracking(1.2)
                    .foregroundColor(InkTheme.ink3)
            }
        }
    }
}

/// Stylized outline of a relaxed right hand seen from above — fingers curled
/// around a pen, pinky edge and palm heel down — drawn in a unit square and
/// scaled to whatever frame it's given.
struct PalmRestShape: Shape {
    func path(in rect: CGRect) -> Path {
        func pt(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
            CGPoint(x: rect.minX + x * rect.width, y: rect.minY + y * rect.height)
        }

        var p = Path()
        p.move(to: pt(0.42, 0.98))                                                            // wrist, thumb side
        p.addCurve(to: pt(0.22, 0.60), control1: pt(0.34, 0.90), control2: pt(0.24, 0.74))    // up the thumb side
        p.addCurve(to: pt(0.10, 0.42), control1: pt(0.20, 0.52), control2: pt(0.10, 0.50))    // out to the thumb
        p.addCurve(to: pt(0.20, 0.26), control1: pt(0.10, 0.34), control2: pt(0.13, 0.28))    // around the thumb tip
        p.addCurve(to: pt(0.34, 0.30), control1: pt(0.26, 0.25), control2: pt(0.31, 0.27))    // back into the web
        p.addCurve(to: pt(0.44, 0.10), control1: pt(0.36, 0.22), control2: pt(0.38, 0.14))    // up to the index knuckle
        p.addCurve(to: pt(0.72, 0.05), control1: pt(0.52, 0.04), control2: pt(0.64, 0.02))    // across the curled fingers
        p.addCurve(to: pt(0.90, 0.24), control1: pt(0.82, 0.09), control2: pt(0.88, 0.15))    // over the pinky knuckle
        p.addCurve(to: pt(0.97, 0.62), control1: pt(0.94, 0.36), control2: pt(0.97, 0.48))    // down the pinky edge
        p.addCurve(to: pt(0.88, 0.98), control1: pt(0.97, 0.76), control2: pt(0.94, 0.90))    // heel of the palm
        p.closeSubpath()                                                                      // across the wrist
        return p
    }
}
