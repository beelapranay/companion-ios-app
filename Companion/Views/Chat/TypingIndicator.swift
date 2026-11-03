import SwiftUI

/// Three softly pulsing dots until the first words of a reply arrive. Still under Reduce Motion.
struct TypingIndicator: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric private var dotSize = 8.0

    var body: some View {
        TimelineView(.animation(minimumInterval: nil, paused: reduceMotion)) { context in
            HStack(spacing: dotSize * 0.6) {
                ForEach(0..<3, id: \.self) { dot in
                    Circle()
                        .frame(width: dotSize, height: dotSize)
                        .opacity(reduceMotion ? 0.6 : opacity(of: dot, at: context.date))
                }
            }
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, Theme.Spacing.large)
        .padding(.vertical, Theme.Spacing.large)
        .background(Color(.surface), in: .rect(cornerRadius: Theme.Radius.bubble))
        .accessibilityElement()
        .accessibilityLabel("Companion is replying")
    }

    private func opacity(of dot: Int, at date: Date) -> Double {
        let wave = sin(date.timeIntervalSinceReferenceDate * 4 - Double(dot) * 0.8)
        return 0.35 + 0.65 * (wave + 1) / 2
    }
}

#Preview {
    TypingIndicator()
        .padding()
        .background(Color(.canvas))
}
