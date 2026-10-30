import CoreML
import Foundation
import Testing

@testable import CrisisKit

/// Runs the real Core ML classifier from Swift and compares it with the PyTorch model (probabilities in
/// rules_fixture.json). Needs the exported model, which is not in git: set CRISIS_COREML_DIR to a folder holding
/// CrisisClassifier.mlpackage, tokenizer.json and tokenizer_config.json (crisis_layer/coreml).
private let coremlDir = ProcessInfo.processInfo.environment["CRISIS_COREML_DIR"].map { URL(fileURLWithPath: $0) }

private func loadClassifier(_ dir: URL) async throws -> CrisisClassifier {
    let compiled = try await MLModel.compileModel(at: dir.appendingPathComponent("CrisisClassifier.mlpackage"))
    return try await CrisisClassifier(modelURL: compiled, tokenizerFolder: dir)
}

@Test(.enabled(if: coremlDir != nil, "set CRISIS_COREML_DIR"))
func tokenizerMatchesPython() async throws {
    let clf = try await loadClassifier(coremlDir!)
    let bad = Fixture.shared.inputs.filter { clf.ids($0.text) != $0.ids }.map(\.text)
    #expect(bad.isEmpty, "\(bad.count) differ: \(bad.prefix(5))")
}

@Test(.enabled(if: coremlDir != nil, "set CRISIS_COREML_DIR"))
func probabilitiesMatchPyTorch() async throws {
    let clf = try await loadClassifier(coremlDir!)
    var worst = 0.0
    var levelFlips: [String] = []
    for x in Fixture.shared.inputs {
        let p = try clf.probabilities(x.text)
        worst = max(worst, zip(p, x.probs).map { abs($0 - $1) }.max()!)
        if CrisisAssessment(text: x.text, probabilities: p).level
            != CrisisAssessment(text: x.text, probabilities: x.probs).level {
            levelFlips.append(x.text)
        }
    }
    print("max |dP| vs PyTorch: \(worst); level flips: \(levelFlips)")
    #expect(worst < 0.05)
    #expect(levelFlips.count <= 3, "\(levelFlips)")
}
