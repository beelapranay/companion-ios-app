import Foundation
import MemoryKit
import Observation

/// Canned conversations for SwiftUI previews and the CompanionDemo Simulator target, where MLX can't run. Replies
/// are scripted and there is no crisis layer here (a message containing "demo crisis" shows the crisis card), so
/// this must never stand in for `AppModel` in the real app.
@MainActor @Observable
final class PreviewChatModel: ChatModel, MemoryProviding {
    var phase: ModelPhase
    var messages: [ChatMessage]
    var showCrisis = false
    var isGenerating = false

    var memoryFacts: [MemoryFact]
    var memoryDays: [DaySummary]
    var rememberEnabled = true
    var isTakingNotes = false

    private var replyCount = 0

    // in the texting format `Texting.format` gives real replies: lowercase, a line per sentence
    private static let replies = [
        "that sounds like a lot to carry\ni'm here, no rush\nwhat feels heaviest right now?",
        "yeah that makes sense honestly\ndo you wanna talk through what happened, or just get it off your chest?",
        "thanks for telling me\nwhat's one small thing that might make the next hour a bit easier?",
    ]

    init(phase: ModelPhase = .ready, messages: [ChatMessage] = [],
         memoryFacts: [MemoryFact] = MemorySamples.facts(),
         memoryDays: [DaySummary] = MemorySamples.days()) {
        self.phase = phase
        self.messages = messages
        self.memoryFacts = memoryFacts
        self.memoryDays = memoryDays
    }

    func load() async {}

    func send(_ raw: String) async {
        let text = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isGenerating else { return }
        messages.append(ChatMessage(role: .user, text: text))

        if text.localizedStandardContains("demo crisis") {
            messages.append(ChatMessage(role: .crisisCard, text: ""))
            showCrisis = true
            return
        }

        isGenerating = true
        defer { isGenerating = false }
        messages.append(ChatMessage(role: .assistant, text: "", isStreaming: true))
        let slot = messages.count - 1
        try? await Task.sleep(for: .seconds(1.2))

        let reply = Self.replies[replyCount % Self.replies.count]
        for end in reply.indices where reply[end] == " " || reply[end] == "\n" {
            messages[slot].text = String(reply[..<end])
            try? await Task.sleep(for: .milliseconds(70))
        }
        messages[slot].text = reply
        messages[slot].isStreaming = false
        replyCount += 1
        if replyCount % 3 == 0 {
            messages[slot].checkIn = .asking
        }
    }

    func answerCheckIn(_ id: UUID, safe: Bool) {
        guard let index = messages.firstIndex(where: { $0.id == id }) else { return }
        if safe {
            messages[index].checkIn = .okay
        } else {
            showCrisis = true
        }
    }

    // MARK: memory (canned, in memory only)

    func updateMemory(_ id: UUID, text: String) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return deleteMemory(id) }
        guard let index = memoryFacts.firstIndex(where: { $0.id == id }) else { return }
        memoryFacts[index].text = trimmed
        memoryFacts[index].edited = true
    }

    func deleteMemory(_ id: UUID) {
        memoryFacts.removeAll { $0.id == id }
    }

    func wipeMemory() {
        memoryFacts = []
        memoryDays = []
    }

    func loadSampleMemories() {
        memoryFacts = MemorySamples.facts()
        memoryDays = MemorySamples.days()
    }

    /// Pretends to take notes for a moment, so the "noting" state can be seen in the demo.
    func endSession() async {
        guard rememberEnabled, !messages.isEmpty, !isTakingNotes else { return }
        isTakingNotes = true
        try? await Task.sleep(for: .seconds(2))
        isTakingNotes = false
    }
}
