import SwiftUI

/// What `LoadingView` shows: the breathing brand mark, status and progress (when there is a download), and a note
/// on privacy.
struct LoadingContent: View {
    let status: String
    let progress: Double?

    var body: some View {
        VStack(spacing: Theme.Spacing.section) {
            Spacer(minLength: Theme.Spacing.section)

            BrandMark(isBreathing: true)

            VStack(spacing: Theme.Spacing.small) {
                Text("Getting Companion ready")
                    .font(.title2.bold())
                    .accessibilityAddTraits(.isHeader)
                Text(status)
                    .foregroundStyle(.secondary)
                    .contentTransition(.opacity)
                    .animation(Theme.motion, value: status)
            }
            .multilineTextAlignment(.center)

            if let progress {
                VStack(spacing: Theme.Spacing.small) {
                    ProgressView(value: progress)
                        .tint(Color(.brand))
                    Text(progress, format: .percent.precision(.fractionLength(0)))
                        .font(.subheadline)
                        .monospacedDigit()
                        .contentTransition(.numericText(value: progress))
                        .foregroundStyle(.secondary)
                        .accessibilityHidden(true)
                }
                .frame(maxWidth: 280)
                .animation(Theme.motion, value: progress)
            } else {
                ProgressView()
                    .controlSize(.large)
            }

            Spacer(minLength: Theme.Spacing.section)

            VStack(alignment: .leading, spacing: Theme.Spacing.large) {
                LoadingNote(text: "The language model runs entirely on this phone. Once it's set up, Companion works offline.",
                            systemImage: "iphone")
                LoadingNote(text: "Your messages never leave the device.", systemImage: "lock.fill")
            }
            .padding(Theme.Spacing.large)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.surface), in: .rect(cornerRadius: Theme.Radius.card))
        }
        .frame(maxWidth: Theme.readableWidth)
    }
}

#Preview {
    LoadingContent(status: "Loading safety checks…", progress: 0.3)
        .padding()
        .background(AppBackground())
}
