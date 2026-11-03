import SwiftUI

/// Startup: the safety checks load, then the language model downloads (first launch only). Support stays one tap
/// away here too, since the first download can take a while.
struct LoadingView: View {
    let status: String
    let progress: Double?

    @State private var showSupport = false

    var body: some View {
        // short screens, such as iPhone Duo's outer display or large text, scroll instead of clipping Support
        ViewThatFits(in: .vertical) {
            LoadingContent(status: status, progress: progress)
            ScrollView {
                LoadingContent(status: status, progress: progress)
            }
        }
        .padding(.horizontal, Theme.Spacing.section)
        .frame(maxWidth: .infinity)
        .safeAreaBar(edge: .bottom) {
            Button("Need support now?", systemImage: "heart.text.square", action: openSupport)
                .buttonStyle(.glass)
                .controlSize(.large)
                .padding(.bottom, Theme.Spacing.small)
        }
        .background(AppBackground())
        .sheet(isPresented: $showSupport) { CrisisView() }
    }

    private func openSupport() {
        showSupport = true
    }
}

#Preview("Downloading") {
    LoadingView(status: "Downloading the language model (about 1 GB, first launch only)…", progress: 0.42)
}

#Preview("Safety checks") {
    LoadingView(status: "Loading safety checks…", progress: nil)
}
