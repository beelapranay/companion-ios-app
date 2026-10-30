import Foundation
import Testing

@testable import CrisisKit

/// The Swift rules must reproduce the Python ones (crisis_layer/rules.py, pipeline.py) exactly; rules_fixture.json
/// holds what Python returned, written by crisis_layer/export_swift.py.
struct Fixture: Decodable {
    struct Input: Decodable {
        let text: String
        let level: String
        let rules: [String]
        let high_precision: Bool
        let ids: [Int]
        let probs: [Double]
    }

    struct Reply: Decodable {
        let text: String
        let level: String
        let stripped: String
        let removed: Bool
        let ok: Bool
        let reasons: [String]
    }

    let inputs: [Input]
    let replies: [Reply]

    static let shared: Fixture = {
        let url = Bundle.module.url(forResource: "rules_fixture", withExtension: "json", subdirectory: "Resources")!
        return try! JSONDecoder().decode(Fixture.self, from: Data(contentsOf: url))
    }()
}

private func level(_ name: String) -> CrisisLevel { CrisisLevel.allCases.first { $0.name == name }! }

@Test func checkInputMatchesPython() {
    var mismatches: [String] = []
    for x in Fixture.shared.inputs {
        let (lv, rules) = CrisisRules.checkInput(x.text)
        if lv.name != x.level || rules != x.rules {
            mismatches.append("\(x.text): swift \(lv.name) \(rules), python \(x.level) \(x.rules)")
        }
    }
    #expect(mismatches.isEmpty, "\(mismatches.count) of \(Fixture.shared.inputs.count):\n\(mismatches.prefix(10).joined(separator: "\n"))")
}

@Test func highPrecisionMatchesPython() {
    let bad = Fixture.shared.inputs.filter { CrisisRules.highPrecision($0.text) != $0.high_precision }.map(\.text)
    #expect(bad.isEmpty, "\(bad.prefix(10))")
}

@Test func stripResourcesMatchesPython() {
    var bad: [String] = []
    for r in Fixture.shared.replies {
        let (text, removed) = CrisisRules.stripResources(r.text)
        if text != r.stripped || removed != r.removed { bad.append(r.text.prefix(80) + "…") }
    }
    #expect(bad.isEmpty, "\(bad.count) of \(Fixture.shared.replies.count): \(bad.prefix(5))")
}

@Test func checkOutputMatchesPython() {
    var bad: [String] = []
    for r in Fixture.shared.replies {
        let (ok, reasons) = CrisisRules.checkOutput(r.stripped, level: level(r.level))
        if ok != r.ok || reasons != r.reasons { bad.append("\(reasons) vs \(r.reasons): " + r.stripped.prefix(60)) }
    }
    #expect(bad.isEmpty, "\(bad.count) of \(Fixture.shared.replies.count): \(bad.prefix(5))")
}

@Test func assessmentFollowsPerLevelRule() {
    // an idiom that fires a crisis rule but not a high-precision one only reaches a check-in
    let idiom = CrisisAssessment(text: "This traffic is killing me.", probabilities: [0.9, 0.05, 0.05])
    #expect(idiom.level == .checkin)
    let explicit = CrisisAssessment(text: "I want to kill myself.", probabilities: [0.9, 0.05, 0.05])
    #expect(explicit.level == .crisis)
    let calm = CrisisAssessment(text: "I just got laid off.", probabilities: [0.8, 0.15, 0.05])
    #expect(calm.level == .none)
}
