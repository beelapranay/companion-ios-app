import MemoryKit
import SwiftUI

/// A list of notes in time order: everything that mentions one person, or everything in one lane for a day, week
/// or month that had more than fits on the timeline. Private notes stay covered here too.
struct FactListView<Model: MemoryProviding>: View {
    let route: MemoryRoute
    let open: (UUID) -> Void

    @Environment(Model.self) private var model

    private var facts: [MemoryFact] {
        let all = model.memoryFacts.sorted { $0.saidAt < $1.saidAt }
        return switch route {
        case .person(let name):
            all.filter { PersonName.text($0.text, mentions: name) }
        case .stretch(let lane, let start, let end):
            all.filter { MemoryLane(type: $0.type) == lane && $0.saidAt >= start && $0.saidAt < end }
        }
    }

    var body: some View {
        ScrollView {
            LazyVStack(alignment: .leading, spacing: Theme.Spacing.small) {
                ForEach(facts) { fact in
                    FactRow(fact: fact) { open(fact.id) }
                }
            }
            .padding(Theme.Spacing.large)
            .frame(maxWidth: Theme.readableWidth)
            .frame(maxWidth: .infinity)
        }
        .overlay {
            if facts.isEmpty {
                ContentUnavailableView("nothing here now", systemImage: "leaf",
                                       description: Text("those notes have been deleted."))
            }
        }
        .background(AppBackground())
        .navigationTitle(title)
        .navigationSubtitle(subtitle)
        .navigationBarTitleDisplayMode(.inline)
    }

    private var title: String {
        switch route {
        case .person(let name): name
        case .stretch(let lane, _, _): String(localized: lane.title)
        }
    }

    private var subtitle: String {
        switch route {
        case .person: String(localized: "everything you've mentioned, oldest first")
        case .stretch(_, let start, let end):
            (start..<end.addingTimeInterval(-1)).formatted(.interval.month(.abbreviated).day()).lowercased()
        }
    }
}

/// One note in a list: its text (or a private placeholder), when it was noted, and the time words used.
private struct FactRow: View {
    let fact: MemoryFact
    let open: () -> Void

    var body: some View {
        Button(action: open) {
            HStack(spacing: Theme.Spacing.medium) {
                Image(systemName: fact.sensitive ? "lock.fill" : fact.symbol)
                    .font(.subheadline)
                    .foregroundStyle(fact.sensitive ? AnyShapeStyle(.secondary) : AnyShapeStyle(.tint))
                    .frame(width: 24)
                    .accessibilityHidden(true)

                VStack(alignment: .leading, spacing: Theme.Spacing.tight) {
                    Text(fact.sensitive ? String(localized: "private, tap to show") : fact.text)
                        .foregroundStyle(fact.sensitive ? .secondary : .primary)
                        .multilineTextAlignment(.leading)
                    Text(dateLine)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)

                Image(systemName: "chevron.right")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tertiary)
                    .accessibilityHidden(true)
            }
            .padding(Theme.Spacing.medium)
            .frame(minHeight: Theme.minTapTarget)
            .background(Color(.surface), in: .rect(cornerRadius: Theme.Radius.card / 1.5))
        }
        .buttonStyle(.pressable)
    }

    private var dateLine: String {
        let noted = fact.saidAt.formatted(.dateTime.weekday(.abbreviated).month(.abbreviated).day()).lowercased()
        return fact.when.isEmpty || fact.sensitive ? noted : "\(noted) · “\(fact.when)”"
    }
}

#Preview("Person") {
    NavigationStack {
        FactListView<PreviewChatModel>(route: .person("sam"), open: { _ in })
    }
    .environment(PreviewChatModel())
}
