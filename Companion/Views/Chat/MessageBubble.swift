import SwiftUI

/// A chat bubble: white text on brand blue for the person, a solid surface for Companion. Bubbles are content, so
/// they stay solid rather than glass. The bottom corner on the speaker's side is tucked in as a small tail, and a
/// message that continues a group tucks in its top corner on that side too.
struct MessageBubble: View {
    let text: String
    let isUser: Bool
    var joinsPrevious = false

    var body: some View {
        Text(text)
            .textSelection(.enabled)
            .foregroundStyle(isUser ? AnyShapeStyle(.white) : AnyShapeStyle(.primary))
            .padding(.horizontal, Theme.Spacing.large)
            .padding(.vertical, Theme.Spacing.medium)
            .background(isUser ? AnyShapeStyle(Color(.brand).gradient) : AnyShapeStyle(Color(.surface)), in: shape)
            .shadow(color: Color(.brand).opacity(isUser ? 0.18 : 0.06), radius: 10, y: 4)
            .accessibilityElement(children: .ignore)
            .accessibilityLabel(isUser ? Text("You: \(text)") : Text("Companion: \(text)"))
    }

    private var shape: UnevenRoundedRectangle {
        let round = Theme.Radius.bubble
        let tucked = Theme.Radius.bubbleTail
        let top = joinsPrevious ? tucked : round
        return isUser
            ? UnevenRoundedRectangle(topLeadingRadius: round, bottomLeadingRadius: round,
                                     bottomTrailingRadius: tucked, topTrailingRadius: top)
            : UnevenRoundedRectangle(topLeadingRadius: top, bottomLeadingRadius: tucked,
                                     bottomTrailingRadius: round, topTrailingRadius: round)
    }
}

#Preview {
    VStack(spacing: 8) {
        MessageBubble(text: "I couldn't sleep again last night.", isUser: true)
        MessageBubble(text: "that sounds exhausting", isUser: false)
    }
    .padding()
    .background(AppBackground())
}
