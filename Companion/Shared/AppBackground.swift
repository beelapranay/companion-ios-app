import SwiftUI

/// The app's backdrop: a soft blue wash at the top fading into the canvas. It gives the glass bars something to
/// pick up without competing with content.
struct AppBackground: View {
    var body: some View {
        LinearGradient(
            stops: [
                .init(color: Color(.canvasTint), location: 0),
                .init(color: Color(.canvas), location: 0.45),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
        .ignoresSafeArea()
    }
}

#Preview {
    AppBackground()
}
