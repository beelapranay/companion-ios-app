import SwiftUI

/// A reply drawn as a short run of texts, one bubble per line, to match the texting format `AppModel` applies
/// (`Texting.format` puts a line break where each full stop was). VoiceOver reads the whole reply as one message.
struct ReplyBubbles: View {
    let text: String
    var joinsPrevious = false

    var body: some View {
        let lines = text.split(separator: "\n")
        VStack(alignment: .leading, spacing: Theme.Spacing.tight) {
            // lines only grow at the end while a reply streams, so a line's position is a stable identity
            ForEach(lines.indices, id: \.self) { index in
                MessageBubble(text: String(lines[index]), isUser: false, joinsPrevious: joinsPrevious || index > 0)
            }
        }
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Companion: \(text)"))
    }
}

#Preview {
    ReplyBubbles(text: "that sounds really exhausting\nwhat kept you up, was it work stuff again?")
        .padding()
        .background(Color(.canvas))
}
