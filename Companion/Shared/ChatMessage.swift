import Foundation

/// One row in the conversation. `text` is always what `AppModel` chose to show (sanitized while streaming), never
/// the raw model output.
struct ChatMessage: Identifiable, Equatable {
    enum Role { case user, assistant, crisisCard }
    enum CheckIn { case none, asking, okay }

    let id = UUID()
    let role: Role
    var text: String
    var checkIn = CheckIn.none
    var isStreaming = false
    var date = Date.now
}
