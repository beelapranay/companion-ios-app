import SwiftUI

/// The first-launch notice, reachable again from the chat screen.
struct AboutView: View {
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.section) {
                    ForEach(OnboardingPage.all, content: NoticeCard.init)
                }
                .padding(Theme.Spacing.large)
                .frame(maxWidth: Theme.readableWidth)
                .frame(maxWidth: .infinity)
            }
            .background(AppBackground())
            .navigationTitle("About Companion")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", role: .close, action: close)
                }
            }
        }
    }

    private func close() {
        dismiss()
    }
}

#Preview {
    AboutView()
}
