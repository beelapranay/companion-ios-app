import Foundation
import MemoryKit
import Observation

/// What the memory views (the "your life" timeline, fact sheets, settings) need. `AppModel` is the real one;
/// `PreviewChatModel` serves canned facts. Every stored fact is visible to the user and can be edited or deleted;
/// nothing leaves the phone.
@MainActor
protocol MemoryProviding: AnyObject, Observable {
    /// all stored facts, oldest first
    var memoryFacts: [MemoryFact] { get }
    /// one entry per day the user chatted, oldest first: message count and how many the crisis layer rated
    /// check-in or crisis (the mood lane)
    var memoryDays: [DaySummary] { get }
    /// "remember things": off stops note-taking and keeps facts out of replies (stored facts stay until wiped)
    var rememberEnabled: Bool { get set }
    /// the model is taking notes on the last session right now
    var isTakingNotes: Bool { get }

    func updateMemory(_ id: UUID, text: String)
    func deleteMemory(_ id: UUID)
    /// deletes every fact and day summary
    func wipeMemory()
    /// replaces the store with `MemorySamples` (a hardcoded 10-day graph) so the timeline can be tried on a device
    func loadSampleMemories()
    /// call when the app goes to the background: takes notes on the session's messages
    func endSession() async
}
