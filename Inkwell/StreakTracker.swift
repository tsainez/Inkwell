//
//  StreakTracker.swift
//  Inkwell
//
//  Counts consecutive correct strokes within a practice session and decides
//  when that run deserves a celebration. Pure logic — no UI imports — so the
//  milestone behavior is unit-testable.
//

import Foundation

struct StreakTracker: Equatable {
    /// Consecutive correct strokes since the last miss.
    private(set) var count: Int = 0

    /// A milestone fires every time the streak crosses a multiple of this.
    let milestoneInterval: Int

    // Explicit because `private(set)` would make the synthesized memberwise
    // initializer private to this file.
    init(milestoneInterval: Int = 10) {
        self.milestoneInterval = milestoneInterval
    }

    /// Record a correctly written stroke. Returns the new streak count when it
    /// lands exactly on a milestone (10, 20, 30…), or nil otherwise.
    @discardableResult
    mutating func recordCorrect() -> Int? {
        count += 1
        return count.isMultiple(of: milestoneInterval) ? count : nil
    }

    /// Record a rejected stroke (wrong stroke or wrong direction). Accidental
    /// dabs graded `.tooShort` should NOT be reported here — they aren't misses.
    mutating func recordMiss() {
        count = 0
    }
}
