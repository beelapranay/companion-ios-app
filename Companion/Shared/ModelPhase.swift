/// Where startup is: loading (with a download fraction when there is one), ready to chat, or failed.
enum ModelPhase: Equatable {
    case loading(String, Double?)
    case ready
    case failed(String)
}
