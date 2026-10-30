import CoreML
import Foundation
import Tokenizers

/// Tier 2 of the crisis layer: the RoBERTa classifier exported by crisis_layer/export_coreml.py.
///
/// The Core ML package is a multifunction model with one fixed-length function per input bucket ("len16" ...
/// "len256"); each message is padded to the smallest bucket that fits. Messages longer than 256 tokens are scored
/// in 256-token windows and the window with the highest risk wins.
public final class CrisisClassifier: @unchecked Sendable {
    public static let lengths = [16, 32, 64, 128, 256]

    private let tokenizer: Tokenizer
    private let models: [Int: MLModel]
    private let padID: Int32

    /// - Parameters:
    ///   - modelURL: the compiled model (`CrisisClassifier.mlmodelc`, as Xcode puts it in the app bundle).
    ///   - tokenizerFolder: a folder holding the classifier's `tokenizer.json` and `tokenizer_config.json`.
    public init(modelURL: URL, tokenizerFolder: URL, padID: Int32 = 1) async throws {
        tokenizer = try await AutoTokenizer.from(modelFolder: tokenizerFolder)
        var models: [Int: MLModel] = [:]
        for L in Self.lengths {
            let config = MLModelConfiguration()
            config.computeUnits = .cpuAndNeuralEngine
            config.functionName = "len\(L)"
            models[L] = try MLModel(contentsOf: modelURL, configuration: config)
        }
        self.models = models
        self.padID = padID
    }

    /// The classifier's token ids for a message, as the Python tokenizer gives them with truncation to `maxLength`
    /// (start and end tokens kept).
    public func ids(_ text: String, maxLength: Int = 256) -> [Int] {
        let ids = tokenizer.encode(text: text)
        guard ids.count > maxLength else { return ids }
        return [ids[0]] + ids[1..<(maxLength - 1)] + [ids[ids.count - 1]]
    }

    /// P(none), P(checkin), P(crisis) for one message.
    public func probabilities(_ text: String) throws -> [Double] {
        let all = tokenizer.encode(text: text)
        guard all.count > 256 else { return try score(all) }
        let body = Array(all[1..<(all.count - 1)])
        var best = [1.0, 0.0, 0.0]
        for start in stride(from: 0, to: body.count, by: 254) {
            let window = [all[0]] + body[start..<min(start + 254, body.count)] + [all[all.count - 1]]
            let p = try score(window)
            if p[1] + p[2] > best[1] + best[2] { best = p }
        }
        return best
    }

    private func score(_ ids: [Int]) throws -> [Double] {
        let L = Self.lengths.first { $0 >= ids.count } ?? 256
        let input = try MLMultiArray(shape: [1, NSNumber(value: L)], dataType: .int32)
        let mask = try MLMultiArray(shape: [1, NSNumber(value: L)], dataType: .int32)
        for i in 0..<L {
            input[i] = NSNumber(value: i < ids.count ? Int32(ids[i]) : padID)
            mask[i] = NSNumber(value: i < ids.count ? 1 : 0)
        }
        let features = try MLDictionaryFeatureProvider(dictionary: ["input_ids": input, "attention_mask": mask])
        guard let model = models[L],
              let probs = try model.prediction(from: features).featureValue(for: "probs")?.multiArrayValue
        else { throw CocoaError(.featureUnsupported) }
        return (0..<3).map { probs[$0].doubleValue }
    }
}

/// The crisis layer's input check, a port of crisis_layer/pipeline.py `combine`: each level has its own trigger.
/// - crisis screen: P(crisis) >= tCrisis, or a high-precision rule
/// - check-in: P(checkin) + P(crisis) >= tRisk, or any other rule (rules alone fire on idioms such as "this
///   traffic is killing me", so outside the high-precision list they never reach the crisis screen)
public struct CrisisAssessment: Sendable {
    /// Check-in and crisis-screen thresholds, set on real-text validation (crisis_layer/eval_pipeline.py).
    public static let tRisk = RulesData.tRisk
    public static let tCrisis = RulesData.tCrisis

    public let level: CrisisLevel
    public let probabilities: [Double]
    public let rules: [String]
    public let highPrecision: Bool

    public init(text: String, probabilities p: [Double],
                tRisk: Double = CrisisAssessment.tRisk, tCrisis: Double = CrisisAssessment.tCrisis) {
        let (ruleLevel, rules) = CrisisRules.checkInput(text)
        let hp = CrisisRules.highPrecision(text)
        let clf: CrisisLevel = p[2] >= tCrisis ? .crisis : (p[1] + p[2] >= tRisk ? .checkin : .none)
        if clf == .crisis || hp {
            level = .crisis
        } else if ruleLevel != .none || clf == .checkin {
            level = .checkin
        } else {
            level = .none
        }
        probabilities = p
        self.rules = rules
        highPrecision = hp
    }
}
