import SwiftUI

/// The onboarding's glass control bar: page dots, then Back and Continue (or "I understand" on the last page). The
/// Back button grows out of Continue's glass when it appears.
struct OnboardingControls: View {
    let count: Int
    let current: Int
    let advance: () -> Void
    let goBack: () -> Void

    @Namespace private var glass

    private var isLast: Bool { current == count - 1 }

    var body: some View {
        VStack(spacing: Theme.Spacing.large) {
            PageIndicator(count: count, current: current)

            GlassEffectContainer(spacing: Theme.Spacing.medium) {
                HStack(spacing: Theme.Spacing.medium) {
                    if current > 0 {
                        Button("Back", systemImage: "chevron.backward", action: goBack)
                            .labelStyle(.iconOnly)
                            .buttonStyle(.glass)
                            .buttonBorderShape(.circle)
                            .controlSize(.extraLarge)
                            .glassEffectID("back", in: glass)
                    }

                    Button(action: advance) {
                        let title: LocalizedStringResource = isLast ? "I understand" : "Continue"
                        Text(title)
                            .bold()
                            .frame(maxWidth: .infinity)
                            .contentTransition(.interpolate)
                    }
                    .buttonStyle(.glassProminent)
                    .controlSize(.extraLarge)
                    .tint(Color(.brand))
                    .glassEffectID("continue", in: glass)
                }
            }
            .animation(Theme.spring, value: current)
            .sensoryFeedback(.selection, trigger: current)
        }
        .frame(maxWidth: Theme.readableWidth)
        .padding(.horizontal, Theme.Spacing.section)
        .padding(.bottom, Theme.Spacing.small)
    }
}

#Preview {
    VStack {
        Spacer()
        OnboardingControls(count: 3, current: 1, advance: {}, goBack: {})
    }
    .background(AppBackground())
}
