import Foundation

/// The friend voice's texting format, done in code instead of asked of the model: lowercase, a line break instead of
/// each full stop, no em dashes, no punctuation-only lines. Port of `texting()` in
/// neuron-explorer/sweep/friend_view.py, which the 2026-11-02 evals graded.
///
/// It runs after `CrisisRules.stripResources`, never before: that filter splits sentences at full stops, so with the
/// full stops gone a whole reply would count as one sentence and stripping a crisis-line mention would delete it all.
enum Texting {
    private static let dash = try! NSRegularExpression(pattern: #"\s*[—–]\s*"#)
    // full stops (and quotes or brackets right after them), but not "..."
    private static let stop = try! NSRegularExpression(pattern: #"(?<!\.)\.(?!\.)["')\]]*(\s+|$)"#)
    private static let punctuationOnly = try! NSRegularExpression(pattern: #"^[\s.,;:!?'"()\[\]-]*$"#)

    static func format(_ reply: String) -> String {
        var t = reply.lowercased().replacingOccurrences(of: "**", with: "")
        t = replace(dash, in: t, with: ", ")
        t = replace(stop, in: t, with: "\n")
        return t.components(separatedBy: "\n")
            .map { line in
                var l = line.trimmingCharacters(in: .whitespacesAndNewlines)
                while l.hasSuffix(",") { l.removeLast() }
                return l
            }
            .filter { !$0.isEmpty && !matches(punctuationOnly, $0) }
            .joined(separator: "\n")
    }

    /// Safety net for thinking tags, which are also banned at sampling time: keeps only what follows the last
    /// `</think>` (the 4-bit model sometimes wrote a reply, `</think>`, then the reply again) and drops stray tags.
    static func dropThinking(_ reply: String) -> String {
        var t = reply
        if let end = t.range(of: "</think>", options: .backwards) {
            t = String(t[end.upperBound...])
        }
        return t.replacingOccurrences(of: "<think>", with: "")
    }

    private static func replace(_ rx: NSRegularExpression, in s: String, with template: String) -> String {
        rx.stringByReplacingMatches(in: s, range: NSRange(s.startIndex..., in: s), withTemplate: template)
    }

    private static func matches(_ rx: NSRegularExpression, _ s: String) -> Bool {
        rx.firstMatch(in: s, range: NSRange(s.startIndex..., in: s)) != nil
    }
}
