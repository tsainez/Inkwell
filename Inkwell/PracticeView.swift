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

    // Quiz state
    @State private var expectedIndex: Int = 0          // next stroke the user must write
    @State private var missesOnCurrentStroke: Int = 0  // misses since the last correct stroke
    @State private var hintIndex: Int? = nil           // stroke highlighted as a hint
    @State private var demoIndex: Int? = nil           // stroke highlighted by "Show stroke order"
    @State private var feedback: String? = nil         // transient correction message
    @State private var demoTask: Task<Void, Never>? = nil

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

    var body: some View {
        VStack(spacing: 0) {
            header

            // Main Content
            HStack(spacing: 40) {
                writingColumn
                infoColumn
            }
            .padding(40)
        }
        .background(InkTheme.paper.ignoresSafeArea())
        .onAppear { setupCharacter() }
        .onChange(of: currentIndex) { _, _ in setupCharacter() }
        .onDisappear { demoTask?.cancel() }
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
            }

            Spacer()

            HStack(spacing: 2) {
                Text("\(currentIndex + 1)")
                    .font(.inkSerif(size: 22, weight: .bold))
                    .foregroundColor(InkTheme.ink)
                Text(" / \(deck.chars.count)")
                    .font(.inkSerif(size: 22))
                    .foregroundColor(InkTheme.ink3)
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
                    .shadow(color: Color.black.opacity(0.04), radius: 20, x: 0, y: 8)

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
                            .foregroundColor(InkTheme.ink3.opacity(0.12))
                    }

                    PencilCanvasView(canvasView: $canvasView, onStrokeFinished: handleStroke)
                }
                .frame(width: padSide, height: padSide)

                if isDone {
                    doneVeil
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
                Circle()
                    .fill(InkTheme.accent)
                    .frame(width: 56, height: 56)
                    .overlay(
                        Image(systemName: isSkipped ? "arrow.right" : "checkmark")
                            .font(.system(size: 24, weight: .bold))
                            .foregroundColor(.white)
                    )

                Text(isSkipped ? "Skipped" : (mistakes == 0 ? "Perfect" : "Well written"))
                    .font(.inkSerif(size: 28, weight: .bold))
                    .foregroundColor(InkTheme.ink)

                Text(isSkipped
                     ? "come back to this one"
                     : (mistakes == 0
                        ? "clean stroke order"
                        : "\(mistakes) stroke correction\(mistakes == 1 ? "" : "s")"))
                    .font(.inkSans(size: 14))
                    .foregroundColor(InkTheme.ink2)
            }
        }
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

            Spacer()

            Button(action: isDone ? nextCharacter : skipCharacter) {
                HStack(spacing: 6) {
                    Image(systemName: "forward.fill").font(.system(size: 12))
                    Text(isDone ? "Next" : "Skip").font(.inkSans(size: 13, weight: .semibold))
                }
                .foregroundColor(InkTheme.ink2)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(Color.clear)
            }
        }
        .frame(width: 480)
    }

    // MARK: - Info column

    private var infoColumn: some View {
        VStack(alignment: .leading, spacing: 24) {
            VStack(alignment: .leading, spacing: 12) {
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

                HStack(spacing: 8) {
                    HStack(spacing: 4) {
                        Image(systemName: "speaker.wave.2.fill").font(.system(size: 12))
                        Text("Audio").font(.inkSans(size: 12, weight: .semibold))
                    }
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(InkTheme.line2)
                    .cornerRadius(16)

                    Text(deck.lang == .chinese ? "Simplified" : "Japanese")
                        .font(.inkSans(size: 12, weight: .medium))
                        .foregroundColor(InkTheme.ink3)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(InkTheme.line2.opacity(0.5))
                        .cornerRadius(16)
                }
            }

            Spacer()

            statsCard
        }
        .frame(maxWidth: .infinity, alignment: .leading)
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
                }
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity)
        .background(InkTheme.card)
        .cornerRadius(18)
        .overlay(RoundedRectangle(cornerRadius: 18).stroke(InkTheme.line, lineWidth: 1))
    }

    // MARK: - Grading

    /// Grade a finished user stroke against the expected next stroke.
    private func handleStroke(_ canvasPoints: [CGPoint]) {
        guard !isDone else { return }
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
            expectedIndex += 1
            missesOnCurrentStroke = 0
            hintIndex = nil
            feedback = nil
            if expectedIndex >= totalStrokes {
                completeCharacter(mistakesCount: mistakes)
            }

        case .tooShort:
            // An accidental dab — remove it but don't penalize.
            rejectLastStroke()

        case .wrongDirection:
            mistakes += 1
            missesOnCurrentStroke += 1
            rejectLastStroke()
            feedback = "Wrong direction — start that stroke from the other end."
            if missesOnCurrentStroke >= hintThreshold { hintIndex = expectedIndex }

        case .wrongStroke:
            mistakes += 1
            missesOnCurrentStroke += 1
            rejectLastStroke()
            if let other = matchesAnotherStroke(userBox, data: data) {
                feedback = "Out of order — that looks like stroke \(other + 1). Write stroke \(expectedIndex + 1) first."
            } else {
                feedback = "Not quite — try stroke \(expectedIndex + 1) again."
            }
            if missesOnCurrentStroke >= hintThreshold { hintIndex = expectedIndex }
        }
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

    /// Remove the most recent (rejected) stroke from the canvas. Deferred to the
    /// next runloop tick to avoid mutating the drawing from inside its own
    /// change callback.
    private func rejectLastStroke() {
        DispatchQueue.main.async {
            guard !canvasView.drawing.strokes.isEmpty else { return }
            var drawing = canvasView.drawing
            drawing.strokes.removeLast()
            canvasView.drawing = drawing
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
    }

    private func completeCharacter(mistakesCount: Int) {
        isDone = true
        results.append(SessionResultItem(glyph: currentItem.glyph, mistakes: mistakesCount, skipped: false))
    }

    private func skipCharacter() {
        demoTask?.cancel()
        isDone = true
        isSkipped = true
        results.append(SessionResultItem(glyph: currentItem.glyph, mistakes: 0, skipped: true))
    }

    private func restartCurrent() {
        setupCharacter()
    }

    private func nextCharacter() {
        if currentIndex + 1 >= deck.chars.count {
            onFinish(results)
        } else {
            currentIndex += 1   // triggers setupCharacter() via onChange
        }
    }
}
