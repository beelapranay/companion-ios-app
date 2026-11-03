# Handoff: Companion app UI

Next session's focus: **make Companion's UI excellent.** It is a SwiftUI iPhone app for on-device mental wellbeing
chat. The logic works and builds; the UI is a plain first pass (default SwiftUI lists, bubbles and buttons). Make it
feel calm, warm, trustworthy and polished, without weakening any of the safety behaviour described below.

## What the app is

- An iPhone 16 Pro app (iOS 18+) where a person chats with a supportive companion. Everything runs on the phone:
  the chat model is LFM3-1.7B (4-bit MLX, about 945 MB, downloaded on first launch), and messages never leave the
  device.
- It is a **research prototype for adults**. It is not a therapist, a medical device or an emergency service. The
  project is non-commercial.
- Around every message is a **crisis layer** (the `CrisisKit` package). It rates each user message as **none**,
  **check-in** or **crisis** before the chat model sees it:
  - **none:** normal chat.
  - **check-in:** the model replies as usual, and a small, dismissible line appears under the reply: "How are you
    holding up right now? If you're ever not feeling safe, support is one tap away." with "I'm okay" and "I'm not
    safe" buttons. Policy: at most one check-in every 10 messages or 30 minutes (halved after a crisis), sooner if a
    new kind of risk appears.
  - **crisis:** the model is skipped for that message. A crisis card appears in the chat and the crisis screen
    opens.

  Every model reply also has crisis-hotline sentences stripped while it streams, because the model garbles hotline
  names. The app shows its own verified resources instead. Unsafe replies (doses, very-low-calorie plans, tips for
  hiding self-harm, and so on) are replaced with a fixed fallback message.

## Where things are

Project root: `/Users/pranaybeela/Documents/projects/lfm-1.7B/app/` (its own local git repo, branch `main`, not
pushed yet; the user commits through their main session).

| path | what |
|---|---|
| `project.yml` | XcodeGen spec. `Companion.xcodeproj` is generated from it and is **not in git**; run `xcodegen generate` after changing it or after adding or removing files. |
| `Companion/App/CompanionApp.swift` | App entry: first-launch notice, then a loading screen, then chat. |
| `Companion/App/AppModel.swift` | `@MainActor @Observable` state and logic. Views read `phase`, `messages`, `showCrisis` and `isGenerating`, and call `send(_:)` and `answerCheckIn(_:safe:)`. `ChatMessage` has a `role` (`.user`, `.assistant`, `.crisisCard`), `text`, a `checkIn` state (`.none`, `.asking`, `.okay`) and `isStreaming`. |
| `Companion/App/SystemPrompt.swift` | The chat model's system prompt (v5). **Do not edit.** It must stay identical to the evaluated Python version. |
| `Companion/Views/ChatView.swift` | Chat screen, `MessageRow`, `CheckInView` and the composer. |
| `Companion/Views/CrisisView.swift` | Crisis screen (resources, grounding exercise, "Back to chat"). |
| `Companion/Views/StartViews.swift` | `NoticeView` (first-launch disclaimer) and `LoadingView` (model download progress). |
| `CrisisKit/` | Swift package: rules, classifier wrapper, safety policy, tests. **Logic, not UI. Leave it alone.** |
| `scripts/fetch_models.sh` | Copies the crisis classifier (~250 MB, not in git) into `Companion/Resources/`. |
| `README.md` | Build, run and status. |

Background docs, if needed: `../crisis_layer/README.md` (how the crisis layer was built and evaluated, and the
per-level app behaviour).

## Build and run

- Build check (no signing): `xcodebuild -project Companion.xcodeproj -scheme Companion -destination 'generic/platform=iOS' -derivedDataPath build -jobs 4 -skipPackagePluginValidation -skipMacroValidation CODE_SIGNING_ALLOWED=NO build`.
  The first build compiles MLX's C++ core and takes 10+ minutes; after that it's quick.
- **MLX does not run in the iOS Simulator** (it needs real Metal). The full app only runs on the user's iPhone, from
  Xcode with their signing team. Building for the Simulator at all is untested and may fail to link MLX.
