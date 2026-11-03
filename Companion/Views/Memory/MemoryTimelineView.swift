import SwiftUI

/// The sideways timeline: time runs left to right, opening on today at the right edge. Pinching in or out moves
/// between days, weeks and months (the picker above does the same, for anyone who can't pinch). Lane titles stay
/// pinned at the leading edge while the columns scroll beneath them.
struct MemoryTimelineView: View {
    let buckets: [TimelineBucket]
    @Binding var zoom: TimelineZoom
    let open: (UUID) -> Void

    @ScaledMetric(relativeTo: .footnote) private var chipHeight = TimelineMetrics.chipHeight
    @ScaledMetric(relativeTo: .caption) private var laneTitle = TimelineMetrics.laneTitle

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                ForEach(buckets) { bucket in
                    TimelineColumn(bucket: bucket, zoom: zoom, open: open)
                }
            }
            .scrollTargetLayout()
        }
        .id(zoom)  // a new zoom starts again from today
        .defaultScrollAnchor(.trailing)
        .scrollIndicators(.hidden)
        .contentMargins(.horizontal, Theme.Spacing.large, for: .scrollContent)
        .overlay(alignment: .topLeading) {
            laneTitles
        }
        .simultaneousGesture(pinch)
        .transition(.opacity)
    }

    private var laneBand: CGFloat {
        CGFloat(TimelineMetrics.chipsPerLane) * chipHeight
            + CGFloat(TimelineMetrics.chipsPerLane - 1) * TimelineMetrics.chipSpacing
    }

    /// Titles that sit in the empty title row each column leaves above its lane.
    private var laneTitles: some View {
        VStack(alignment: .leading, spacing: 0) {
            LaneTitle(title: "how days felt")
                .frame(height: laneTitle)
            Color.clear.frame(height: TimelineMetrics.mood)
            ForEach(MemoryLane.allCases) { lane in
                LaneTitle(title: lane.title)
                    .frame(height: laneTitle)
                Color.clear.frame(height: laneBand)
            }
        }
        .padding(.leading, Theme.Spacing.large)
        .allowsHitTesting(false)
    }

    private var pinch: some Gesture {
        MagnifyGesture()
            .onEnded { value in
                let next = if value.magnification < 0.75 {
                    zoom.zoomedOut
                } else if value.magnification > 1.33 {
                    zoom.zoomedIn
                } else {
                    zoom
                }
                guard next != zoom else { return }
                withAnimation(Theme.spring) { zoom = next }
            }
    }
}

/// A lane's name: small, in a soft capsule so it stays readable over whatever scrolls behind it.
private struct LaneTitle: View {
    let title: LocalizedStringResource

    var body: some View {
        Text(title)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.secondary)
            .padding(.horizontal, Theme.Spacing.small)
            .padding(.vertical, 2)
            .background(.background.opacity(0.7), in: .capsule)
            .accessibilityAddTraits(.isHeader)
    }
}

#Preview {
    @Previewable @State var zoom = TimelineZoom.days
    NavigationStack {
        MemoryTimelineView(
            buckets: TimelineBucket.build(facts: MemorySamples.facts(), days: MemorySamples.days(), zoom: zoom),
            zoom: $zoom,
            open: { _ in }
        )
        .background(AppBackground())
    }
}
