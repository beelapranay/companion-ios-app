import SwiftUI

/// The floating glass composer: a message field and a send button, with a jump-to-latest button that rises out of
/// the same glass while the conversation is scrolled up. Sending waits for a non-empty draft and for the current
/// reply to finish; the draft can still be typed meanwhile.
struct ComposerView: View {
    @Binding var draft: String
    let isReplying: Bool
    let showsJumpButton: Bool
    let send: () -> Void
    let jumpToLatest: () -> Void

    @Namespace private var glass
    @State private var sentCount = 0
    @ScaledMetric private var sendSize = 24.0

    private var canSend: Bool {
        !isReplying && !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        GlassEffectContainer(spacing: Theme.Spacing.small) {
            VStack(spacing: Theme.Spacing.small) {
                if showsJumpButton {
                    Button("Latest messages", systemImage: "arrow.down", action: jumpToLatest)
                        .labelStyle(.iconOnly)
                        .buttonStyle(.glass)
                        .buttonBorderShape(.circle)
                        .controlSize(.large)
                        .glassEffectID("jump", in: glass)
                }

                HStack(alignment: .bottom, spacing: Theme.Spacing.small) {
                    TextField("Message", text: $draft,
                              prompt: isReplying ? Text("Companion is replying…") : Text("Message"),
                              axis: .vertical)
                        .lineLimit(1...6)
                        .padding(.horizontal, Theme.Spacing.large)
                        .padding(.vertical, Theme.Spacing.medium)
                        .frame(minHeight: Theme.minTapTarget + 4)
                        .glassEffect(.regular.interactive(), in: .rect(cornerRadius: Theme.Radius.field))
                        .glassEffectID("field", in: glass)

                    Button(action: submit) {
                        Label("Send", systemImage: "arrow.up")
                            .labelStyle(.iconOnly)
                            .font(.body.bold())
                            .frame(width: sendSize, height: sendSize)
                    }
                    .buttonStyle(.glassProminent)
                    .buttonBorderShape(.circle)
                    .controlSize(.large)
                    .tint(Color(.brand))
                    .disabled(!canSend)
                    .glassEffectID("send", in: glass)
                }
            }
        }
        .animation(Theme.spring, value: showsJumpButton)
        .animation(Theme.snappy, value: canSend)
        .frame(maxWidth: Theme.readableWidth)
        .padding(.horizontal, Theme.Spacing.medium)
        .padding(.bottom, Theme.Spacing.small)
        .sensoryFeedback(.impact(weight: .light), trigger: sentCount)
    }

    private func submit() {
        guard canSend else { return }
        send()
        sentCount += 1
    }
}

#Preview {
    @Previewable @State var draft = "I keep thinking about Friday"
    VStack {
        Spacer()
        ComposerView(draft: $draft, isReplying: false, showsJumpButton: true, send: {}, jumpToLatest: {})
        ComposerView(draft: .constant(""), isReplying: true, showsJumpButton: false, send: {}, jumpToLatest: {})
    }
    .background(AppBackground())
}
