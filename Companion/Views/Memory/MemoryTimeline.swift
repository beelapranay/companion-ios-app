import Foundation
import MemoryKit

/// How far the timeline is zoomed out: one column per day, week or month. Pinching moves between these.
enum TimelineZoom: String, CaseIterable, Identifiable {
    case days, weeks, months

    var id: Self { self }

    var title: LocalizedStringResource {
        switch self {
        case .days: "days"
        case .weeks: "weeks"
        case .months: "months"
        }
    }

    var component: Calendar.Component {
        switch self {
        case .days: .day
        case .weeks: .weekOfYear
        case .months: .month
        }
    }

    var zoomedIn: TimelineZoom {
        switch self {
        case .days, .weeks: .days
        case .months: .weeks
        }
    }

    var zoomedOut: TimelineZoom {
        switch self {
        case .days: .weeks
        case .weeks, .months: .months
        }
    }
}

/// The timeline's rows under the mood lane. Places, preferences and health sit with themes and feelings.
enum MemoryLane: String, CaseIterable, Identifiable, Hashable {
    case people, happenings, mind

    var id: Self { self }

    var title: LocalizedStringResource {
        switch self {
        case .people: "people"
        case .happenings: "what's happening"
        case .mind: "on your mind"
        }
    }

    init(type: String) {
        switch type {
        case "person": self = .people
        case "event", "plan": self = .happenings
        default: self = .mind
        }
    }
}

/// How a stretch of days felt, from the crisis layer's per-day counts. Deliberately coarse, never shown as a number.
enum MoodTone {
    case quiet, lighter, mixed, heavier

    init(messages: Int, heavy: Int) {
        guard messages > 0 else { self = .quiet; return }
        let share = Double(heavy) / Double(messages)
        self = share == 0 ? .lighter : share < 0.34 ? .mixed : .heavier
    }

    var description: LocalizedStringResource {
        switch self {
        case .quiet: "no chats"
        case .lighter: "a lighter stretch"
        case .mixed: "a mixed stretch"
        case .heavier: "a heavier stretch"
        }
    }
}

/// One column of the timeline: a day, week or month, with the facts noted in it and how it felt.
struct TimelineBucket: Identifiable {
    let start: Date
    let end: Date
    var facts: [MemoryFact] = []
    var messages = 0
    var heavy = 0

    var id: Date { start }
    var mood: MoodTone { MoodTone(messages: messages, heavy: heavy) }
    var isEmpty: Bool { facts.isEmpty && messages == 0 }

    func facts(in lane: MemoryLane) -> [MemoryFact] {
        facts.filter { MemoryLane(type: $0.type) == lane }
    }

    /// The people lane shows names, once each per column. Private facts never give a name; they show as a
    /// placeholder instead.
    var people: [String] {
        var seen: [String] = []
        for fact in facts(in: .people) where !fact.sensitive {
            if let name = PersonName.of(fact.text), !seen.contains(name) { seen.append(name) }
        }
        return seen
    }

    func contains(_ date: Date) -> Bool {
        date >= start && date < end
    }
}

extension TimelineBucket {
    /// Columns from the first day anything was noted up to today, with no gaps, so time reads left to right.
    static func build(facts: [MemoryFact], days: [DaySummary], zoom: TimelineZoom, now: Date = .now,
                      calendar: Calendar = .current) -> [TimelineBucket] {
        let dates = facts.map(\.saidAt) + days.map(\.day)
        guard let earliest = dates.min(),
              var cursor = calendar.dateInterval(of: zoom.component, for: earliest)?.start
        else { return [] }

        var buckets: [TimelineBucket] = []
        // a cap so a corrupt date can't build an endless axis (about three years of days)
        while cursor <= now, buckets.count < 1_100 {
            guard let interval = calendar.dateInterval(of: zoom.component, for: cursor) else { break }
            buckets.append(TimelineBucket(start: interval.start, end: interval.end))
            cursor = interval.end
        }

        for fact in facts.sorted(by: { $0.saidAt < $1.saidAt }) {
            if let i = buckets.firstIndex(where: { $0.contains(fact.saidAt) }) { buckets[i].facts.append(fact) }
        }
        for day in days {
            if let i = buckets.firstIndex(where: { $0.contains(day.day) }) {
                buckets[i].messages += day.messages
                buckets[i].heavy += day.checkins + day.crises
            }
        }
        return buckets
    }
}

/// Picks the person a "person" fact is about, simply: the first word, skipping "my"/"the" and a relation word
/// followed by a name ("roommate sam keeps…" is sam, "mom is visiting" is mom, "sam's birthday" is sam).
enum PersonName {
    private static let determiners: Set<String> = ["my", "the", "a", "an", "her", "his", "their", "our", "your"]
    private static let relations: Set<String> = [
        "roommate", "flatmate", "mom", "mum", "dad", "sister", "brother", "friend", "bestie", "boss", "manager",
        "partner", "boyfriend", "girlfriend", "bf", "gf", "wife", "husband", "ex", "coworker", "colleague",
        "classmate", "teacher", "professor", "coach", "therapist", "doctor", "cousin", "aunt", "uncle", "grandma",
        "grandpa", "son", "daughter", "neighbor", "neighbour", "kid",
    ]
    /// words that end a name, so "mom is visiting" stays "mom"
    private static let notNames: Set<String> = [
        "is", "was", "are", "were", "has", "had", "have", "and", "who", "will", "would", "can", "could", "should",
        "might", "may", "keeps", "kept", "wants", "wanted", "said", "says", "got", "gets", "does", "did", "doesn't",
        "didn't", "can't", "won't", "isn't", "wasn't", "thinks", "thought", "called", "texted", "told", "tells",
        "asked", "asks", "just", "always", "never", "still", "really", "to", "of", "in", "on", "at", "with", "from",
        "for", "be", "been", "moved", "left", "loves", "hates", "likes", "feels", "made", "makes", "took", "takes",
        "went", "goes", "lives", "works", "seems", "started", "stopped", "bought", "came", "comes",
    ]

    static func of(_ text: String) -> String? {
        var words = words(in: text)
        while let first = words.first, determiners.contains(first) { words.removeFirst() }
        guard let first = words.first else { return nil }
        if relations.contains(first), words.count > 1, !notNames.contains(words[1]), !relations.contains(words[1]) {
            return words[1]
        }
        return first
    }

    /// Whether `text` mentions `name` as a whole word.
    static func text(_ text: String, mentions name: String) -> Bool {
        words(in: text).contains(name)
    }

    private static func words(in text: String) -> [String] {
        text.lowercased()
            .split { !$0.isLetter && $0 != "'" && $0 != "’" }
            .map { word in
                var word = String(word)
                for suffix in ["'s", "’s"] where word.hasSuffix(suffix) { word.removeLast(2) }
                return word.trimmingCharacters(in: CharacterSet(charactersIn: "'’"))
            }
            .filter { !$0.isEmpty }
    }
}

extension MemoryFact {
    /// A friendly name for the kind of note, in the app's voice (never a clinical tag).
    var kindTitle: LocalizedStringResource {
        switch type {
        case "person": "someone in your life"
        case "event": "something happening"
        case "plan": "a plan"
        case "place": "a place"
        case "feeling": "a feeling"
        case "preference": "something you like"
        case "health": "looking after yourself"
        default: "on your mind"
        }
    }

    var symbol: String {
        switch type {
        case "person": "person.fill"
        case "event": "calendar"
        case "plan": "checklist"
        case "place": "mappin"
        case "feeling": "cloud.sun.fill"
        case "preference": "heart.fill"
        default: "bubble.left.fill"
        }
    }
}
