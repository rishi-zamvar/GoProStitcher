import SwiftUI

// MARK: - Retro Color Palette
// Six colors only. No gradients, no opacity variants, no shadows.

enum RetroColor {
    static let beigeBackground = Color(hex: "#F2E9DA")   // root background
    static let beigeSecondary  = Color(hex: "#E4D8C4")   // secondary backgrounds
    static let white           = Color(hex: "#FFFFFF")   // card fills
    static let black           = Color(hex: "#000000")   // borders, primary text
    static let accentRed       = Color(hex: "#D72638")   // errors, recording state
    static let muted           = Color(hex: "#3A3A3A")   // secondary text
}

// MARK: - Retro Typography
// JetBrains Mono only. Bold for headers, Regular for body. No italic.

enum RetroFont {
    static func bold(_ size: CGFloat) -> Font {
        .custom("JetBrainsMono-Bold", size: size)
    }
    static func regular(_ size: CGFloat) -> Font {
        .custom("JetBrainsMono-Regular", size: size)
    }

    // Semantic aliases
    static let title:    Font = bold(20)
    static let subtitle: Font = regular(14)
    static let body:     Font = regular(13)
    static let caption:  Font = regular(11)
    static let label:    Font = bold(12)
}

// MARK: - Retro Spacing (4pt grid)

enum RetroSpacing {
    static let xs:  CGFloat = 4
    static let sm:  CGFloat = 8
    static let md:  CGFloat = 16
    static let lg:  CGFloat = 24
    static let xl:  CGFloat = 32
    static let xxl: CGFloat = 40
}

// MARK: - Color hex init helper

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: .init(charactersIn: "#"))
        let scanner = Scanner(string: hex)
        var rgb: UInt64 = 0
        scanner.scanHexInt64(&rgb)
        let r = Double((rgb >> 16) & 0xFF) / 255
        let g = Double((rgb >> 8)  & 0xFF) / 255
        let b = Double(rgb         & 0xFF) / 255
        self.init(red: r, green: g, blue: b)
    }
}
