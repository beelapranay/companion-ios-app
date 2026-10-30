import SwiftUI

/// Shown once, before first use: what the app is and is not.
struct NoticeView: View {
    let accept: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Before we start").font(.largeTitle.bold())
            Text("Companion is a supportive chat that runs entirely on your phone. Your messages never leave the device.")
            Text("It is not a therapist, doctor or emergency service, and it can make mistakes.")
            Text("If you are in danger or thinking about harming yourself, contact emergency services or a crisis line right away. In the US, call or text 988.")
                .fontWeight(.semibold)
            Text("This is a research prototype for adults (18+).").foregroundStyle(.secondary)
            Spacer()
            Button(action: accept) {
                Text("I understand").frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .controlSize(.large)
        }
        .padding(24)
    }
}

struct LoadingView: View {
    let message: String
    let progress: Double?

    var body: some View {
        VStack(spacing: 16) {
            if let progress {
                ProgressView(value: progress).frame(maxWidth: 240)
            } else {
                ProgressView()
            }
            Text(message).multilineTextAlignment(.center).foregroundStyle(.secondary)
        }
        .padding(32)
    }
}
