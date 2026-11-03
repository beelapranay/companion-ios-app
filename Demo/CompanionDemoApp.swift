import SwiftUI

/// Simulator demo of the Companion UI with scripted replies, since MLX can't run in the Simulator. Not the real app:
/// there is no chat model and no crisis layer. Choose a screen with launch arguments, for example
/// `-demo streaming`, `-demoCrisis YES` or `-acceptedNotice NO` (see `PreviewChatModel.demo(_:)`).
@main
struct CompanionDemoApp: App {
    @State private var model = PreviewChatModel.demo(UserDefaults.standard.string(forKey: "demo") ?? "conversation")

    var body: some Scene {
        WindowGroup {
            RootView<PreviewChatModel>()
                .environment(model)
        }
    }
}
