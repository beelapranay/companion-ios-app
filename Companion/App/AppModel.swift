import CrisisKit
import Foundation
import HuggingFace
import MemoryKit
import MLXHuggingFace
import MLXLLM
import MLXLMCommon
import Observation
import Tokenizers
import UIKit

/// Everything the chat screen needs: model loading, the conversation, and the crisis layer around every turn.
///
/// Each user message is rated by `CrisisAssessment` (rules + Core ML classifier) before the chat model sees it:
/// - crisis: the fixed crisis screen opens and the chat model is skipped for that message
/// - check-in or none: LFM3 replies with the system prompt for that level (`SystemPrompt.finetuned(level:)` for the
///   bundled fine-tuned model, or `.calm` / `.friend` for the base model from the Hub);
///   crisis-resource sentences are stripped as the reply streams (the app shows its own verified resources), the
///   finished reply goes through `CrisisRules.checkOutput`, and `Texting.format` applies the texting style last
/// - a check-in line goes under the reply when `SafetyPolicy` allows it
///
/// The system prompt changes per message, so each turn starts a `ChatSession` from the saved history and prefills
/// it again; the history keeps the last `historyLimit` messages. Crisis turns stay out of it, since the model never
/// answered them.
///
/// Memory (MemoryKit): every non-crisis user message waits in the store's `pending`; when the session ends
/// (`endSession`, called as the app goes to the background) or on the next launch, the chat model takes notes on those
/// messages alone (`MemoryRules.extractionSystem`, never the friend's lines), and the notes are grounded, flagged and
/// redacted in code before they are stored. With `memoryInPrompt`, up to five stored facts go into the system prompt
/// as the "known from earlier chats" block the v4 model was trained on.
@MainActor @Observable
final class AppModel: ChatModel, MemoryProviding {
    typealias Phase = ModelPhase

    var phase = Phase.loading("Starting…", nil)
    var messages: [ChatMessage] = []
    var showCrisis = false
    var isGenerating = false

    private var container: ModelContainer?
    private var history: [Chat.Message] = []
    private var thinkingTokens: Set<Int> = []
    private var classifier: CrisisClassifier?
    private var policy = SafetyPolicy()
    private var userTurns = 0

    private let memory = MemoryStore(url: MemoryStore.defaultURL)
    private(set) var isTakingNotes = false
    var rememberEnabled = UserDefaults.standard.object(forKey: "rememberEnabled") as? Bool ?? true {
        didSet {
            UserDefaults.standard.set(rememberEnabled, forKey: "rememberEnabled")
            if !rememberEnabled { memory.clearPending() }
        }
    }

    /// Facts go into the reply prompt only for a friend model trained with the memory block (v4). v3 (bundled now)
    /// was not, so it only takes notes.
    static let memoryInPrompt = false
    /// greedy decoding for notes, as in the extraction eval
    static let noteParameters = GenerateParameters(maxTokens: 600, temperature: 0)
    /// notes are also taken mid-session once this many messages are waiting
    static let notesEvery = 20

    /// The bundled fine-tuned "friend" model (`Resources/FriendModel`: v3 by default, copied in by
    /// scripts/fetch_models.sh; `FRIEND_VERSION=v2` there restores the v2 backup).
    /// Set to false to go back to the base LFM3 from the Hugging Face Hub with the `friend` / `calm` prompts.
    static let useFineTuned = true

    static let fallback = "i wanna be careful with that one, so i'm not gonna go into it\nbut i'm still here, what's going on?"
    static let historyLimit = 12
    // same sampling as the evals: temperature 0.7 over the full vocabulary, thinking off. The fine-tuned model's
    // replies are about 20 words, so 160 tokens is plenty; the base model keeps the evals' 512.
    static let parameters = GenerateParameters(
        maxTokens: useFineTuned ? 160 : 512, temperature: 0.7, topP: 1.0)

    func load() async {
        do {
            phase = .loading("Loading safety checks…", nil)
            guard let modelURL = Bundle.main.url(forResource: "CrisisClassifier", withExtension: "mlmodelc"),
                  let tokenizerFolder = Bundle.main.url(forResource: "CrisisModel", withExtension: nil)
            else { throw AppError.missingCrisisModel }
            classifier = try await CrisisClassifier(modelURL: modelURL, tokenizerFolder: tokenizerFolder)

            let container = try await loadChatModel()
            // The 4-bit model sometimes writes <think> or </think> even with thinking off; ban both at sampling.
            thinkingTokens = await container.perform { context in
                Set(["<think>", "</think>"].compactMap { context.tokenizer.convertTokenToId($0) })
            }
            self.container = container
            phase = .ready
            if !memory.pending.isEmpty { await takeNotes() }  // a session the app was killed in
        } catch {
            phase = .failed(error.localizedDescription)
        }
    }

