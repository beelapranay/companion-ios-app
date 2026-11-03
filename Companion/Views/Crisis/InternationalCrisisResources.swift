import SwiftUI

/// Resources outside the US: the international helpline directory and the local emergency number. Fixed in code;
/// don't add numbers without review.
struct InternationalCrisisResources: View {
    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            Text("Talk to someone now")
                .font(.title3.bold())
                .accessibilityAddTraits(.isHeader)
            ResourceLink(title: "Find a free, confidential helpline in your country", systemImage: "globe",
                         destination: URL(string: "https://findahelpline.com")!, style: .prominent)
            Label {
                Text("In an emergency, call your local emergency number.")
                    .font(.headline)
            } icon: {
                Image(systemName: "staroflife.fill")
                    .foregroundStyle(Color(.emergency))
            }
            .padding(Theme.Spacing.large)
            .frame(maxWidth: .infinity, minHeight: Theme.largeTapTarget, alignment: .leading)
            .background(Color(.surface), in: .rect(cornerRadius: Theme.Radius.card))
            .overlay {
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .strokeBorder(Color(.emergency).opacity(0.6), lineWidth: 1.5)
            }
        }
    }
}
