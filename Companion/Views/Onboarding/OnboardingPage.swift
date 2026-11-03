import Foundation

/// One step of the first-launch notice. Together the steps must carry everything the notice has always said:
/// on-device privacy, not a therapist or emergency service, can make mistakes, emergency info (988 in the US),
/// adults only, research prototype. `AboutView` shows the same text again later.
struct OnboardingPage: Identifiable {
    let id: Int
    let systemImage: String
    let title: LocalizedStringResource
    let paragraphs: [LocalizedStringResource]
    var important: LocalizedStringResource?

    static let all = [
        OnboardingPage(
            id: 0,
            systemImage: "leaf.fill",
            title: "A quiet place to talk",
            paragraphs: [
                "Companion is a supportive chat that runs entirely on your phone. Your messages never leave the device.",
                "Once it's set up, it works offline.",
            ]),
        OnboardingPage(
            id: 1,
            systemImage: "hand.raised.fill",
            title: "What Companion is, and isn't",
            paragraphs: [
                "It is not a therapist, doctor or emergency service, and it can make mistakes.",
                "This is a research prototype for adults (18+).",
            ]),
        OnboardingPage(
            id: 2,
            systemImage: "heart.fill",
            title: "If you're ever in danger",
            paragraphs: [
                "In the app, the Support button is always one tap away.",
            ],
            important: """
                If you are in danger or thinking about harming yourself, contact emergency services or a crisis \
                line right away. In the US, call or text 988.
                """),
    ]
}
