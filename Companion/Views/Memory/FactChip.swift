import SwiftUI

/// A note on the timeline: a solid capsule (content, so no glass) with a small symbol and one line of text.
/// Private notes never show their text here, only a neutral placeholder.
struct FactChip: View {
    enum Content {
        case text(String, symbol: String)
        case person(String)
        case hidden
        case more(Int)
    }

    let content: Content
    @ScaledMetric(relativeTo: .footnote) private var height = TimelineMetrics.chipHeight

    var body: some View {
        HStack(spacing: Theme.Spacing.tight + 2) {
            Image(systemName: symbol)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(isHidden ? AnyShapeStyle(.secondary) : AnyShapeStyle(.tint))
                .accessibilityHidden(true)
            Text(label)
                .font(.footnote)
                .foregroundStyle(isHidden ? .secondary : .primary)
                .lineLimit(1)
        }
        .padding(.horizontal, Theme.Spacing.medium - 2)
        .frame(height: height)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(background, in: .capsule)
        .overlay {
            if isHidden {
                Capsule().strokeBorder(.secondary.opacity(0.5), style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
            }
        }
        .contentShape(.capsule)
    }

    private var isHidden: Bool {
        if case .hidden = content { true } else { false }
    }

    private var symbol: String {
        switch content {
        case .text(_, let symbol): symbol
        case .person: "person.fill"
        case .hidden: "lock.fill"
        case .more: "ellipsis"
        }
    }

    private var label: String {
        switch content {
        case .text(let text, _), .person(let text): text
        case .hidden: String(localized: "private, tap to show")
        case .more(let count): String(localized: "\(count) more")
        }
    }

    private var background: AnyShapeStyle {
        isHidden ? AnyShapeStyle(Color(.surface).opacity(0.5)) : AnyShapeStyle(Color(.surface))
    }
}

#Preview {
    VStack {
        FactChip(content: .person("sam"))
        FactChip(content: .text("chem exam on thursday", symbol: "calendar"))
        FactChip(content: .hidden)
        FactChip(content: .more(3))
    }
    .frame(width: 150)
    .padding()
    .background(AppBackground())
}
