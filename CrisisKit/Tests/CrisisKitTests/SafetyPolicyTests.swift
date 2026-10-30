import Foundation
import Testing

@testable import CrisisKit

private func sad(_ text: String = "I feel so low lately.") -> CrisisAssessment {
    CrisisAssessment(text: text, probabilities: [0.6, 0.35, 0.05])  // classifier says check-in, no rule fires
}

@Test func firstCheckInShowsThenCoolsDown() {
    var p = SafetyPolicy()
    let t0 = Date(timeIntervalSince1970: 0)
    do { let shown = p.shouldCheckIn(sad(), index: 0, now: t0); #expect(shown) }
    do { let shown = p.shouldCheckIn(sad(), index: 1, now: t0.addingTimeInterval(60)); #expect(!shown) }
    do { let shown = p.shouldCheckIn(sad(), index: 9, now: t0.addingTimeInterval(120)); #expect(!shown) }
    do { let shown = p.shouldCheckIn(sad(), index: 10, now: t0.addingTimeInterval(180)); #expect(shown) }  // 10 messages later
}

@Test func cooldownEndsAfterThirtyMinutes() {
    var p = SafetyPolicy()
    let t0 = Date(timeIntervalSince1970: 0)
    do { let shown = p.shouldCheckIn(sad(), index: 0, now: t0); #expect(shown) }
    do { let shown = p.shouldCheckIn(sad(), index: 2, now: t0.addingTimeInterval(31 * 60)); #expect(shown) }
}

@Test func newKindOfRiskBypassesCooldown() {
    var p = SafetyPolicy()
    let t0 = Date(timeIntervalSince1970: 0)
    do { let shown = p.shouldCheckIn(sad(), index: 0, now: t0); #expect(shown) }
    let funeral = CrisisAssessment(text: "I keep imagining my own funeral.", probabilities: [0.9, 0.08, 0.02])
    #expect(funeral.level == .checkin && !funeral.rules.isEmpty)
    do { let shown = p.shouldCheckIn(funeral, index: 1, now: t0.addingTimeInterval(10)); #expect(shown) }
}

@Test func noCheckInForSafeOrCrisisMessages() {
    var p = SafetyPolicy()
    do { let shown = p.shouldCheckIn(CrisisAssessment(text: "I just got laid off.", probabilities: [0.9, 0.08, 0.02]), index: 0); #expect(!shown) }
    do { let shown = p.shouldCheckIn(CrisisAssessment(text: "I want to kill myself.", probabilities: [0.1, 0.1, 0.8]), index: 1); #expect(!shown) }
}

@Test func crisisHalvesTheCooldown() {
    var p = SafetyPolicy()
    let t0 = Date(timeIntervalSince1970: 0)
    p.didShowCrisis(index: 0, now: t0)
    #expect(p.heightened)
    do { let shown = p.shouldCheckIn(sad(), index: 4, now: t0.addingTimeInterval(60)); #expect(!shown) }
    do { let shown = p.shouldCheckIn(sad(), index: 5, now: t0.addingTimeInterval(120)); #expect(shown) }  // 5 messages when heightened
}
