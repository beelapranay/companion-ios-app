import MemoryKit
import SwiftUI

/// One note, in full: what it says, when it was noted, and the words of yours it came from. It can be edited,
/// deleted, or waved off with "that's not right". A private note stays covered until the user asks to see it.
struct FactSheet<Model: MemoryProviding>: View {
    let id: UUID

    @Environment(Model.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var revealed = false
    @State private var isEditing = false
    @State private var draft = ""
    @State private var confirmDelete = false
    @FocusState private var editorFocused: Bool

    private var fact: MemoryFact? {
        model.memoryFacts.first { $0.id == id }
    }

    var body: some View {
        NavigationStack {
            Group {
                if let fact {
                    content(for: fact)
                } else {
                    ContentUnavailableView("forgotten", systemImage: "checkmark.circle",
                                           description: Text("that note's gone now."))
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(AppBackground())
            .navigationTitle(fact.map { Text($0.kindTitle) } ?? Text("note"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done", role: .close, action: close)
                }
            }
            .confirmationDialog("forget this note?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("forget it", role: .destructive, action: forget)
            } message: {
                Text("it's deleted from this phone straight away.")
            }
        }
        .presentationDetents([.medium, .large])
    }

    private func content(for fact: MemoryFact) -> some View {
        let showsText = !fact.sensitive || revealed
        return ScrollView {
            VStack(alignment: .leading, spacing: Theme.Spacing.section) {
                if !showsText {
                    PrivateCover(reveal: reveal)
                } else if isEditing {
                    editor
                } else {
                    Text(fact.text)
                        .font(.title2.weight(.semibold))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                details(for: fact)

                if showsText && !fact.source.isEmpty {
                    SourceQuote(text: fact.source)
                }
            }
            .padding(Theme.Spacing.large)
            .frame(maxWidth: Theme.readableWidth)
            .frame(maxWidth: .infinity)
        }
        .safeAreaBar(edge: .bottom) {
            Group {
                if showsText {
                    actions
                }
            }
        }
    }

    private var editor: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            TextField("what should it say?", text: $draft, axis: .vertical)
                .font(.title3)
                .focused($editorFocused)
                .padding(Theme.Spacing.medium)
                .background(Color(.surface), in: .rect(cornerRadius: Theme.Radius.field / 2))
            Text("leave it empty to forget it.")
                .font(.footnote)
                .foregroundStyle(.secondary)
        }
    }

    private func details(for fact: MemoryFact) -> some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            Label {
                Text("noted \(fact.saidAt.formatted(.relative(presentation: .named)))")
            } icon: {
                Image(systemName: "clock")
            }
            if !fact.when.isEmpty {
                Label {
                    Text("you said “\(fact.when)”")
                } icon: {
                    Image(systemName: "calendar")
                }
            }
            if fact.edited {
                Label("you edited this", systemImage: "pencil")
            }
        }
        .font(.subheadline)
        .foregroundStyle(.secondary)
    }

    private var actions: some View {
        GlassEffectContainer(spacing: Theme.Spacing.small) {
            HStack(spacing: Theme.Spacing.small) {
                if isEditing {
                    Button("cancel", action: cancelEdit)
                        .buttonStyle(.glass)
                    Button("save", action: save)
                        .buttonStyle(.glassProminent)
                } else {
                    Button("edit", systemImage: "pencil", action: startEdit)
                        .buttonStyle(.glass)
                    Button("that's not right", systemImage: "hand.thumbsdown", action: forget)
                        .buttonStyle(.glass)
                    Button("delete", systemImage: "trash") { confirmDelete = true }
                        .buttonStyle(.glass)
                        .labelStyle(.iconOnly)
                }
            }
            .controlSize(.large)
            .frame(maxWidth: .infinity)
        }
        .padding(.horizontal, Theme.Spacing.large)
        .padding(.bottom, Theme.Spacing.small)
        .animation(Theme.snappy, value: isEditing)
    }

    // MARK: actions

    private func reveal() {
        withAnimation(Theme.motion) { revealed = true }
    }

    private func startEdit() {
        draft = fact?.text ?? ""
        isEditing = true
        editorFocused = true
    }

    private func cancelEdit() {
        isEditing = false
    }

    private func save() {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        model.updateMemory(id, text: text)
        isEditing = false
        if text.isEmpty { dismiss() }
    }

    /// Both "that's not right" and delete simply forget the note.
    private func forget() {
        model.deleteMemory(id)
        dismiss()
    }

    private func close() {
        dismiss()
    }
}

/// Covers a private note until the user asks to see it.
private struct PrivateCover: View {
    let reveal: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            Label("this one's private", systemImage: "lock.fill")
                .font(.headline)
            Text("it stays hidden on your timeline. it's only on this phone, and you can delete it any time.")
                .foregroundStyle(.secondary)
            Button("show it", action: reveal)
                .buttonStyle(.glass)
        }
        .padding(Theme.Spacing.large)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.surface), in: .rect(cornerRadius: Theme.Radius.card))
    }
}

/// The user's own words the note came from, set off as a quote.
private struct SourceQuote: View {
    let text: String

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.small) {
            Text("where it came from")
                .font(.footnote.weight(.semibold))
                .foregroundStyle(.secondary)
            Text("“\(text)”")
                .italic()
                .padding(.leading, Theme.Spacing.medium)
                .overlay(alignment: .leading) {
                    Capsule()
                        .fill(.tint.opacity(0.5))
                        .frame(width: 3)
                }
                .accessibilityLabel("you said: \(text)")
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

#Preview("Note") {
    let model = PreviewChatModel()
    Color.clear.sheet(isPresented: .constant(true)) {
        FactSheet<PreviewChatModel>(id: model.memoryFacts[2].id)
            .environment(model)
    }
}

#Preview("Private note") {
    let model = PreviewChatModel()
    Color.clear.sheet(isPresented: .constant(true)) {
        FactSheet<PreviewChatModel>(id: model.memoryFacts.first(where: \.sensitive)!.id)
            .environment(model)
    }
}
