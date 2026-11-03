import SwiftUI

/// One conversation entry: a user bubble on the trailing side, a reply (with its check-in, if any) on the leading
/// side, or the crisis card at full width.
struct MessageRow: View {
    let message: ChatMessage
    var joinsPrevious = false
    let answerCheckIn: (UUID, Bool) -> Void
    let openSupport: () -> Void

    var body: some View {
        switch message.role {
        case .user:
            MessageBubble(text: message.text, isUser: true, joinsPrevious: joinsPrevious)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .padding(.leading, Theme.Spacing.bubbleInset)
        case .assistant:
            VStack(alignment: .leading, spacing: Theme.Spacing.small) {
                if message.isStreaming && message.text.isEmpty {
                    TypingIndicator()
                } else {
                    ReplyBubbles(text: message.text, joinsPrevious: joinsPrevious)
                }
                if message.checkIn != .none {
                    CheckInCard(state: message.checkIn, answer: answer)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.trailing, Theme.Spacing.bubbleInset)
        case .crisisCard:
            CrisisCard(action: openSupport)
        }
    }

    private func answer(safe: Bool) {
        answerCheckIn(message.id, safe)
    }
}
