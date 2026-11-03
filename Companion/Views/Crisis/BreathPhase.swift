import Foundation

/// The steps of the 4-4-6 breath from the grounding text, as used by `BreathingExercise`.
enum BreathPhase: Equatable {
    case ready, inhale, hold, exhale

    static let cycle: [BreathPhase] = [.inhale, .hold, .exhale]

    var title: LocalizedStringResource {
        switch self {
        case .ready: "Ready when you are"
        case .inhale: "Breathe in"
        case .hold: "Hold"
        case .exhale: "Breathe out"
        }
    }

    var seconds: Double {
        switch self {
        case .ready: 0
        case .inhale, .hold: 4
        case .exhale: 6
        }
    }

    /// How large the circle is at the end of this step.
    var scale: Double {
        switch self {
        case .ready, .exhale: 0.55
        case .inhale, .hold: 1
        }
    }

    /// The Reduce Motion stand-in for `scale`: the circle brightens instead of growing.
    var fill: Double {
        switch self {
        case .ready, .exhale: 0.2
        case .inhale, .hold: 0.5
        }
    }
}
