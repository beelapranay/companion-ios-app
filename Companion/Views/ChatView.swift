import SwiftUI

struct ChatView: View {
    @Environment(AppModel.self) private var model
    @State private var draft = ""
    @FocusState private var focused: Bool

    var body: some View {
        @Bindable var model = model
        NavigationStack {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(alignment: .leading, spacing: 12) {
                        if model.messages.isEmpty {
                            Text("Hi. What's on your mind today?")
                                .foregroundStyle(.secondary)
                                .padding(.top, 40)
                                .frame(maxWidth: .infinity)
                        }
                        ForEach(model.messages) { message in
                            MessageRow(message: message).id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: model.messages.last?.text) {
                    if let id = model.messages.last?.id { proxy.scrollTo(id, anchor: .bottom) }
                }
            }
            .safeAreaInset(edge: .bottom) { composer }
            .navigationTitle("Companion")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                Button("Support", systemImage: "heart.text.square") { model.showCrisis = true }
                    .accessibilityLabel("Crisis support")
            }
            .sheet(isPresented: $model.showCrisis) { CrisisView() }
        }
    }

    private var composer: some View {
        HStack(alignment: .bottom, spacing: 8) {
            TextField("Message", text: $draft, axis: .vertical)
                .lineLimit(1...5)
                .focused($focused)
                .padding(10)
                .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 18))
            Button {
                let text = draft
                draft = ""
                Task { await model.send(text) }
            } label: {
                Image(systemName: "arrow.up.circle.fill").font(.system(size: 32))
            }
            .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || model.isGenerating)
            .accessibilityLabel("Send")
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(.bar)
    }
}

struct MessageRow: View {
    @Environment(AppModel.self) private var model
    let message: ChatMessage

    var body: some View {
        switch message.role {
        case .user:
            HStack {
                Spacer(minLength: 48)
                Text(message.text)
                    .padding(12)
                    .background(Color.accentColor.opacity(0.15), in: RoundedRectangle(cornerRadius: 16))
            }
        case .assistant:
            VStack(alignment: .leading, spacing: 8) {
                Text(message.text.isEmpty && message.isStreaming ? "…" : message.text)
                    .padding(12)
                    .background(.thinMaterial, in: RoundedRectangle(cornerRadius: 16))
                if message.checkIn != .none { CheckInView(message: message) }
            }
            .padding(.trailing, 32)
        case .crisisCard:
            Button { model.showCrisis = true } label: {
                Label("Your safety matters most right now. Tap to see support you can reach immediately.",
                      systemImage: "heart.circle.fill")
                    .multilineTextAlignment(.leading)
                    .padding(12)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .background(Color.red.opacity(0.12), in: RoundedRectangle(cornerRadius: 16))
            }
            .buttonStyle(.plain)
        }
    }
}

/// The small, dismissible safety question under a reply (crisis_layer/README.md: a check-in must cost almost
/// nothing, so no modal and no hotline numbers here).
struct CheckInView: View {
    @Environment(AppModel.self) private var model
    let message: ChatMessage

    var body: some View {
        if message.checkIn == .okay {
            Text("Thanks for letting me know. I'm here whenever you want to talk.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        } else {
            VStack(alignment: .leading, spacing: 6) {
                Text("How are you holding up right now? If you're ever not feeling safe, support is one tap away.")
                    .font(.footnote)
                    .foregroundStyle(.secondary)
                HStack {
                    Button("I'm okay") { model.answerCheckIn(message.id, safe: true) }
                    Button("I'm not safe") { model.answerCheckIn(message.id, safe: false) }
                        .tint(.red)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
        }
    }
}
