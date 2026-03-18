import SwiftUI

/// Centered pill button in 8-bit style.
/// Default: black fill, beige text, 0 corner radius, 2px black border.
/// Hover: inverted (beige fill, black text).
struct RetroButton: View {
    let title: String
    let action: () -> Void
    var isDisabled: Bool = false

    @State private var isHovered = false

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(RetroFont.bold(13))
                .foregroundColor(isHovered ? RetroColor.black : RetroColor.beigeBackground)
                .padding(.horizontal, RetroSpacing.lg)
                .padding(.vertical, RetroSpacing.sm)
                .background(isHovered ? RetroColor.beigeSecondary : RetroColor.black)
                .overlay(
                    Rectangle()
                        .stroke(RetroColor.black, lineWidth: 2)
                )
        }
        .buttonStyle(.plain)
        .disabled(isDisabled)
        .opacity(isDisabled ? 0.4 : 1.0)
        .onHover { isHovered = $0 }
    }
}

/// ButtonStyle variant for use with SwiftUI's .buttonStyle() modifier.
struct RetroButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .font(RetroFont.bold(13))
            .foregroundColor(RetroColor.beigeBackground)
            .padding(.horizontal, RetroSpacing.lg)
            .padding(.vertical, RetroSpacing.sm)
            .background(configuration.isPressed ? RetroColor.muted : RetroColor.black)
            .overlay(Rectangle().stroke(RetroColor.black, lineWidth: 2))
    }
}