    func send(_ raw: String) async {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isGenerating, let container, let classifier else { return }
        while isTakingNotes { try? await Task.sleep(for: .milliseconds(100)) }  // notes and replies share the model
        messages.append(ChatMessage(role: .user, text: text))
        let index = userTurns
        userTurns += 1

        let probs = (try? classifier.probabilities(text)) ?? [0, 1, 0]  // if the classifier fails, check in
        let assessment = CrisisAssessment(text: text, probabilities: probs)
        if rememberEnabled { memory.record(message: text, level: assessment.level.rawValue) }

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
        var prompt = Self.useFineTuned
            ? SystemPrompt.finetuned(level: assessment.level)
            : assessment.level == .none ? SystemPrompt.friend : SystemPrompt.calm
        if Self.useFineTuned && Self.memoryInPrompt && rememberEnabled {
            prompt += MemoryRules.knownBlock(memory.select(for: text))
        }
        let turns: [Chat.Message] = [.system(prompt)] + history
        let session = ChatSession(
            container, history: turns, generateParameters: Self.parameters, components: components(),
            additionalContext: ["enable_thinking": false])
        var reply = ""
        do {
            for try await chunk in session.streamResponse(to: text) {
                reply += chunk
                messages[slot].text = Texting.format(CrisisRules.stripResources(Texting.dropThinking(reply)).text)
            }
        } catch {
            reply = ""
        }
        let kept = CrisisRules.stripResources(Texting.dropThinking(reply)).text
        let (ok, _) = CrisisRules.checkOutput(kept, level: assessment.level)
        let shown = Texting.format(kept)
        let usable = ok && !shown.isEmpty
        messages[slot].text = usable ? shown : Self.fallback
        messages[slot].isStreaming = false
        // the model sees its own filtered reply, or the fallback when that was shown instead
        history += [.user(text), .assistant(usable ? kept : Self.fallback)]
        history = Array(history.suffix(Self.historyLimit))
        if policy.shouldCheckIn(assessment, index: index) || (!ok && assessment.level != .none) {
            messages[slot].checkIn = .asking
        }
        isGenerating = false
        if memory.pending.count >= Self.notesEvery { await takeNotes() }
    }

    /// Bans <think> and </think> at sampling (the 4-bit model sometimes writes them even with thinking off).
    private func components() -> GenerationComponents {
        var components = GenerationComponents()
        let banned = thinkingTokens
        if !banned.isEmpty {
            components.logitProcessorFactory = { SuppressTokensProcessor(tokenIds: banned)! }
        }
        return components
    }

    // MARK: memory

    var memoryFacts: [MemoryFact] { memory.facts }
    var memoryDays: [DaySummary] { memory.days }
    func updateMemory(_ id: UUID, text: String) { memory.update(id, text: text) }
    func deleteMemory(_ id: UUID) { memory.delete(id) }
    func wipeMemory() { memory.wipe() }
    func loadSampleMemories() { memory.replaceAll(facts: MemorySamples.facts(), days: MemorySamples.days()) }

    func endSession() async {
        guard !memory.pending.isEmpty else { return }
        // iOS gives a backgrounded app a few seconds; ask for the time the notes take (about 2 s on a laptop)
        let task = UIApplication.shared.beginBackgroundTask(withName: "memory-notes")
        await takeNotes()
        if task != .invalid { UIApplication.shared.endBackgroundTask(task) }
    }

    /// Takes notes on the pending messages with the chat model, the user's messages only. If the output isn't
    /// valid notes the messages are dropped rather than retried, so a bad batch can't block memory forever.
    private func takeNotes() async {
        guard rememberEnabled, let container, !isTakingNotes, !isGenerating, !memory.pending.isEmpty else { return }
        isTakingNotes = true
        defer { isTakingNotes = false }
        let batch = memory.pending
        let session = ChatSession(
            container, history: [.system(MemoryRules.extractionSystem)], generateParameters: Self.noteParameters,
            components: components(), additionalContext: ["enable_thinking": false])
        let output = (try? await session.respond(to: MemoryRules.extractionPrompt(userMessages: batch))) ?? ""
        if let notes = MemoryRules.parse(Texting.dropThinking(output)) {
            memory.add(notes: notes, from: batch)
        }
        memory.clearPending(batch.count)
    }

    /// The fine-tuned model loads from the app bundle (nothing to download); the base model comes from the Hub on
    /// first launch.
    private func loadChatModel() async throws -> ModelContainer {
        if Self.useFineTuned {
            phase = .loading("Loading the language model…", nil)
            guard let folder = Bundle.main.url(forResource: "FriendModel", withExtension: nil)
            else { throw AppError.missingChatModel }
            return try await loadModelContainer(from: folder, using: #huggingFaceTokenizerLoader())
        }
        phase = .loading("Downloading the language model (about 1 GB, first launch only)…", 0)
        return try await #huggingFaceLoadModelContainer(
            configuration: LLMRegistry.lfm3_1_7b_4bit_mlx
        ) { progress in
            Task { @MainActor in
                self.phase = .loading("Downloading the language model (about 1 GB, first launch only)…",
                                      progress.fractionCompleted)
            }
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
    case missingChatModel

    var errorDescription: String? {
        switch self {
        case .missingCrisisModel:
            "The safety model is missing from the app bundle. Run scripts/fetch_models.sh and rebuild."
        case .missingChatModel:
            "The chat model is missing from the app bundle. Run scripts/fetch_models.sh and rebuild."
        }
    }
}
