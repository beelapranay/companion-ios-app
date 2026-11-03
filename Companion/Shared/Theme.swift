import SwiftUI

/// Shared spacing, shapes and motion, so every screen keeps the same rhythm. Colors live in the asset catalog with
/// light and dark variants: AccentColor (text, icons, tints), Brand (fills behind white text), Canvas and CanvasTint
/// (the backdrop), Surface (content cards), Emergency and LaunchBackground.
///
/// Liquid Glass is for the control layer only: bars, the composer, buttons and floating controls. Content (bubbles,
/// cards, crisis resources) stays solid so it reads clearly, and glass is never stacked on glass. Emergency red is
/// only for real emergency options (crisis screen rows and the crisis card).
enum Theme {
    enum Spacing {
        static let tight: CGFloat = 4
        static let small: CGFloat = 8
        static let medium: CGFloat = 12
        static let large: CGFloat = 16
        static let section: CGFloat = 24
        static let screen: CGFloat = 32
        /// Keeps bubbles from spanning the full width, so the two sides read as a conversation.
        static let bubbleInset: CGFloat = 48
    }

    enum Radius {
        static let bubble: CGFloat = 22
        static let bubbleTail: CGFloat = 6
        static let card: CGFloat = 24
        static let field: CGFloat = 24
    }

    /// Chat content stops widening here, so lines stay readable on wide displays such as iPhone Duo's inner screen.
    static let readableWidth: CGFloat = 680
    static let minTapTarget: CGFloat = 44
    static let largeTapTarget: CGFloat = 64
    /// Messages from the same side closer together than this are drawn as one group.
    static let groupingGap: TimeInterval = 5 * 60
    /// A time label appears before a message that follows a pause longer than this.
    static let timestampGap: TimeInterval = 15 * 60

    /// Screen-level changes: pages, sheets of content appearing, new messages.
    static let spring = Animation.spring(duration: 0.5, bounce: 0.2)
    /// Small, immediate feedback: presses, toggles, buttons appearing.
    static let snappy = Animation.snappy(duration: 0.28)
    /// Fades and state changes that shouldn't bounce.
    static let motion = Animation.smooth(duration: 0.4)
}
