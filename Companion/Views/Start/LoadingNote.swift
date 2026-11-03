import SwiftUI

/// One line of the loading screen's download note, with its symbol in a soft blue badge.
struct LoadingNote: View {
    let text: LocalizedStringResource
    let systemImage: String

    @ScaledMetric private var badge = 32.0

    var body: some View {
        Label {
            Text(text)
                .font(.subheadline)
                .foregroundStyle(.secondary)
        } icon: {
            Image(systemName: systemImage)
                .font(.subheadline.bold())
                .foregroundStyle(.tint)
                .frame(width: badge, height: badge)
                .background(Color.accentColor.opacity(0.12), in: .circle)
        }
        .labelStyle(.titleAndIcon)
    }
}

#Preview {
    LoadingNote(text: "Your messages never leave the device.", systemImage: "lock.fill")
        .padding()
}
