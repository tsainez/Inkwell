//
//  SoundEffects.swift
//  Inkwell
//
//  A tiny, self-contained sound palette for practice feedback. Every effect is
//  synthesized at first use into a PCM buffer — soft koto-like plucks on a
//  pentatonic scale — so the app ships no audio assets and the sounds stay
//  perfectly consistent with each other.
//
//  Deliberately unobtrusive: the audio session uses the `.ambient` category, so
//  effects respect the silent switch and mix with (never interrupt) the user's
//  own music. Peak levels are kept low, and everything can be turned off with
//  the "Sound effects" toggle in Settings (checked on every play call).
//

import AVFoundation

@MainActor
final class SoundEffects {
    static let shared = SoundEffects()

    enum Event: CaseIterable {
        /// Soft, short tick — a correct stroke landing on the paper.
        case strokeCorrect
        /// Muted low thud — a stroke the paper rejected. Quiet, not punishing.
        case strokeRejected
        /// Two-note pluck — a character completed.
        case characterComplete
        /// Ascending pentatonic run — the streak-milestone surprise.
        case streakMilestone
        /// Warm three-note chord — the session summary.
        case sessionComplete
    }

    private let engine = AVAudioEngine()
    private var players: [AVAudioPlayerNode] = []
    private var buffers: [Event: AVAudioPCMBuffer] = [:]
    private var nextPlayerIndex = 0
    private var isConfigured = false
    private var setupFailed = false

    private static let sampleRate = 44_100.0
    /// Enough simultaneous voices for a chime to still be ringing when the
    /// next stroke's tick plays.
    private static let voiceCount = 3

    private init() {}

    /// The user preference from Settings. Read at play time so changes apply
    /// immediately, without any notification plumbing.
    var isEnabled: Bool {
        UserDefaults.standard.object(forKey: AppSettings.Key.soundEffects) as? Bool
            ?? AppSettings.defaultSoundEffects
    }

    func play(_ event: Event) {
        guard isEnabled else { return }
        configureIfNeeded()
        guard !setupFailed, let buffer = buffers[event] else { return }

        if !engine.isRunning {
            do { try engine.start() } catch { return }
        }

        let player = players[nextPlayerIndex]
        nextPlayerIndex = (nextPlayerIndex + 1) % players.count
        player.stop()
        player.scheduleBuffer(buffer, at: nil)
        player.play()
    }

    // MARK: - Setup

    private func configureIfNeeded() {
        guard !isConfigured && !setupFailed else { return }
        isConfigured = true

        // Ambient = obeys the silent switch and mixes with the user's audio.
        try? AVAudioSession.sharedInstance().setCategory(.ambient, options: [.mixWithOthers])

        guard let format = AVAudioFormat(standardFormatWithSampleRate: Self.sampleRate, channels: 1) else {
            setupFailed = true
            return
        }

        for _ in 0..<Self.voiceCount {
            let node = AVAudioPlayerNode()
            engine.attach(node)
            engine.connect(node, to: engine.mainMixerNode, format: format)
            players.append(node)
        }

        for event in Event.allCases {
            buffers[event] = Self.renderBuffer(for: event, format: format)
        }

        engine.prepare()
        do { try engine.start() } catch { setupFailed = true }
    }

    // MARK: - Synthesis

    /// One synthesized note: a sine fundamental plus a faster-decaying second
    /// harmonic under an exponential envelope — reads as a soft string pluck.
    private struct Pluck {
        let frequency: Double   // Hz
        let start: Double       // seconds into the buffer
        let duration: Double    // seconds of audible tail
        let amplitude: Double   // 0...1 peak, kept well below 1
    }

    /// All pitches sit on a G pentatonic scale so any overlap stays consonant.
    private static func recipe(for event: Event) -> [Pluck] {
        switch event {
        case .strokeCorrect:
            return [Pluck(frequency: 987.77, start: 0, duration: 0.09, amplitude: 0.10)] // B5 tick
        case .strokeRejected:
            return [Pluck(frequency: 146.83, start: 0, duration: 0.16, amplitude: 0.11)] // D3 thud
        case .characterComplete:
            return [Pluck(frequency: 523.25, start: 0.00, duration: 0.50, amplitude: 0.16),  // C5
                    Pluck(frequency: 783.99, start: 0.10, duration: 0.60, amplitude: 0.14)]  // G5
        case .streakMilestone:
            let run = [587.33, 659.26, 783.99, 880.00, 1174.66] // D5 E5 G5 A5 D6
            return run.enumerated().map { index, frequency in
                Pluck(frequency: frequency, start: Double(index) * 0.07, duration: 0.45, amplitude: 0.15)
            }
        case .sessionComplete:
            return [Pluck(frequency: 392.00, start: 0.00, duration: 0.90, amplitude: 0.13),  // G4
                    Pluck(frequency: 523.25, start: 0.09, duration: 0.90, amplitude: 0.13),  // C5
                    Pluck(frequency: 659.26, start: 0.18, duration: 1.00, amplitude: 0.13)]  // E5
        }
    }

    private static func renderBuffer(for event: Event, format: AVAudioFormat) -> AVAudioPCMBuffer? {
        let plucks = recipe(for: event)
        let totalSeconds = (plucks.map { $0.start + $0.duration }.max() ?? 0) + 0.05
        let frameCount = AVAudioFrameCount(totalSeconds * sampleRate)
        guard let buffer = AVAudioPCMBuffer(pcmFormat: format, frameCapacity: frameCount),
              let samples = buffer.floatChannelData?.pointee else { return nil }
        buffer.frameLength = frameCount
        // The buffer's memory is not guaranteed to be zeroed, and plucks are
        // mixed in with `+=`.
        samples.update(repeating: 0, count: Int(frameCount))

        for pluck in plucks {
            let startFrame = Int(pluck.start * sampleRate)
            let pluckFrames = Int(pluck.duration * sampleRate)
            for i in 0..<pluckFrames {
                let frame = startFrame + i
                guard frame < Int(frameCount) else { break }
                let t = Double(i) / sampleRate
                // 3 ms attack ramp avoids clicks; exp decay reaches ~e⁻⁵ at the tail.
                let attack = min(1.0, t / 0.003)
                let envelope = attack * exp(-t * (5.0 / pluck.duration))
                let fundamental = sin(2 * .pi * pluck.frequency * t)
                let harmonic = 0.35 * sin(2 * .pi * pluck.frequency * 2 * t) * exp(-t * (9.0 / pluck.duration))
                samples[frame] += Float(pluck.amplitude * envelope * (fundamental + harmonic))
            }
        }
        return buffer
    }
}
