import Foundation
import Testing

@testable import MemoryKit

/// memory_fixture.json holds what the Python rules returned (memory/export_swift.py) on real notes from the evals.
struct Fixture: Decodable {
    struct Fact: Decodable {
        let text: String
        let sensitive: Bool
        let redacted: String
        let words: [String]
    }

    struct Grounding: Decodable {
        let fact: String
        let user: String
        let score: Double
    }

    struct CleanFact: Decodable {
        let type: String
        let text: String
        let when: String
        let sensitive: Bool
    }

    struct Clean: Decodable {
        let raw: String
        let user: String
        let parsed: Bool
        let facts: [CleanFact]?
    }

    struct BlockFact: Decodable {
        let text: String
        let when: String
        let sensitive: Bool
        let days_ago: Int
    }

    struct Block: Decodable {
        let facts: [BlockFact]
        let block: String
    }

    let facts: [Fact]
    let grounding: [Grounding]
    let clean: [Clean]
    let blocks: [Block]

    static let shared: Fixture = {
        let url = Bundle.module.url(forResource: "memory_fixture", withExtension: "json", subdirectory: "Resources")!
        return try! JSONDecoder().decode(Fixture.self, from: Data(contentsOf: url))
    }()
}

@Test func sensitiveRedactAndWordsMatchPython() {
    var bad: [String] = []
    for f in Fixture.shared.facts {
        if MemoryRules.isSensitive(f.text) != f.sensitive { bad.append("sensitive \(f.sensitive): \(f.text)") }
        if MemoryRules.redact(f.text) != f.redacted { bad.append("redact: \(f.text) -> \(MemoryRules.redact(f.text))") }
        if MemoryRules.words(f.text) != f.words { bad.append("words: \(f.text)") }
    }
    #expect(bad.isEmpty, "\(bad.count) mismatches, first: \(bad.prefix(5))")
}

@Test func groundingMatchesPython() {
    let bad = Fixture.shared.grounding.filter { abs(MemoryRules.grounded($0.fact, in: $0.user) - $0.score) > 1e-9 }
    #expect(bad.isEmpty, "\(bad.count) mismatches, first: \(bad.prefix(3).map(\.fact))")
}

@Test func parseAndCleanMatchPython() {
    var bad: [String] = []
    for c in Fixture.shared.clean {
        let parsed = MemoryRules.parse(c.raw)
        if (parsed != nil) != c.parsed { bad.append("parsed \(c.parsed): \(c.raw.prefix(80))"); continue }
        guard let parsed, let want = c.facts else { continue }
        let got = MemoryRules.clean(parsed, userText: c.user)
        let same = got.count == want.count && zip(got, want).allSatisfy {
            $0.text == $1.text && $0.type == $1.type && $0.when == $1.when && $0.sensitive == $1.sensitive
        }
        if !same { bad.append("clean: \(c.raw.prefix(80))") }
    }
    #expect(bad.isEmpty, "\(bad.count) mismatches, first: \(bad.prefix(3))")
}

@Test func knownBlockMatchesPython() {
    for b in Fixture.shared.blocks {
        let facts = b.facts.map {
            MemoryRules.PromptFact(text: $0.text, when: $0.when, sensitive: $0.sensitive, daysAgo: $0.days_ago)
        }
        #expect(MemoryRules.knownBlock(facts) == b.block)
    }
}

@Test func extractionPromptNumbersMessages() {
    let p = MemoryRules.extractionPrompt(userMessages: ["hi", "my roommate\u{2019}s cat\nis loud"])
    #expect(p == "User's messages:\n1. hi\n2. my roommate's cat / is loud")
}

@MainActor @Test func storeAddsGroundedNotesAndPersists() throws {
    let url = FileManager.default.temporaryDirectory.appendingPathComponent("memory-\(UUID()).json")
    defer { try? FileManager.default.removeItem(at: url) }
    let store = MemoryStore(url: url)
    let messages = ["my orgo exam is on thursday", "also i took 20 tylenol last night"]
    for m in messages { store.record(message: m, level: 1) }
    store.record(message: "crisis message", level: 2)
    #expect(store.pending == messages)  // crisis-level messages are never noted
    let added = store.add(notes: [
        .init(type: "event", text: "has an orgo exam", when: "thursday"),
        .init(type: "health", text: "took 20 tylenol", when: "last night"),
        .init(type: "person", text: "has a sister named jo", when: ""),  // not in the messages: dropped
    ], from: store.pending)
    store.clearPending(messages.count)
    #expect(added == 2)
    #expect(store.facts.map(\.text) == ["has an orgo exam", "took pills"])
    #expect(store.facts.map(\.sensitive) == [false, true])
    #expect(store.facts[1].source == messages[1])
    #expect(store.days.first?.messages == 3 && store.days.first?.checkins == 2 && store.days.first?.crises == 1)

    let again = MemoryStore(url: url)
    #expect(again.facts == store.facts && again.pending.isEmpty)
    again.update(again.facts[0].id, text: "has an orgo exam on friday")
    #expect(again.facts[0].edited && !again.facts[0].sensitive)
    again.wipe()
    #expect(MemoryStore(url: url).facts.isEmpty)
}

@MainActor @Test func selectPrefersRelevantAndHidesOldPrivate() {
    let store = MemoryStore(url: nil)
    let now = Date()
    let day: TimeInterval = 86_400
    _ = store.add(notes: [.init(type: "event", text: "has an orgo exam", when: "thursday")],
                  from: ["orgo exam thursday"], now: now - 2 * day)
    _ = store.add(notes: [.init(type: "person", text: "roommate sam eats their food", when: "")],
                  from: ["roommate sam eats my food"], now: now - 20 * day)
    _ = store.add(notes: [.init(type: "feeling", text: "has thoughts of ending their life", when: "")],
                  from: ["i have thoughts of ending my life"], now: now - 12 * day)
    _ = store.add(notes: [.init(type: "place", text: "moved to boston", when: "")],
                  from: ["i moved to boston"], now: now - 40 * day)
    let picked = store.select(for: "heyy", now: now).map(\.text)
    #expect(picked.first == "has an orgo exam")
    #expect(!picked.contains("has thoughts of ending their life"))  // private, 12 days old, not the topic
    #expect(!picked.contains("moved to boston"))  // 40 days old, not the topic
    #expect(store.select(for: "sam did it again", now: now).first?.text == "roommate sam eats their food")
    #expect(store.select(for: "still thinking about ending my life", now: now).map(\.text)
        .contains("has thoughts of ending their life"))
}
