import SwiftUI

/// One large, tappable crisis resource. Red appears here because these are real emergency options; the rest of the
/// app avoids it.
struct ResourceLink: View {
    enum Style { case prominent, standard, emergency }

    let title: LocalizedStringResource
    let systemImage: String
    let destination: URL
    var style = Style.standard

    @ScaledMetric private var iconWidth = 28.0

    var body: some View {
        Link(destination: destination) {
            HStack(spacing: Theme.Spacing.medium) {
                Image(systemName: systemImage)
                    .font(.title3)
                    .foregroundStyle(style == .prominent ? Color.white : Color(.emergency))
                    .frame(width: iconWidth)
                    .accessibilityHidden(true)
                Text(title)
                    .font(.headline)
                    .multilineTextAlignment(.leading)
                Spacer(minLength: 0)
                Image(systemName: "chevron.right")
                    .font(.subheadline.bold())
                    .opacity(0.5)
                    .accessibilityHidden(true)
            }
            .foregroundStyle(style == .prominent ? Color.white : Color.primary)
            .padding(.horizontal, Theme.Spacing.large)
            .padding(.vertical, Theme.Spacing.medium)
            .frame(maxWidth: .infinity, minHeight: Theme.largeTapTarget, alignment: .leading)
            .background(style == .prominent ? AnyShapeStyle(Color(.emergency).gradient) : AnyShapeStyle(Color(.surface)),
                        in: .rect(cornerRadius: Theme.Radius.card))
            .shadow(color: Color(.emergency).opacity(style == .prominent ? 0.3 : 0), radius: 12, y: 6)
            .overlay {
                RoundedRectangle(cornerRadius: Theme.Radius.card)
                    .strokeBorder(Color(.emergency).opacity(style == .emergency ? 0.6 : 0), lineWidth: 1.5)
            }
            .contentShape(.rect(cornerRadius: Theme.Radius.card))
        }
        .buttonStyle(.pressable)
    }
}
