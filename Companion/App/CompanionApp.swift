import SwiftUI

@main
struct CompanionApp: App {
    @State private var model = AppModel()

    var body: some Scene {
        WindowGroup {
            RootView<AppModel>()
                .environment(model)
                .task { await model.load() }
        }
    }
}
