import MemoryKit
import SwiftUI

/// Shared sizes, so the lane titles laid over the timeline line up with the rows inside every column.
enum TimelineMetrics {
    static let laneTitle: CGFloat = 26
    static let mood: CGFloat = 44
    static let chipHeight: CGFloat = 32
    static let chipSpacing: CGFloat = 6
    static let chipsPerLane = 3
    static let axis: CGFloat = 40

    static var laneBand: CGFloat {
        CGFloat(chipsPerLane) * chipHeight + CGFloat(chipsPerLane - 1) * chipSpacing
    }

    static func width(of bucket: TimelineBucket, zoom: TimelineZoom) -> CGFloat {
        switch zoom {
        case .days: bucket.isEmpty ? 40 : 148
        case .weeks, .months: 164
        }
    }
}

/// Where a tap on the timeline leads inside the memory screen's navigation stack.
enum MemoryRoute: Hashable {
    case person(String)
    case stretch(MemoryLane, start: Date, end: Date)
}

/// One day, week or month: the mood mark, then up to three chips per lane, then the date.
struct TimelineColumn: View {
    let bucket: TimelineBucket
    let zoom: TimelineZoom
    let open: (UUID) -> Void

    @ScaledMetric(relativeTo: .footnote) private var chipHeight = TimelineMetrics.chipHeight
    @ScaledMetric(relativeTo: .caption) private var laneTitle = TimelineMetrics.laneTitle

    var body: some View {
        VStack(spacing: 0) {
            Color.clear.frame(height: laneTitle)
            MoodMark(tone: bucket.mood)
                .frame(height: TimelineMetrics.mood)

            ForEach(MemoryLane.allCases) { lane in
                Color.clear.frame(height: laneTitle)
                chips(for: lane)
                    .frame(height: laneBand, alignment: .top)
            }

            axisLabel
                .frame(height: TimelineMetrics.axis)
        }
        .padding(.horizontal, bucket.isEmpty && zoom == .days ? 0 : Theme.Spacing.tight)
        .frame(width: TimelineMetrics.width(of: bucket, zoom: zoom))
        .background(alignment: .leading) {
            Rectangle()
                .fill(.separator.opacity(0.6))
                .frame(width: 0.5)
        }
        .background {
            if isCurrent {
                RoundedRectangle(cornerRadius: Theme.Radius.card / 2)
                    .fill(.tint.opacity(0.06))
            }
        }
        .accessibilityElement(children: .contain)
        .accessibilityLabel(accessibilityTitle)
    }

    private var laneBand: CGFloat {
        CGFloat(TimelineMetrics.chipsPerLane) * chipHeight
            + CGFloat(TimelineMetrics.chipsPerLane - 1) * TimelineMetrics.chipSpacing
    }

    // MARK: chips

    private enum Item: Identifiable {
        case person(String)
        case fact(MemoryFact)

        var id: String {
            switch self {
            case .person(let name): "person-\(name)"
            case .fact(let fact): fact.id.uuidString
            }
        }
    }

    private func items(in lane: MemoryLane) -> [Item] {
        if lane == .people {
            let names = bucket.people.map(Item.person)
            let hidden = bucket.facts(in: .people).filter(\.sensitive).map(Item.fact)
            return names + hidden
        }
        return bucket.facts(in: lane).map(Item.fact)
    }

    @ViewBuilder
    private func chips(for lane: MemoryLane) -> some View {
        let items = items(in: lane)
        let limit = TimelineMetrics.chipsPerLane
        let shown = items.count > limit ? Array(items.prefix(limit - 1)) : items

        VStack(spacing: TimelineMetrics.chipSpacing) {
            ForEach(shown) { item in
                chip(for: item)
            }
            if items.count > limit {
                NavigationLink(value: MemoryRoute.stretch(lane, start: bucket.start, end: bucket.end)) {
                    FactChip(content: .more(items.count - shown.count))
                }
                .buttonStyle(.pressable)
                .accessibilityLabel("\(items.count - shown.count) more in \(Text(lane.title))")
            }
        }
    }

    @ViewBuilder
    private func chip(for item: Item) -> some View {
        switch item {
        case .person(let name):
            NavigationLink(value: MemoryRoute.person(name)) {
                FactChip(content: .person(name))
            }
            .buttonStyle(.pressable)
            .accessibilityHint("Shows everything you've mentioned about \(name)")
        case .fact(let fact):
            Button {
                open(fact.id)
            } label: {
                FactChip(content: fact.sensitive ? .hidden : .text(fact.text, symbol: fact.symbol))
            }
            .buttonStyle(.pressable)
            .accessibilityLabel(fact.sensitive ? Text("private note") : Text(fact.text))
            .accessibilityHint(fact.sensitive ? "Shows this private note" : "Shows where this came from")
        }
    }

    // MARK: date

    private var isCurrent: Bool {
        bucket.contains(.now)
    }

    @ViewBuilder
    private var axisLabel: some View {
        VStack(spacing: 0) {
            if isCurrent {
                Text(currentTitle)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.tint)
            } else if zoom == .days && bucket.isEmpty {
                Text(bucket.start, format: .dateTime.day())
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            } else {
                Text(primaryDate)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
            }
        }
        .lineLimit(1)
        .minimumScaleFactor(0.8)
    }

    private var currentTitle: LocalizedStringResource {
        switch zoom {
        case .days: "today"
        case .weeks: "this week"
        case .months: "this month"
        }
    }

    private var primaryDate: String {
        let calendar = Calendar.current
        let text = switch zoom {
        case .days: bucket.start.formatted(.dateTime.weekday(.abbreviated).day())
        case .weeks: bucket.start.formatted(.dateTime.month(.abbreviated).day())
        case .months: calendar.isDate(bucket.start, equalTo: .now, toGranularity: .year)
            ? bucket.start.formatted(.dateTime.month(.wide))
            : bucket.start.formatted(.dateTime.month(.abbreviated).year())
        }
        return text.lowercased()
    }

    private var accessibilityTitle: Text {
        let date = switch zoom {
        case .days: bucket.start.formatted(date: .complete, time: .omitted)
        case .weeks: String(localized: "week of \(bucket.start.formatted(date: .long, time: .omitted))")
        case .months: bucket.start.formatted(.dateTime.month(.wide).year())
        }
        return Text("\(date), \(Text(bucket.mood.description))")
    }
}

/// How a column felt, as a soft dot on a faint track: higher for lighter stretches, lower for heavier ones. Never
/// a number, and never emergency red.
struct MoodMark: View {
    let tone: MoodTone

    var body: some View {
        ZStack {
            Rectangle()
                .fill(.tint.opacity(0.15))
                .frame(height: 2)
            if tone != .quiet {
                Circle()
                    .fill(.tint.opacity(opacity))
                    .frame(width: 12, height: 12)
                    .shadow(color: .accentColor.opacity(0.35), radius: 6)
                    .offset(y: offset)
            }
        }
        .accessibilityElement()
        .accessibilityLabel(Text(tone.description))
    }

    private var offset: CGFloat {
        switch tone {
        case .lighter: -12
        case .mixed: 0
        case .heavier, .quiet: 12
        }
    }

    private var opacity: Double {
        switch tone {
        case .lighter: 0.9
        case .mixed: 0.7
        case .heavier, .quiet: 0.5
        }
    }
}
