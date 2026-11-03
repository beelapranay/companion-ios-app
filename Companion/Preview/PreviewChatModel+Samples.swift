import Foundation

extension PreviewChatModel {
    /// A preview or demo model by name: conversation, answered, streaming, replying, empty, loading, preparing or
    /// failed. The `demoCrisis` user default opens the crisis screen on top.
    static func demo(_ name: String) -> PreviewChatModel {
        let model = switch name {
        case "empty": PreviewChatModel()
        case "answered": PreviewChatModel(messages: conversation(checkIn: .okay) + [
            ChatMessage(role: .user, text: "Some nights I don't see the point of anything anymore.",
                        date: .now.addingTimeInterval(-60)),
            ChatMessage(role: .crisisCard, text: "", date: .now.addingTimeInterval(-55)),
        ])
        case "streaming": PreviewChatModel(messages: conversation(checkIn: .okay) + [
            ChatMessage(role: .user, text: "Thanks. I think I'll try writing it down tonight.",
                        date: .now.addingTimeInterval(-5)),
            ChatMessage(role: .assistant, text: "", isStreaming: true),
        ])
        case "replying": PreviewChatModel(messages: conversation(checkIn: .okay) + [
            ChatMessage(role: .user, text: "Thanks. I think I'll try writing it down tonight.",
                        date: .now.addingTimeInterval(-5)),
            ChatMessage(role: .assistant, text: "that sounds like a kind thing to do for yourself\neven a few",
                        isStreaming: true),
        ])
        case "loading": PreviewChatModel(
            phase: .loading("Downloading the language model (about 1 GB, first launch only)…", 0.42))
        case "preparing": PreviewChatModel(phase: .loading("Loading safety checks…", nil))
        case "failed": PreviewChatModel(phase: .failed("The Internet connection appears to be offline."))
        default: PreviewChatModel(messages: conversation(checkIn: .asking))
        }
        model.isGenerating = model.messages.last?.isStreaming == true
        model.showCrisis = UserDefaults.standard.bool(forKey: "demoCrisis")
        return model
    }

    private static func conversation(checkIn: ChatMessage.CheckIn) -> [ChatMessage] {
        let yesterday = Date.now.addingTimeInterval(-20 * 3600)
        let earlier = Date.now.addingTimeInterval(-25 * 60)
        return [
            ChatMessage(role: .user, text: "I couldn't sleep again last night. My head just wouldn't stop.",
                        date: yesterday),
            ChatMessage(role: .assistant, text: "ugh, that sounds exhausting\nlying there while your brain just keeps going\nwas it stuck on something specific or more of a general restless thing?",
                        date: yesterday.addingTimeInterval(20)),
            ChatMessage(role: .user, text: "Mostly work. I have a review on Friday.", date: yesterday.addingTimeInterval(90)),
            ChatMessage(role: .user, text: "I keep imagining it going badly.", date: yesterday.addingTimeInterval(100)),
            ChatMessage(role: .assistant, text: "that makes total sense, friday's a lot to have hanging over you\nanxious brains love rehearsing the worst version\nwhat part of it worries you most?",
                        date: yesterday.addingTimeInterval(130)),
            ChatMessage(role: .user, text: "Honestly, some days it all just feels like too much.", date: earlier),
            ChatMessage(role: .assistant, text: "i'm really glad you told me\nwhen everything piles up it gets heavy in a way that's hard to put into words\nwhat's been the hardest part lately?",
                        checkIn: checkIn, date: earlier.addingTimeInterval(25)),
        ]
    }
}
