import SwiftUI

/// The leaf in a blue orb: the app's mark on onboarding, loading and empty screens.
struct BrandMark: View {
    var systemImage = "leaf.fill"
    var isBreathing = false

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @ScaledMetric private var size = 88.0

    var body: some View {
        Image(systemName: systemImage)
            .font(.system(size: size * 0.42, weight: .semibold))
            .foregroundStyle(.white)
            .symbolEffect(.breathe, isActive: isBreathing && !reduceMotion)
            .contentTransition(.symbolEffect(.replace))
            .frame(width: size, height: size)
            .background(Color(.brand).gradient, in: .circle)
            .shadow(color: Color(.brand).opacity(0.35), radius: 18, y: 8)
            .accessibilityHidden(true)
    }
}

#Preview {
    HStack(spacing: 24) {
        BrandMark()
        BrandMark(systemImage: "hand.raised.fill")
    }
    .padding()
    .background(AppBackground())
}
