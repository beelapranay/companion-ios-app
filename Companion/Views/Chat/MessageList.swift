import SwiftUI

/// The messages, grouped: consecutive messages from the same side sit close together, and a quiet time label
/// appears at the start and after long pauses. Each element yields exactly one `VStack`, so the lazy stack can
/// identify rows by message id alone instead of re-running every row while a reply streams.
struct MessageList: View {
    let messages: [ChatMessage]
    let answerCheckIn: (UUID, Bool) -> Void
    let openSupport: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    var body: some View {
        LazyVStack(spacing: 0) {
            ForEach(Array(messages.enumerated()), id: \.element.id) { index, message in
                let previous = index > 0 ? messages[index - 1] : nil
                let joinsPrevious = groups(previous, with: message)

                VStack(spacing: 0) {
                    if showsTimestamp(before: message, after: previous) {
                        TimestampLabel(date: message.date)
                            .padding(.top, index == 0 ? 0 : Theme.Spacing.medium)
                    }
                    MessageRow(
                        message: message,
                        joinsPrevious: joinsPrevious,
                        answerCheckIn: answerCheckIn,
                        openSupport: openSupport
                    )
                }
                .padding(.top, index == 0 ? 0 : joinsPrevious ? Theme.Spacing.tight : Theme.Spacing.large)
                .transition(arrival(for: message))
            }
        }
        .animation(Theme.spring, value: messages.count)
        .frame(maxWidth: Theme.readableWidth)
        .frame(maxWidth: .infinity)
        .padding(.horizontal, Theme.Spacing.large)
        .padding(.vertical, Theme.Spacing.medium)
    }

    /// New messages grow from the speaker's side, like a text arriving; under Reduce Motion they only fade in.
    private func arrival(for message: ChatMessage) -> AnyTransition {
        guard !reduceMotion else { return .opacity }
        let anchor: UnitPoint = switch message.role {
        case .user: .bottomTrailing
        case .assistant: .bottomLeading
        case .crisisCard: .bottom
        }
        return .scale(scale: 0.85, anchor: anchor).combined(with: .opacity)
    }

    private func groups(_ first: ChatMessage?, with second: ChatMessage?) -> Bool {
        guard let first, let second, first.role == second.role, first.role != .crisisCard,
              first.checkIn == .none else { return false }
        return second.date.timeIntervalSince(first.date) < Theme.groupingGap
    }

    private func showsTimestamp(before message: ChatMessage, after previous: ChatMessage?) -> Bool {
        guard let previous else { return true }
        return message.date.timeIntervalSince(previous.date) > Theme.timestampGap
    }
}
