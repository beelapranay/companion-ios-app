import SwiftUI

/// One section of the first-launch notice as a card, for `AboutView`.
struct NoticeCard: View {
    let page: OnboardingPage

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            Label {
                Text(page.title)
            } icon: {
                Image(systemName: page.systemImage)
                    .foregroundStyle(.tint)
            }
            .font(.headline)
            .accessibilityAddTraits(.isHeader)

            if let important = page.important {
                Text(important)
                    .bold()
            }
            ForEach(page.paragraphs.indices, id: \.self) { index in
                Text(page.paragraphs[index])
                    .foregroundStyle(.secondary)
            }
        }
        .padding(Theme.Spacing.large)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.surface), in: .rect(cornerRadius: Theme.Radius.card))
    }
}

#Preview {
    NoticeCard(page: OnboardingPage.all[2])
        .padding()
        .background(Color(.canvas))
}
