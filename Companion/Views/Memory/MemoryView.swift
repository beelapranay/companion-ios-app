import MemoryKit
import SwiftUI

/// "things you've told me": the remember switch, then a sideways timeline of the notes Companion has kept, which
/// the user can open, edit, delete or wipe. The Support button stays in the toolbar here too, so crisis support is
/// still one tap away while this sheet is open.
struct MemoryView<Model: MemoryProviding>: View {
    @Environment(Model.self) private var model
    @Environment(\.dismiss) private var dismiss
    @State private var zoom = TimelineZoom.days
    @State private var openFact: FactRef?
    @State private var confirmWipe = false
    @State private var confirmSamples = false
    @State private var showSupport = false

    var body: some View {
        @Bindable var model = model
        let buckets = TimelineBucket.build(facts: model.memoryFacts, days: model.memoryDays, zoom: zoom)

        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: Theme.Spacing.section) {
                    RememberCard(isOn: $model.rememberEnabled, isTakingNotes: model.isTakingNotes)
                        .padding(.horizontal, Theme.Spacing.large)

                    if buckets.isEmpty {
                        MemoryEmptyState(rememberEnabled: model.rememberEnabled, showExample: loadSamples)
                            .padding(.horizontal, Theme.Spacing.large)
                    } else {
                        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
                            Picker("zoom", selection: $zoom.animation(Theme.spring)) {
                                ForEach(TimelineZoom.allCases) { zoom in
                                    Text(zoom.title).tag(zoom)
                                }
                            }
                            .pickerStyle(.segmented)
                            .padding(.horizontal, Theme.Spacing.large)

                            MemoryTimelineView(buckets: buckets, zoom: $zoom, open: open)

                            Text("pinch to see weeks or months. tap a note to see where it came from.")
                                .font(.footnote)
                                .foregroundStyle(.secondary)
                                .padding(.horizontal, Theme.Spacing.large)
                        }
                    }
                }
                .padding(.vertical, Theme.Spacing.large)
            }
            .background(AppBackground())
            .navigationTitle("things you've told me")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done", role: .close, action: close)
                }
                ToolbarItem(placement: .primaryAction) {
                    Button("Support", systemImage: "heart.text.square", action: openSupport)
                        .labelStyle(.titleAndIcon)
                        .accessibilityLabel("Crisis support")
                }
                ToolbarItem(placement: .secondaryAction) {
                    Button("load sample memories", systemImage: "sparkles.rectangle.stack") { confirmSamples = true }
                }
                ToolbarItem(placement: .secondaryAction) {
                    Button("delete everything", systemImage: "trash") { confirmWipe = true }
                        .disabled(model.memoryFacts.isEmpty && model.memoryDays.isEmpty)
                }
            }
            .navigationDestination(for: MemoryRoute.self) { route in
                FactListView<Model>(route: route, open: open)
            }
            .confirmationDialog("delete everything?", isPresented: $confirmWipe, titleVisibility: .visible) {
                Button("delete everything", role: .destructive, action: wipe)
            } message: {
                Text("this forgets every note and clears the timeline. it can't be undone.")
            }
            .confirmationDialog("load sample memories?", isPresented: $confirmSamples, titleVisibility: .visible) {
                Button("replace with samples", role: .destructive, action: loadSamples)
            } message: {
                Text("this replaces what's stored with two weeks of made-up notes, to show how the timeline works. you can delete them any time.")
            }
            .sheet(item: $openFact) { fact in
                FactSheet<Model>(id: fact.id)
            }
            .sheet(isPresented: $showSupport) {
                CrisisView()
            }
        }
    }

    private func open(_ id: UUID) {
        openFact = FactRef(id: id)
    }

    private func loadSamples() {
        withAnimation(Theme.spring) { model.loadSampleMemories() }
    }

    private func wipe() {
        withAnimation(Theme.motion) { model.wipeMemory() }
    }

    private func openSupport() {
        showSupport = true
    }

    private func close() {
        dismiss()
    }
}

/// Which note's sheet is open.
private struct FactRef: Identifiable {
    let id: UUID
}

/// The "remember things" switch, with a plain promise of what it does, and a quiet note while notes are being taken.
private struct RememberCard: View {
    @Binding var isOn: Bool
    let isTakingNotes: Bool

    var body: some View {
        VStack(alignment: .leading, spacing: Theme.Spacing.medium) {
            Toggle(isOn: $isOn.animation(Theme.snappy)) {
                VStack(alignment: .leading, spacing: Theme.Spacing.tight) {
                    Text("remember things")
                        .font(.headline)
                    Text("after we talk, i jot down people, plans and what's on your mind, so i can keep up. it all stays on this phone, and you can change or delete any of it.")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
            }

            if isTakingNotes {
                HStack(spacing: Theme.Spacing.small) {
                    ProgressView()
                        .controlSize(.small)
                    Text("noting down our last chat…")
                        .font(.footnote)
                        .foregroundStyle(.secondary)
                }
                .transition(.opacity)
            }
        }
        .padding(Theme.Spacing.large)
        .background(Color(.surface), in: .rect(cornerRadius: Theme.Radius.card))
        .animation(Theme.motion, value: isTakingNotes)
    }
}

/// Before anything is noted: what will appear here, said gently, so it doesn't feel like being watched.
private struct MemoryEmptyState: View {
    let rememberEnabled: Bool
    let showExample: () -> Void

    var body: some View {
        ContentUnavailableView {
            Label("nothing here yet", systemImage: "leaf")
        } description: {
            Text(rememberEnabled
                 ? "this fills in as you talk: the people, plans and things on your mind you mention. only you can see it."
                 : "remembering is off, so nothing new gets noted. turn it on above whenever you like.")
        } actions: {
            Button("see an example", action: showExample)
                .buttonStyle(.glass)
        }
        .padding(.vertical, Theme.Spacing.screen)
    }
}

#Preview("Timeline") {
    MemoryView<PreviewChatModel>()
        .environment(PreviewChatModel())
}

#Preview("Empty") {
    MemoryView<PreviewChatModel>()
        .environment(PreviewChatModel(memoryFacts: [], memoryDays: []))
}
