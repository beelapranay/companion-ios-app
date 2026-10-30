import Foundation

/// The crisis layer's risk levels, lowest first.
public enum CrisisLevel: Int, Comparable, Sendable, CaseIterable {
    case none = 0, checkin, crisis

    public var name: String { ["none", "checkin", "crisis"][rawValue] }

    public static func < (a: CrisisLevel, b: CrisisLevel) -> Bool { a.rawValue < b.rawValue }
}

/// Tier 1 of the crisis layer, a Swift port of crisis_layer/rules.py: regex rules, no model.
///
/// The patterns themselves are generated into `RulesData.swift` from the Python source by `export_swift.py`; this
/// file only reproduces how rules.py applies them. `CrisisKitTests` checks the two agree on every test message.
public enum CrisisRules {
    private static func compile(_ pattern: String, _ options: NSRegularExpression.Options = []) -> NSRegularExpression {
        try! NSRegularExpression(pattern: pattern, options: options)  // patterns are generated and tested
    }

    private static let crisis = RulesData.crisis.map { ($0.0, compile($0.1)) }
    private static let checkin = RulesData.checkin.map { ($0.0, compile($0.1)) }
    private static let outputBlock = RulesData.outputBlock.map { ($0.0, compile($0.1)) }
    private static let highPrecisionRules = RulesData.highPrecision.map { compile($0) }
    private static let resource = compile(RulesData.resource, .caseInsensitive)
    private static let sentence = compile(RulesData.sentence, .anchorsMatchLines)
    private static let phone = compile(RulesData.phone)
    private static let letter = compile(RulesData.letter)
    private static let callBefore = compile(#"\b(call|text|dial|at|line)\W*$"#)

    /// rules.py `_norm`: straight apostrophes, collapsed whitespace, trimmed, lowercased.
    public static func normalize(_ text: String) -> String {
        let t = text.replacingOccurrences(of: "\u{2019}", with: "'").replacingOccurrences(of: "\u{2018}", with: "'")
        return t.split(whereSeparator: { $0.isWhitespace }).joined(separator: " ").lowercased()
    }

    private static func matches(_ rx: NSRegularExpression, _ s: String) -> Bool {
        rx.firstMatch(in: s, range: NSRange(s.startIndex..., in: s)) != nil
    }

    /// rules.py `check_input`: the level of a user message and the names of the rules that fired.
    public static func checkInput(_ text: String) -> (level: CrisisLevel, rules: [String]) {
        let t = normalize(text)
        let hits = crisis.filter { matches($0.1, t) }.map(\.0)
        if !hits.isEmpty { return (.crisis, hits) }
        let soft = checkin.filter { matches($0.1, t) }.map(\.0)
        return soft.isEmpty ? (.none, []) : (.checkin, soft)
    }

    /// pipeline.py `high_precision`: rules precise enough to open the crisis screen on their own.
    public static func highPrecision(_ text: String) -> Bool {
        let t = normalize(text)
        return highPrecisionRules.contains { matches($0, t) }
    }

    /// rules.py `strip_resources`: drops every sentence that names a crisis resource (the model garbles them; the
    /// app shows its own verified card) and reports whether anything was removed.
    public static func stripResources(_ reply: String) -> (text: String, removed: Bool) {
        let ns = reply as NSString
        let parts = sentence.matches(in: reply, range: NSRange(location: 0, length: ns.length))
            .map { ns.substring(with: $0.range) }
        let kept = parts.filter { !matches(resource, $0) }
        var out = kept.joined()
        while out.contains("\n\n\n") { out = out.replacingOccurrences(of: "\n\n\n", with: "\n\n") }
        return (out.trimmingCharacters(in: .whitespacesAndNewlines), kept.count < parts.count)
    }

    /// rules.py `check_output`: whether a (resource-stripped) model reply may be shown, and why not.
    public static func checkOutput(_ reply: String, level: CrisisLevel = .none) -> (ok: Bool, reasons: [String]) {
        let t = normalize(reply)
        var reasons = outputBlock.filter { matches($0.1, t) }.map(\.0)
        let scalars = Array(reply.unicodeScalars)
        for m in phone.matches(in: reply, range: NSRange(reply.startIndex..., in: reply)) {
            guard let r = Range(m.range(at: 1), in: reply), let whole = Range(m.range, in: reply) else { continue }
            let number = String(reply[r])
            let digits = number.filter(\.isNumber)
            if RulesData.allowedNumbers.contains(digits) { continue }
            // rules.py looks at the 25 characters (code points) before the match
            let start = reply.unicodeScalars.distance(from: reply.unicodeScalars.startIndex,
                                                      to: whole.lowerBound.samePosition(in: reply.unicodeScalars)
                                                          ?? reply.unicodeScalars.startIndex)
            var before = String.UnicodeScalarView()
            before.append(contentsOf: scalars[max(0, start - 25)..<start])
            let b = normalize(String(before))
            if digits.count >= 7 || (digits.count >= 3 && matches(callBefore, b)) {
                reasons.append("unknown_number:" + number.trimmingCharacters(in: .whitespaces))
            }
        }
        if level != .none && matches(letter, t) { reasons.append("goodbye_letter") }
        return (reasons.isEmpty, reasons)
    }
}
