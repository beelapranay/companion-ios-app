import SwiftUI

/// The splash backdrop: a blue mesh whose bright center drifts as it blooms in.
struct SplashMesh: View {
    let bloomed: Bool

    var body: some View {
        MeshGradient(
            width: 3,
            height: 3,
            points: [
                [0, 0], [0.5, 0], [1, 0],
                [0, 0.5], bloomed ? [0.42, 0.4] : [0.5, 0.5], [1, 0.5],
                [0, 1], [0.5, 1], [1, 1],
            ],
            colors: [
                Color(.launchBackground), Color(.brand), Color(.launchBackground),
                Color(.brand), .accentColor, Color(.brand),
                Color(.launchBackground), Color(.launchBackground), Color(.brand),
            ]
        )
    }
}

#Preview {
    SplashMesh(bloomed: true)
        .ignoresSafeArea()
}
