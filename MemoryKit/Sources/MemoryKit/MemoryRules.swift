import Foundation

/// The rules for what gets stored about the user, ported from memory/memory_core.py and memory/extract_eval.py
/// (the Python is the source of truth; `MemoryRulesData` is generated from it and the tests check parity):
/// - the model takes notes from the user's own messages only (`extractionPrompt`), never the friend's
/// - a note is kept only if most of its content words appear in the user's messages (`grounded`)
/// - `sensitive` is set by keywords in code, never by the model
/// - sensitive notes keep what happened but lose numbers, amounts and drug names (`redact`)
public enum MemoryRules {
    public static let extractionSystem = MemoryRulesData.extractionSystem
    public static let minGrounding = 0.5
    public static let promptLimit = 5

    private static let sensitiveRx = try! NSRegularExpression(pattern: MemoryRulesData.sensitive)
    private static let drugsRx = try! NSRegularExpression(pattern: MemoryRulesData.drugs, options: .caseInsensitive)
    private static let redactions = MemoryRulesData.redactions.map {
        (try! NSRegularExpression(pattern: $0.0, options: .caseInsensitive), $0.1)
    }
    private static let wordRx = try! NSRegularExpression(pattern: "[a-z0-9']+")
    private static let fenceRx = try! NSRegularExpression(pattern: "^```(json)?|```$")
    private static let objectRx = try! NSRegularExpression(pattern: #"\{.*\}"#, options: .dotMatchesLineSeparators)

    /// Curly quotes to straight ones, as the Python QUOTES table does.
    public static func straightQuotes(_ s: String) -> String {
        s.replacingOccurrences(of: "\u{2018}", with: "'").replacingOccurrences(of: "\u{2019}", with: "'")
            .replacingOccurrences(of: "\u{201C}", with: "\"").replacingOccurrences(of: "\u{201D}", with: "\"")
    }

    /// The user message for the note-taking call: the user's messages of one session, numbered.
    public static func extractionPrompt(userMessages: [String]) -> String {
        let lines = userMessages.enumerated().map { i, m in
            "\(i + 1). " + straightQuotes(m).replacingOccurrences(of: "\n", with: " / ")
        }
        return "User's messages:\n" + lines.joined(separator: "\n")
    }

    static func matches(_ rx: NSRegularExpression, _ s: String) -> [String] {
        rx.matches(in: s, range: NSRange(s.startIndex..., in: s)).compactMap { Range($0.range, in: s).map { String(s[$0]) } }
    }

    /// Content words: lowercased, "'s" removed, stop words and one-letter words dropped.
    public static func words(_ text: String) -> [String] {
        let t = text.lowercased().replacingOccurrences(of: "'s", with: "")
        return matches(wordRx, t).filter { !MemoryRulesData.stopWords.contains($0) && $0.count > 1 }
    }

    /// Share of the fact's content words (5-letter prefixes, so other word forms count) found in `userText`.
    public static func grounded(_ fact: String, in userText: String) -> Double {
        let ws = words(fact)
        guard !ws.isEmpty else { return 0 }
        let prefixes = Set(words(userText).map { String($0.prefix(5)) })
        return Double(ws.filter { prefixes.contains(String($0.prefix(5))) }.count) / Double(ws.count)
    }

    public static func isSensitive(_ text: String) -> Bool {
        let low = text.lowercased()
        return sensitiveRx.firstMatch(in: low, range: NSRange(low.startIndex..., in: low)) != nil
            || drugsRx.firstMatch(in: text, range: NSRange(text.startIndex..., in: text)) != nil
    }

    public static func redact(_ text: String) -> String {
        var t = straightQuotes(text)
        for (rx, template) in redactions {
            t = rx.stringByReplacingMatches(in: t, range: NSRange(t.startIndex..., in: t), withTemplate: template)
        }
        return t.trimmingCharacters(in: CharacterSet(charactersIn: " ,"))
    }

    /// A note as the model wrote it (parsed from its JSON).
    public struct RawFact: Equatable, Sendable {
        public var type: String
        public var text: String
        public var when: String
    }

    /// The model's notes, or nil if the output isn't JSON of the form {"facts": [...]}.
    public static func parse(_ output: String) -> [RawFact]? {
        var t = output.trimmingCharacters(in: .whitespacesAndNewlines)
        t = fenceRx.stringByReplacingMatches(in: t, range: NSRange(t.startIndex..., in: t), withTemplate: "")
        t = t.trimmingCharacters(in: .whitespacesAndNewlines)
        var obj = try? JSONSerialization.jsonObject(with: Data(t.utf8), options: [.fragmentsAllowed])
        if obj == nil {
            guard let m = objectRx.firstMatch(in: t, range: NSRange(t.startIndex..., in: t)),
                  let r = Range(m.range, in: t) else { return nil }
            obj = try? JSONSerialization.jsonObject(with: Data(t[r].utf8))
        }
        guard let dict = obj as? [String: Any], let facts = dict["facts"] as? [Any] else { return nil }
        return facts.compactMap { item in
            guard let f = item as? [String: Any], let text = f["text"] as? String,
                  !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else { return nil }
            return RawFact(type: f["type"] as? String ?? "theme", text: text, when: f["when"] as? String ?? "")
        }
    }

    /// A note after the code-side rules: grounded, flagged, redacted.
    public struct CleanFact: Equatable, Sendable {
        public var type: String
        public var text: String
        public var when: String
        public var sensitive: Bool
    }

    public static func clean(_ facts: [RawFact], userText: String) -> [CleanFact] {
        facts.compactMap { f in
            let text = f.text.trimmingCharacters(in: .whitespacesAndNewlines)
            guard !text.isEmpty, grounded(text, in: userText) >= minGrounding else { return nil }
            let sensitive = isSensitive(text)
            return CleanFact(type: f.type, text: sensitive ? redact(text) : text, when: f.when, sensitive: sensitive)
        }
    }

    /// One line of the prompt's memory block.
    public struct PromptFact: Equatable, Sendable {
        public var text: String
        public var when: String
        public var sensitive: Bool
        public var daysAgo: Int
        public init(text: String, when: String, sensitive: Bool, daysAgo: Int) {
            self.text = text
            self.when = when
            self.sensitive = sensitive
            self.daysAgo = daysAgo
        }
    }

    /// The lines appended to the system prompt, exactly as in training (memory_core.known_block); "" when empty.
    public static func knownBlock(_ facts: [PromptFact]) -> String {
        guard !facts.isEmpty else { return "" }
        let lines = facts.prefix(promptLimit).map { f -> String in
            var tags: [String] = []
            if !f.when.isEmpty { tags.append(f.when) }
            if f.sensitive { tags.append("private") }
            tags.append(f.daysAgo == 0 ? "said today" : f.daysAgo == 1 ? "said yesterday" : "said \(f.daysAgo) days ago")
            return "- \(f.text.lowercased()) (\(tags.joined(separator: ", ")))"
        }
        return "\nknown from earlier chats:\n" + lines.joined(separator: "\n")
    }
}
