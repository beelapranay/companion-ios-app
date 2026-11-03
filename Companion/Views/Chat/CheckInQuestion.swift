import SwiftUI

/// The asking state of a check-in: the gentle question and two equally easy glass answers, side by side, or stacked
/// at accessibility text sizes.
struct CheckInQuestion: View {
    let answer: (_ safe: Bool) -> Void

    @Environment(\.dynamicTypeSize) private var dynamicTypeSize

    var body: some View {
        let layout = dynamicTypeSize.isAccessibilitySize
            ? AnyLayout(VStackLayout(alignment: .leading, spacing: Theme.Spacing.small))
            : AnyLayout(HStackLayout(spacing: Theme.Spacing.small))

        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            Label {
                Text("How are you holding up right now? If you're ever not feeling safe, support is one tap away.")
            } icon: {
                Image(systemName: "heart.fill")
                    .foregroundStyle(.tint)
            }
            .font(.subheadline)

            GlassEffectContainer(spacing: Theme.Spacing.small) {
                layout {
                    Button("I'm okay", action: answerOkay)
                        .tint(.accentColor)
                    Button("I'm not safe", action: answerNotSafe)
                        .tint(Color(.emergency))
                }
                .buttonStyle(.glass)
                .controlSize(.large)
            }
        }
        .padding(Theme.Spacing.large)
        .background(Color(.surface), in: .rect(cornerRadius: Theme.Radius.card))
        .overlay {
            RoundedRectangle(cornerRadius: Theme.Radius.card)
                .strokeBorder(Color.accentColor.opacity(0.25), lineWidth: 1)
        }
    }

    private func answerOkay() {
        answer(true)
    }

    private func answerNotSafe() {
        answer(false)
    }
}

#Preview {
    CheckInQuestion { _ in }
        .padding()
        .background(AppBackground())
}
