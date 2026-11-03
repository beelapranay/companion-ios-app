import SwiftUI

/// What a new conversation opens with: a gentle hello and a few glass chips to begin with, since a blank page can
/// be hard.
struct ChatEmptyState: View {
    let pick: (String) -> Void

    private static let starters = [
        "I've had a rough day",
        "I'm feeling anxious about something",
        "I just need to vent for a bit",
        "Help me wind down before sleep",
    ]

    var body: some View {
        ScrollView {
            VStack(spacing: Theme.Spacing.section) {
                BrandMark()

                VStack(spacing: Theme.Spacing.small) {
                    Text("Hi. What's on your mind today?")
                        .font(.title2.bold())
                        .accessibilityAddTraits(.isHeader)
                    Text("Talk through whatever you're carrying. Everything stays on this phone.")
                        .foregroundStyle(.secondary)
                }
                .multilineTextAlignment(.center)

                GlassEffectContainer(spacing: Theme.Spacing.small) {
                    VStack(spacing: Theme.Spacing.small) {
                        ForEach(Self.starters, id: \.self) { starter in
                            Button(starter) { pick(starter) }
                                .buttonStyle(.glass)
                                .controlSize(.large)
                        }
                    }
                }
            }
            .padding(Theme.Spacing.section)
            .frame(maxWidth: Theme.readableWidth)
            .containerRelativeFrame(.vertical)
            .frame(maxWidth: .infinity)
        }
        .scrollBounceBehavior(.basedOnSize)
        .scrollDismissesKeyboard(.interactively)
    }
}

#Preview {
    ChatEmptyState { _ in }
        .background(AppBackground())
}
