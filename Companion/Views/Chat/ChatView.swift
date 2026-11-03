import SwiftUI

/// The conversation screen. The Support button stays in the toolbar at all times, so the crisis screen is always
/// one tap away. The composer floats in a glass bar at the bottom, with a jump-to-latest control above it while
/// the conversation is scrolled up. The memory button opens the timeline of things the user has mentioned; it
/// pulses gently while notes are being taken.
struct ChatView<Model: ChatModel & MemoryProviding>: View {
    @Environment(Model.self) private var model
    @State private var draft = ""
    @State private var position = ScrollPosition(edge: .bottom)
    @State private var isAtBottom = true
    @State private var showAbout = false
    @State private var showMemory = false

    var body: some View {
        @Bindable var model = model
        NavigationStack {
            ZStack {
                if model.messages.isEmpty {
                    ChatEmptyState(pick: send)
                        .transition(.opacity)
                } else {
                    ScrollView {
                        MessageList(messages: model.messages, answerCheckIn: answerCheckIn, openSupport: openSupport)
                    }
                    .defaultScrollAnchor(.bottom)
                    .scrollPosition($position)
                    .scrollDismissesKeyboard(.interactively)
                    .onScrollGeometryChange(for: Bool.self, of: isNearBottom) { _, nearBottom in
                        isAtBottom = nearBottom
                    }
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppBackground())
            .safeAreaBar(edge: .bottom) {
                ComposerView(
                    draft: $draft,
                    isReplying: model.isGenerating,
                    showsJumpButton: !isAtBottom && !model.messages.isEmpty,
                    send: sendDraft,
                    jumpToLatest: jumpToLatest
                )
            }
            .navigationTitle("Companion")
            .navigationSubtitle("Private, on this iPhone")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("About Companion", systemImage: "info", action: openAbout)
                }
                ToolbarItem(placement: .topBarLeading) {
                    Button("Things you've told me", systemImage: "calendar.day.timeline.left", action: openMemory)
                        .symbolEffect(.pulse, isActive: model.isTakingNotes)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Support", systemImage: "heart.text.square", action: openSupport)
                        .labelStyle(.titleAndIcon)
                        .accessibilityLabel("Crisis support")
                }
            }
            .onChange(of: model.messages.count) {
                jumpToLatest()
            }
            .sheet(isPresented: $model.showCrisis) { CrisisView() }
            .sheet(isPresented: $showAbout) { AboutView() }
            .sheet(isPresented: $showMemory) { MemoryView<Model>() }
        }
    }

    private func isNearBottom(_ geometry: ScrollGeometry) -> Bool {
        geometry.visibleRect.maxY >= geometry.contentSize.height - 80
    }

    private func sendDraft() {
        let text = draft
        draft = ""
        send(text)
    }

    private func send(_ text: String) {
        Task { await model.send(text) }
    }

    private func jumpToLatest() {
        withAnimation(Theme.spring) { position.scrollTo(edge: .bottom) }
    }

    private func answerCheckIn(_ id: UUID, safe: Bool) {
        model.answerCheckIn(id, safe: safe)
    }

    private func openSupport() {
        model.showCrisis = true
    }

    private func openAbout() {
        showAbout = true
    }

    private func openMemory() {
        showMemory = true
    }
}

#Preview("Conversation") {
    ChatView<PreviewChatModel>()
        .environment(PreviewChatModel.demo("conversation"))
}

#Preview("Answered + crisis card") {
    ChatView<PreviewChatModel>()
        .environment(PreviewChatModel.demo("answered"))
}

#Preview("Typing") {
    ChatView<PreviewChatModel>()
        .environment(PreviewChatModel.demo("streaming"))
}

#Preview("Empty") {
    ChatView<PreviewChatModel>()
        .environment(PreviewChatModel.demo("empty"))
}
