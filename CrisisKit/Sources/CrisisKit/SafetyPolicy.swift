import Foundation

/// When the app adds a check-in line under a reply (crisis_layer/README.md, "App behaviour per level").
///
/// The classifier's check-in threshold is low on purpose, so a check-in has to cost the user almost nothing: at
/// most one every `cooldownMessages` messages or `cooldownSeconds`, unless the level rises or a new kind of rule
/// fires. After a crisis in the session the cooldown is halved for the rest of it.
public struct SafetyPolicy: Sendable {
    public var cooldownMessages = 10
    public var cooldownSeconds: TimeInterval = 30 * 60

    public private(set) var heightened = false
    private var lastCheckIn: (message: Int, date: Date, level: CrisisLevel)?
    private var seenRules: Set<String> = []

    public init() {}

    /// Whether to show a check-in for this message (`index` counts the user's messages in the session).
    public mutating func shouldCheckIn(_ a: CrisisAssessment, index: Int, now: Date = .now) -> Bool {
        defer { seenRules.formUnion(a.rules) }
        guard a.level == .checkin else { return false }
        let newKind = !Set(a.rules).isSubset(of: seenRules)
        let factor = heightened ? 2 : 1
        let due = lastCheckIn.map {
            index - $0.message >= cooldownMessages / factor
                || now.timeIntervalSince($0.date) >= cooldownSeconds / Double(factor)
                || a.level > $0.level
        } ?? true
        guard due || newKind else { return false }
        lastCheckIn = (index, now, a.level)
        return true
    }

    /// Call when a message opens the crisis screen.
    public mutating func didShowCrisis(index: Int, now: Date = .now) {
        heightened = true
        lastCheckIn = (index, now, .crisis)
    }
}
