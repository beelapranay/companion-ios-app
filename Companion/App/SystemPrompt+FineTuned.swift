import CrisisKit

extension SystemPrompt {
    /// The prompt the fine-tuned "friend" models (v2 and v3) were trained on: one prompt for both levels, with the
    /// crisis layer's level on its own line. It must match training exactly (a single newline, nothing trailing),
    /// so it lives here by hand rather than in the generated `SystemPrompt.swift`.
    static func finetuned(level: CrisisLevel) -> String {
        let tag = level == .none ? "none" : "checkin"
        return "You're a friend people can text in a wellbeing app.\nlevel: \(tag)"
    }
}
