import Foundation
import Observation

/// What the views need from the app's model. `AppModel` is the real one; `PreviewChatModel` serves canned
/// conversations to previews and the Simulator demo, where MLX can't run.
@MainActor
protocol ChatModel: AnyObject, Observable {
    var phase: ModelPhase { get }
    var messages: [ChatMessage] { get }
    var showCrisis: Bool { get set }
    var isGenerating: Bool { get }

    func load() async
    func send(_ raw: String) async
    func answerCheckIn(_ id: UUID, safe: Bool)
}
