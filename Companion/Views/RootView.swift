import SwiftUI

/// Splash, then the first-launch notice, then loading, then chat. Generic over the model so previews and the
/// Simulator demo can drive the same screens without MLX. Going to the background ends the chat session, which is
/// when the model takes notes for the memory timeline.
struct RootView<Model: ChatModel & MemoryProviding>: View {
    @Environment(Model.self) private var model
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("acceptedNotice") private var acceptedNotice = false
    @State private var showsSplash = true

    var body: some View {
        ZStack {
            if !acceptedNotice {
                OnboardingView(accept: accept)
                    .transition(.opacity)
            } else {
                switch model.phase {
                case .ready:
                    ChatView<Model>()
                        .transition(.opacity)
                case .loading(let status, let progress):
                    LoadingView(status: status, progress: progress)
                        .transition(.opacity)
                case .failed(let error):
                    StartFailedView(error: error, retry: retry)
                        .transition(.opacity)
                }
            }

            if showsSplash {
                SplashView(finish: hideSplash)
                    .zIndex(1)
            }
        }
        .animation(Theme.motion, value: model.phase == .ready)
        .animation(Theme.motion, value: acceptedNotice)
        .onChange(of: scenePhase) { _, phase in
            if phase == .background { endSession() }
        }
    }

    private func endSession() {
        Task { await model.endSession() }
    }

    private func accept() {
        acceptedNotice = true
    }

    private func retry() {
        Task { await model.load() }
    }

    private func hideSplash() {
        showsSplash = false
    }
}

#Preview("Launch") {
    RootView<PreviewChatModel>()
        .environment(PreviewChatModel.demo("conversation"))
        .defaultAppStorage(UserDefaults(suiteName: "preview-notice")!)
}
