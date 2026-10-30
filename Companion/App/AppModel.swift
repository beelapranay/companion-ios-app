import CrisisKit
import Foundation
import HuggingFace
import MLXHuggingFace
import MLXLLM
import MLXLMCommon
import Observation
import Tokenizers

struct ChatMessage: Identifiable {
    enum Role { case user, assistant, crisisCard }

    let id = UUID()
    let role: Role
    var text: String
    var checkIn = CheckIn.none
    var isStreaming = false

    enum CheckIn { case none, asking, okay }
}

/// Everything the chat screen needs: model loading, the conversation, and the crisis layer around every turn.
///
/// Each user message is rated by `CrisisAssessment` (rules + Core ML classifier) before the chat model sees it:
/// - crisis: the fixed crisis screen opens and the chat model is skipped for that message
/// - check-in or none: LFM3 replies; crisis-resource sentences are stripped as the reply streams (the app shows its
///   own verified resources), and the finished reply goes through `CrisisRules.checkOutput`
/// - a check-in line goes under the reply when `SafetyPolicy` allows it
@MainActor @Observable
final class AppModel {
    enum Phase: Equatable {
        case loading(String, Double?)
        case ready
        case failed(String)
    }

    var phase = Phase.loading("Starting…", nil)
    var messages: [ChatMessage] = []
    var showCrisis = false
    var isGenerating = false

    private var session: ChatSession?
    private var classifier: CrisisClassifier?
    private var policy = SafetyPolicy()
    private var userTurns = 0

    static let fallback = """
        I want to be careful here, so I won't go into that. I'm still here with you, though. Would you like to tell \
        me a bit more about what's going on?
        """

    func load() async {
        do {
            phase = .loading("Loading safety checks…", nil)
            guard let modelURL = Bundle.main.url(forResource: "CrisisClassifier", withExtension: "mlmodelc"),
                  let tokenizerFolder = Bundle.main.url(forResource: "CrisisModel", withExtension: nil)
            else { throw AppError.missingCrisisModel }
            classifier = try await CrisisClassifier(modelURL: modelURL, tokenizerFolder: tokenizerFolder)

            phase = .loading("Downloading the language model (about 1 GB, first launch only)…", 0)
            let container = try await #huggingFaceLoadModelContainer(
                configuration: LLMRegistry.lfm3_1_7b_4bit_mlx
            ) { progress in
                Task { @MainActor in
                    self.phase = .loading("Downloading the language model (about 1 GB, first launch only)…",
                                          progress.fractionCompleted)
                }
            }
            // same sampling as the evals: temperature 0.7 over the full vocabulary, thinking off
            session = ChatSession(
                container, instructions: SystemPrompt.v5,
                generateParameters: GenerateParameters(maxTokens: 512, temperature: 0.7, topP: 1.0),
                additionalContext: ["enable_thinking": false])
            phase = .ready
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    func send(_ raw: String) async {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isGenerating, let session, let classifier else { return }
        messages.append(ChatMessage(role: .user, text: text))
        let index = userTurns
        userTurns += 1

        let probs = (try? classifier.probabilities(text)) ?? [0, 1, 0]  // if the classifier fails, check in
        let assessment = CrisisAssessment(text: text, probabilities: probs)

        if assessment.level == .crisis {
            policy.didShowCrisis(index: index)
            messages.append(ChatMessage(role: .crisisCard, text: ""))
            showCrisis = true
            return
        }

        isGenerating = true
        defer { isGenerating = false }
        messages.append(ChatMessage(role: .assistant, text: "", isStreaming: true))
        let slot = messages.count - 1
        var reply = ""
        do {
            for try await chunk in session.streamResponse(to: text) {
                reply += chunk
                messages[slot].text = CrisisRules.stripResources(reply).text
            }
        } catch {
            reply = ""
        }
        let shown = CrisisRules.stripResources(reply).text
        let (ok, _) = CrisisRules.checkOutput(shown, level: assessment.level)
        messages[slot].text = ok && !shown.isEmpty ? shown : Self.fallback
        messages[slot].isStreaming = false
        if policy.shouldCheckIn(assessment, index: index) || (!ok && assessment.level != .none) {
            messages[slot].checkIn = .asking
        }
    }

    func answerCheckIn(_ id: UUID, safe: Bool) {
        guard let i = messages.firstIndex(where: { $0.id == id }) else { return }
        if safe {
            messages[i].checkIn = .okay
        } else {
            policy.didShowCrisis(index: userTurns)
            showCrisis = true
        }
    }
}

enum AppError: LocalizedError {
    case missingCrisisModel

    var errorDescription: String? {
        "The safety model is missing from the app bundle. Run scripts/fetch_models.sh and rebuild."
    }
}
