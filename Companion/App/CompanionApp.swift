import SwiftUI

@main
struct CompanionApp: App {
    @State private var model = AppModel()
    @AppStorage("acceptedNotice") private var acceptedNotice = false

    var body: some Scene {
        WindowGroup {
            Group {
                if !acceptedNotice {
                    NoticeView { acceptedNotice = true }
                } else {
                    switch model.phase {
                    case .ready: ChatView()
                    case .loading(let what, let progress): LoadingView(message: what, progress: progress)
                    case .failed(let error): LoadingView(message: "Couldn't start: \(error)", progress: nil)
                    }
                }
            }
            .environment(model)
            .task { await model.load() }
        }
    }
}
