import SwiftUI

/// The animated half of launch. Its first frame matches the static launch screen exactly (LaunchBackground color,
/// LaunchLogo centered at its natural size), then a blue mesh blooms in, a glass disc forms around the leaf and the
/// wordmark rises before the whole thing lifts away. It plays once per cold launch alongside startup work, which
/// is already running underneath, so it never delays the app. Under Reduce Motion it simply fades.
struct SplashView: View {
    let finish: () -> Void

    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var bloomed = false
    @State private var leaving = false

    var body: some View {
        ZStack {
            Color(.launchBackground)

            SplashMesh(bloomed: bloomed)
                .opacity(bloomed ? 1 : 0)

            Image(.launchLogo)
                .background {
                    Color.clear
                        .frame(width: 148, height: 148)
                        .glassEffect(.clear, in: .circle)
                        .scaleEffect(bloomed || reduceMotion ? 1 : 0.5)
                        .opacity(bloomed ? 1 : 0)
                }
                .scaleEffect(bloomed && !reduceMotion ? 0.86 : 1)
                .overlay(alignment: .top) {
                    VStack(spacing: Theme.Spacing.tight) {
                        Text("Companion")
                            .font(.largeTitle.bold())
                        Text("A quiet place to talk")
                            .font(.headline)
                            .foregroundStyle(.white.opacity(0.8))
                    }
                    .foregroundStyle(.white)
                    .fixedSize()
                    .offset(y: 130 + (bloomed || reduceMotion ? 0 : 16))
                    .opacity(bloomed ? 1 : 0)
                }
        }
        .ignoresSafeArea()
        .scaleEffect(leaving && !reduceMotion ? 1.12 : 1)
        .opacity(leaving ? 0 : 1)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel("Companion")
        .task { await play() }
    }

    private func play() async {
        withAnimation(reduceMotion ? Theme.motion : .spring(duration: 0.7, bounce: 0.25)) {
            bloomed = true
        }
        try? await Task.sleep(for: .milliseconds(reduceMotion ? 350 : 850))
        withAnimation(.smooth(duration: 0.45)) {
            leaving = true
        } completion: {
            finish()
        }
    }
}

#Preview {
    SplashView {}
}
