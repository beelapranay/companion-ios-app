import SwiftUI

/// Shown in place of a reply when a message is rated crisis. It stays prominent in the conversation and reopens the
/// crisis screen.
struct CrisisCard: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            HStack(spacing: Theme.Spacing.medium) {
                Image(systemName: "heart.circle.fill")
                    .font(.largeTitle)
                    .symbolEffect(.bounce, options: .nonRepeating)
                    .foregroundStyle(Color(.emergency))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: Theme.Spacing.tight) {
                    Text("Your safety matters most right now.")
                        .font(.headline)
                    Text("Tap to see support you can reach immediately.")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.subheadline.bold())
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
            .padding(Theme.Spacing.large)
            .frame(maxWidth: .infinity, minHeight: Theme.largeTapTarget, alignment: .leading)
            // a solid surface under the red tint, so the card stays opaque over the blue backdrop
            .background(Color(.emergency).opacity(0.1), in: .rect(cornerRadius: Theme.Radius.card))
            .background(Color(.surface), in: .rect(cornerRadius: Theme.Radius.card))
            .overlay {
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .strokeBorder(Color(.emergency).opacity(0.4), lineWidth: 1)
            }
            .contentShape(.rect(cornerRadius: Theme.Radius.card))
        }
        .buttonStyle(.pressable)
        .accessibilityHint("Opens crisis support")
    }
}

#Preview {
    CrisisCard {}
        .padding()
        .background(AppBackground())
}
