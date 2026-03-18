import SwiftUI

/// Block-fill progress bar: filled blocks left-to-right, empty blocks for remaining.
/// Example at 50%: ████░░░░
struct RetroProgressBar: View {
    let fraction: Double        // 0.0 – 1.0
    var blockCount: Int = 16    // total segments

    private let filledChar  = "█"
    private let emptyChar   = "░"

    // Internal — used by tests to verify block rendering without instantiating a View
    var displayString: String {
        let filled = Int((fraction * Double(blockCount)).rounded())
        let clamped = min(max(filled, 0), blockCount)
        return String(repeating: filledChar, count: clamped)
             + String(repeating: emptyChar,  count: blockCount - clamped)
    }

    var body: some View {
        Text(displayString)
            .font(RetroFont.regular(14))
            .foregroundColor(RetroColor.black)
            .lineLimit(1)
            .drawingGroup(opaque: false, colorMode: .linear)
    }
}
