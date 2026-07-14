//
//  StreakTrackerTests.swift
//  InkwellTests
//
//  The streak celebration must fire exactly on milestones and never otherwise,
//  so the counting rules are pinned down here.
//

import Testing
@testable import Inkwell

struct StreakTrackerTests {

    @Test func noMilestoneBeforeTheInterval() {
        var tracker = StreakTracker()
        for _ in 1...9 {
            #expect(tracker.recordCorrect() == nil)
        }
        #expect(tracker.count == 9)
    }

    @Test func milestoneFiresExactlyAtTheInterval() {
        var tracker = StreakTracker()
        for _ in 1...9 { tracker.recordCorrect() }
        #expect(tracker.recordCorrect() == 10)
    }

    @Test func milestoneRepeatsAtEveryMultiple() {
        var tracker = StreakTracker()
        var milestones: [Int] = []
        for _ in 1...30 {
            if let milestone = tracker.recordCorrect() {
                milestones.append(milestone)
            }
        }
        #expect(milestones == [10, 20, 30])
    }

    @Test func missResetsTheStreak() {
        var tracker = StreakTracker()
        for _ in 1...9 { tracker.recordCorrect() }
        tracker.recordMiss()
        #expect(tracker.count == 0)
        // The next correct is #1 of a new run, not #10 of the old one.
        #expect(tracker.recordCorrect() == nil)
    }

    @Test func streakResumesCountingAfterReset() {
        var tracker = StreakTracker()
        for _ in 1...4 { tracker.recordCorrect() }
        tracker.recordMiss()
        for _ in 1...9 { tracker.recordCorrect() }
        #expect(tracker.recordCorrect() == 10)
    }

    @Test func customIntervalIsRespected() {
        var tracker = StreakTracker(milestoneInterval: 3)
        #expect(tracker.recordCorrect() == nil)
        #expect(tracker.recordCorrect() == nil)
        #expect(tracker.recordCorrect() == 3)
    }
}
