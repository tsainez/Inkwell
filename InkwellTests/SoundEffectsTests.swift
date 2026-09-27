import Testing
import AVFoundation
@testable import Inkwell

struct SoundEffectsTests {

    @Test @MainActor func testRecipeGeneratesPlucksForAllEvents() async throws {
        for event in SoundEffects.Event.allCases {
            let plucks = SoundEffects.recipe(for: event)
            #expect(!plucks.isEmpty, "Recipe for \(event) should not be empty")

            for pluck in plucks {
                #expect(pluck.frequency > 0, "Frequency should be positive")
                #expect(pluck.start >= 0, "Start time should be non-negative")
                #expect(pluck.duration > 0, "Duration should be positive")
                #expect(pluck.amplitude > 0 && pluck.amplitude < 1.0, "Amplitude should be between 0 and 1")
            }
        }
    }

    @Test @MainActor func testRenderBufferCreatesAudioData() async throws {
        guard let format = AVAudioFormat(standardFormatWithSampleRate: 44100.0, channels: 1) else {
            Issue.record("Failed to create audio format")
            return
        }

        for event in SoundEffects.Event.allCases {
            let buffer = SoundEffects.renderBuffer(for: event, format: format)
            #expect(buffer != nil, "Buffer for \(event) should not be nil")

            if let buffer = buffer {
                #expect(buffer.frameLength > 0, "Buffer for \(event) should have frame length > 0")
                #expect(buffer.floatChannelData != nil, "Buffer for \(event) should have float channel data")

                // Let's also verify that there is actually some audio data (non-zero samples)
                if let data = buffer.floatChannelData?.pointee {
                    var hasNonZeroSample = false
                    for i in 0..<Int(buffer.frameLength) {
                        if abs(data[i]) > 0.0001 {
                            hasNonZeroSample = true
                            break
                        }
                    }
                    #expect(hasNonZeroSample, "Buffer for \(event) should have non-zero samples")
                }
            }
        }
    }
}
