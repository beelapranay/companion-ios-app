import SwiftUI

/// Step dots for onboarding; the current one stretches into a pill. VoiceOver hears "Step 2 of 3" instead.
struct PageIndicator: View {
    let count: Int
    let current: Int

    var body: some View {
        HStack(spacing: Theme.Spacing.small) {
            ForEach(0..<count, id: \.self) { index in
                Capsule()
                    .fill(index == current ? AnyShapeStyle(.tint) : AnyShapeStyle(.quaternary))
                    .frame(width: index == current ? 24 : 8, height: 8)
            }
        }
        .animation(Theme.spring, value: current)
        .accessibilityElement()
        .accessibilityLabel("Step \(current + 1) of \(count)")
    }
}

#Preview {
    PageIndicator(count: 3, current: 1)
}
