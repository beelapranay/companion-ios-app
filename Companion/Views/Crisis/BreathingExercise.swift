import SwiftUI

/// A guided version of the 4-4-6 breath: a soft blue orb that grows, holds and shrinks, with a light tap at each
/// step so it can be followed with eyes closed. Under Reduce Motion the orb stays still and only brightens and dims.
struct BreathingExercise: View {
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isRunning = false
    @State private var phase = BreathPhase.ready
    @ScaledMetric private var size = 176.0

    var body: some View {
        VStack(spacing: Theme.Spacing.large) {
            ZStack {
                Circle()
                    .fill(Color.accentColor.opacity(0.08))
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [Color.accentColor.opacity(0.55), Color(.brand)],
                            center: .topLeading,
                            startRadius: 0,
                            endRadius: size
                        )
                    )
                    .opacity(reduceMotion ? phase.fill * 1.6 : 1)
                    .scaleEffect(reduceMotion ? 1 : phase.scale)
                    .shadow(color: Color(.brand).opacity(0.35), radius: 24, y: 8)
            }
            .frame(width: size, height: size)
            .accessibilityHidden(true)

            Text(phase.title)
                .font(.title3.bold())
                .contentTransition(.opacity)
                .accessibilityAddTraits(.updatesFrequently)

            Button(action: toggle) {
                Label(isRunning ? LocalizedStringResource("Stop") : "Start breathing",
                      systemImage: isRunning ? "stop.fill" : "wind")
                    .contentTransition(.symbolEffect(.replace))
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.glass)
            .controlSize(.large)
        }
        .padding(Theme.Spacing.large)
        .frame(maxWidth: .infinity)
        .background(Color(.surface), in: .rect(cornerRadius: Theme.Radius.card))
        .sensoryFeedback(.impact(weight: .light), trigger: phase)
        .task(id: isRunning) { await breathe() }
    }

    private func toggle() {
        isRunning.toggle()
    }

    /// Steps through the cycle until stopped; `task(id:)` cancels this when `isRunning` changes.
    private func breathe() async {
        guard isRunning else {
            withAnimation(Theme.spring) { phase = .ready }
            return
        }
        while !Task.isCancelled {
            for next in BreathPhase.cycle {
                withAnimation(.easeInOut(duration: next.seconds)) { phase = next }
                try? await Task.sleep(for: .seconds(next.seconds))
                if Task.isCancelled { return }
            }
        }
    }
}

#Preview {
    BreathingExercise()
        .padding()
        .background(AppBackground())
}