- **For UI work this matters most.** Iterate with SwiftUI previews and mock state rather than the real model:
  - Give the views sample data: a conversation with user and assistant messages, a streaming reply, a reply with a
    check-in asking, one answered "I'm okay", a crisis card, plus the loading and failed phases.
  - The cleanest approach is probably to have the views depend on something mockable (a small protocol, or an
    `AppModel` initializer that takes canned messages and never calls `load()`), so previews and a Simulator demo
    mode don't need MLX.
  - Keep the real `AppModel` logic unchanged.
- The laptop is an 8 GB M3 MacBook Air. Avoid heavy parallel builds; `-jobs 4` is fine.

## Safety rules for the UI (do not break these)

1. **The crisis screen is always one tap away.** There is a "Support" toolbar button on the chat screen today; keep
   an equivalent that is always visible.
2. **Crisis screen wording and resources are fixed in code, never generated.**
   - Keep the resources as they are: US 988 call and text, text HOME to 741741, 911; elsewhere findahelpline.com and
     the local emergency number.
   - You may improve the layout and tone, but don't invent new hotlines or numbers.
   - Any change to the resource list needs the user's approval and verification.
3. **The check-in must stay cheap.** It is a small line under the reply, not a modal or alert, and contains no
   hotline numbers. The two choices ("I'm okay" / "I'm not safe") must stay obvious and easy to tap. "I'm not safe"
   opens the crisis screen.
4. **The crisis card in the chat stays prominent and tappable.** It reopens the crisis screen.
5. **Keep the first-launch notice**: not a therapist or emergency service, can make mistakes, emergency info (988 in
   the US), adults only, research prototype. Its design can improve, but its content must stay.
6. **Don't show model text the pipeline hasn't sanitized.** Display `ChatMessage.text` as `AppModel` sets it. Don't
   add views that show the raw model stream.
7. **No engagement tricks.** No streaks, badges, guilt-inducing nudges or notifications pushing people to come back.
   Red or alarm styling is reserved for real emergencies (the crisis screen's emergency rows, the crisis card); the
   rest of the app should feel calm.

## Ideas for the UI

These are suggestions, not requirements.

- **Look and feel:** a soft, warm palette with a calm accent colour, generous spacing and a friendly type scale.
  Support light and dark mode.
- **Chat:**
  - Better bubbles, with grouped messages and timestamps.
  - A gentle typing indicator while the reply streams.
  - Smooth scroll-to-bottom.
  - A composer with a clear send state.
  - An empty state with a few gentle conversation starters.
- **Check-in:** design it as a soft inline card that feels caring, not clinical. Show the answered "I'm okay" state
  quietly.
- **Crisis screen:** clear hierarchy. The most urgent options (call, text, emergency) come first as large tap
  targets, then the grounding exercise (maybe as a guided breathing animation), then the disclaimer.
- **First launch:** turn the notice into an onboarding flow that explains on-device privacy, keeping all the
  required content.
- **Loading:** a pleasant first-launch download screen with progress and an explanation (about 1 GB, once, over
  Wi-Fi).
- **Accessibility:** Dynamic Type, VoiceOver labels, sufficient contrast, Reduce Motion support, and 44 pt tap
  targets.

## Conventions and preferences

- The user's terminal style is "caveman" (terse replies). Code, docs and commits are written normally.
- **Commit only when the user asks**, and don't push. The app repo is local and the user handles commits and pushes
  from the main session. The app's GitHub repo doesn't exist yet.
- Don't touch `../mlx-swift-lm` (the LFM3 Swift port, a pending upstream PR), `../crisis_layer`, `../neuron-explorer`
  or the models.
- Follow the existing code style: short doc comments on types that explain why, and SwiftUI with `@Observable`.

## Open items outside UI scope (main session)

- Push the app to a private GitHub repo, and push the MLX Swift LFM3 port to the user's fork and open the PR.
- First run on the iPhone: check speed, memory, and that the increased-memory-limit entitlement works with the
  user's signing team.
