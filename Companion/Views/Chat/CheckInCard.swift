import SwiftUI

/// The small, dismissible safety question under a reply (crisis_layer/README.md: a check-in must cost almost
/// nothing, so it is inline, never a modal, and has no hotline numbers). "I'm not safe" opens the crisis screen;
/// "I'm okay" leaves a quiet thank-you.
struct CheckInCard: View {
    let state: ChatMessage.CheckIn
    let answer: (_ safe: Bool) -> Void

    var body: some View {
        VStack(alignment: .leading) {
            if state == .okay {
                Label("Thanks for letting me know. I'm here whenever you want to talk.",
                      systemImage: "checkmark.circle.fill")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                    .padding(.horizontal, Theme.Spacing.tight)
                    .transition(.opacity.combined(with: .scale(scale: 0.95, anchor: .topLeading)))
            } else {
                CheckInQuestion(answer: answer)
                    .transition(.opacity)
            }
        }
        .animation(Theme.spring, value: state)
        .sensoryFeedback(.success, trigger: state == .okay)
    }
}

#Preview {
    VStack(alignment: .leading, spacing: 24) {
        CheckInCard(state: .asking) { _ in }
        CheckInCard(state: .okay) { _ in }
    }
    .padding()
    .background(AppBackground())
}
