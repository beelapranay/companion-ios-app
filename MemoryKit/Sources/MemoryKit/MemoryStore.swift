import Foundation
import Observation

/// One stored fact about the user. Everything stays on the device.
public struct MemoryFact: Codable, Identifiable, Hashable, Sendable {
    public var id: UUID
    /// person, place, event, plan, theme, feeling, preference or health (as the model labelled it)
    public var type: String
    public var text: String
    /// the time words the user used ("thursday", "last night"), or ""
    public var when: String
    /// suicide, self-harm, eating, abuse, drugs or alcohol, health: hidden by default, "private" in the prompt
    public var sensitive: Bool
    /// when the user said it (the end of that session)
    public var saidAt: Date
    /// the user's message it came from, for "where did this come from?"
    public var source: String
    /// the user changed the text
    public var edited: Bool

    public init(id: UUID = UUID(), type: String, text: String, when: String, sensitive: Bool, saidAt: Date,
                source: String, edited: Bool = false) {
        self.id = id
        self.type = type
        self.text = text
        self.when = when
        self.sensitive = sensitive
        self.saidAt = saidAt
        self.source = source
        self.edited = edited
    }
}

/// Per-day counts for the mood lane: how many messages, and how many the crisis layer rated check-in or crisis.
public struct DaySummary: Codable, Hashable, Sendable {
    public var day: Date
    public var messages: Int
    public var checkins: Int
    public var crises: Int

    public init(day: Date, messages: Int, checkins: Int, crises: Int) {
        self.day = day
        self.messages = messages
        self.checkins = checkins
        self.crises = crises
    }
}

/// The user's stored facts, saved as JSON in Application Support with complete file protection (unreadable while
/// the phone is locked). Holds the facts, the day summaries, and the user messages not yet turned into notes
/// (`pending`), so a session cut short by the app being killed is noted on the next launch.
@MainActor @Observable
public final class MemoryStore {
    public private(set) var facts: [MemoryFact] = []
    public private(set) var days: [DaySummary] = []
    public private(set) var pending: [String] = []

    private let url: URL?
    private let calendar = Calendar.current

    private struct Saved: Codable {
        var facts: [MemoryFact]
        var days: [DaySummary]
        var pending: [String]
    }

    /// `url` nil keeps everything in memory (previews, tests).
    public init(url: URL?) {
        self.url = url
        guard let url, let data = try? Data(contentsOf: url),
              let saved = try? JSONDecoder().decode(Saved.self, from: data) else { return }
        facts = saved.facts
        days = saved.days
        pending = saved.pending
    }

    public static var defaultURL: URL {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        return dir.appendingPathComponent("memory.json")
    }

    private func save() {
        guard let url else { return }
        do {
            try FileManager.default.createDirectory(at: url.deletingLastPathComponent(), withIntermediateDirectories: true)
            let data = try JSONEncoder().encode(Saved(facts: facts, days: days, pending: pending))
            #if os(iOS)
            try data.write(to: url, options: [.atomic, .completeFileProtection])
            #else
            try data.write(to: url, options: .atomic)
            #endif
        } catch {
            // not fatal: memory is a nice-to-have, and the chat keeps working without it
        }
    }

    // MARK: recording a session

    /// Counts one user message for today's summary; non-crisis messages also wait in `pending` to be noted.
    public func record(message: String, level: Int, now: Date = Date()) {
        let day = calendar.startOfDay(for: now)
        if let i = days.firstIndex(where: { $0.day == day }) {
            days[i].messages += 1
            days[i].checkins += level == 1 ? 1 : 0
            days[i].crises += level >= 2 ? 1 : 0
        } else {
            days.append(DaySummary(day: day, messages: 1, checkins: level == 1 ? 1 : 0, crises: level >= 2 ? 1 : 0))
        }
        if level < 2 { pending.append(message) }
        save()
    }

    /// Stores the model's notes on `pending` (run through `MemoryRules.clean`) and clears it. Returns how many were
    /// kept.
    @discardableResult
    public func add(notes raw: [MemoryRules.RawFact], from messages: [String], now: Date = Date()) -> Int {
        let userText = messages.map(MemoryRules.straightQuotes).joined(separator: " ")
        let clean = MemoryRules.clean(raw, userText: userText)
        var added = 0
        for f in clean {
            let lower = f.text.lowercased()
            if facts.contains(where: { $0.text.lowercased() == lower }) { continue }
            let source = messages.max { MemoryRules.grounded(f.text, in: $0) < MemoryRules.grounded(f.text, in: $1) } ?? ""
            facts.append(MemoryFact(type: f.type, text: f.text, when: f.when, sensitive: f.sensitive, saidAt: now,
                                    source: source))
            added += 1
        }
        save()
        return added
    }

    /// Drops the first `count` pending messages (after they were noted, or when remembering is off).
    public func clearPending(_ count: Int? = nil) {
        pending.removeFirst(min(count ?? pending.count, pending.count))
        save()
    }

    // MARK: the user's controls

    public func update(_ id: UUID, text: String) {
        guard let i = facts.firstIndex(where: { $0.id == id }) else { return }
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return delete(id) }
        facts[i].text = t
        facts[i].sensitive = MemoryRules.isSensitive(t)
        facts[i].edited = true
        save()
    }

    public func delete(_ id: UUID) {
        facts.removeAll { $0.id == id }
        save()
    }

    /// Replaces everything with the given facts and days (the "load sample memories" demo); pending is cleared.
    public func replaceAll(facts: [MemoryFact], days: [DaySummary]) {
        self.facts = facts.sorted { $0.saidAt < $1.saidAt }
        self.days = days.sorted { $0.day < $1.day }
        pending = []
        save()
    }

    /// Deletes every fact, day summary and pending message.
    public func wipe() {
        facts = []
        days = []
        pending = []
        save()
    }

    // MARK: what goes into the prompt

    /// Up to `MemoryRules.promptLimit` facts for a reply to `message`: facts that share words with the message
    /// first, then recent ones, with a bonus for pending events from the last week. Facts older than 30 days come in
    /// only when the message is about them. Private facts come in only when the message touches their topic or they
    /// are from the last 7 days.
    public func select(for message: String, now: Date = Date()) -> [MemoryRules.PromptFact] {
        let scored: [(Double, MemoryFact, Int)] = facts.compactMap { f in
            let days = max(0, calendar.dateComponents([.day], from: calendar.startOfDay(for: f.saidAt),
                                                      to: calendar.startOfDay(for: now)).day ?? 0)
            let overlap = MemoryRules.grounded(f.text, in: message)
            if days > 30 && overlap == 0 { return nil }
            if f.sensitive && overlap == 0 && days > 7 { return nil }
            let pendingEvent = !f.when.isEmpty && days <= 7 ? 0.5 : 0
            // any shared word (often a name: "sam") beats recency; more shared words rank higher
            let topic = overlap > 0 ? 1.5 + overlap : 0
            return (topic + exp(-Double(days) / 7) + pendingEvent, f, days)
        }
        return scored.sorted { $0.0 > $1.0 }.prefix(MemoryRules.promptLimit).map {
            MemoryRules.PromptFact(text: $0.1.text, when: $0.1.when, sensitive: $0.1.sensitive, daysAgo: $0.2)
        }
    }
}
