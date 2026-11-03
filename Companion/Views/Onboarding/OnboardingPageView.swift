import SwiftUI

/// The content of one onboarding page: the brand orb with this page's symbol, a title and a few short paragraphs.
/// The safety message, when a page has one, sits in its own card so it can't be skimmed past.
struct OnboardingPageView: View {
    let page: OnboardingPage

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.large) {
            BrandMark(systemImage: page.systemImage)
                .padding(.bottom, Theme.Spacing.small)

            Text(page.title)
                .font(.largeTitle.bold())
                .accessibilityAddTraits(.isHeader)

            if let important = page.important {
                Label {
                    Text(important)
                        .font(.body.bold())
                } icon: {
                    Image(systemName: "phone.fill")
                        .foregroundStyle(Color(.emergency))
                }
                .padding(Theme.Spacing.large)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(Color(.surface), in: .rect(cornerRadius: Theme.Radius.card))
            }

            ForEach(page.paragraphs.indices, id: \.self) { index in
                Text(page.paragraphs[index])
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview {
    OnboardingPageView(page: OnboardingPage.all[2])
        .padding()
        .background(AppBackground())
}
