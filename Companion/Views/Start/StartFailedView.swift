import SwiftUI

/// Startup failed (no network for the first download, or a missing safety model). Offers a retry, and support
/// stays reachable.
struct StartFailedView: View {
    let error: String
    let retry: () -> Void

    @State private var showSupport = false
    @State private var attempts = 0

    var body: some View {
        ContentUnavailableView {
            Label("Companion couldn't start", systemImage: "wifi.exclamationmark")
                .symbolEffect(.wiggle, value: attempts)
        } description: {
            Text(error)
        } actions: {
            Button("Try again", systemImage: "arrow.clockwise", action: tryAgain)
                .buttonStyle(.glassProminent)
                .controlSize(.large)
                .tint(Color(.brand))
            Button("Need support now?", systemImage: "heart.text.square", action: openSupport)
                .buttonStyle(.glass)
                .controlSize(.large)
        }
        .background(AppBackground())
        .sheet(isPresented: $showSupport) { CrisisView() }
    }

    private func tryAgain() {
        attempts += 1
        retry()
    }

    private func openSupport() {
        showSupport = true
    }
}

#Preview {
    StartFailedView(error: "The Internet connection appears to be offline.") {}
}
