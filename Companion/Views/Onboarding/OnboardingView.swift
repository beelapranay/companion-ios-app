import SwiftUI

/// Shown once, before first use: what the app is and is not, in three pages that swipe natively or advance with
/// the button. "I understand" only appears on the last page, so the emergency information is always seen before the
/// first chat.
struct OnboardingView: View {
    let accept: () -> Void

    @State private var page: Int? = 0
    private let pages = OnboardingPage.all

    private var current: Int { page ?? 0 }
    private var isLastPage: Bool { current == pages.count - 1 }

    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(spacing: 0) {
                ForEach(pages) { page in
                    ScrollView {
                        OnboardingPageView(page: page)
                            .padding(.horizontal, Theme.Spacing.screen)
                            .padding(.top, Theme.Spacing.screen * 2)
                            .frame(maxWidth: Theme.readableWidth)
                            .frame(maxWidth: .infinity)
                    }
                    .scrollBounceBehavior(.basedOnSize)
                    .containerRelativeFrame(.horizontal)
                    .scrollTransition(axis: .horizontal) { content, phase in
                        content
                            .opacity(1 - abs(phase.value) * 0.7)
                            .scaleEffect(1 - abs(phase.value) * 0.06)
                    }
                }
            }
            .scrollTargetLayout()
        }
        .scrollTargetBehavior(.paging)
        .scrollPosition(id: $page)
        .scrollIndicators(.hidden)
        .safeAreaBar(edge: .bottom) {
            OnboardingControls(
                count: pages.count,
                current: current,
                advance: advance,
                goBack: goBack
            )
        }
        .background(AppBackground())
    }

    private func advance() {
        if isLastPage {
            accept()
        } else {
            withAnimation(Theme.spring) { page = current + 1 }
        }
    }

    private func goBack() {
        withAnimation(Theme.spring) { page = max(current - 1, 0) }
    }
}

#Preview {
    OnboardingView {}
}
