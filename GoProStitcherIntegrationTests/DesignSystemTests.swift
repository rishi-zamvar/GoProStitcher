import XCTest
import SwiftUI
@testable import GoProStitcher

final class DesignSystemTests: XCTestCase {

    // MARK: - Color Token Tests

    func test_colorTokens_haveCorrectHexValues() {
        // Verify each token resolves to the expected sRGB components (±0.005 tolerance)
        assertColor(RetroColor.beigeBackground, hex: "#F2E9DA")
        assertColor(RetroColor.beigeSecondary,  hex: "#E4D8C4")
        assertColor(RetroColor.white,            hex: "#FFFFFF")
        assertColor(RetroColor.black,            hex: "#000000")
        assertColor(RetroColor.accentRed,        hex: "#D72638")
        assertColor(RetroColor.muted,            hex: "#3A3A3A")
    }

    // MARK: - Font Registration Tests

    func test_jetBrainsMonoRegular_isRegistered() {
        // CTFontDescriptor lookup confirms the font is available at runtime
        let descriptor = CTFontDescriptorCreateWithNameAndSize(
            "JetBrainsMono-Regular" as CFString, 14
        )
        let font = CTFontCreateWithFontDescriptor(descriptor, 14, nil)
        let name = CTFontCopyPostScriptName(font) as String
        XCTAssertEqual(name, "JetBrainsMono-Regular",
                       "JetBrainsMono-Regular not registered — check Info.plist ATSApplicationFontsPath")
    }

    func test_jetBrainsMonoBold_isRegistered() {
        let descriptor = CTFontDescriptorCreateWithNameAndSize(
            "JetBrainsMono-Bold" as CFString, 14
        )
        let font = CTFontCreateWithFontDescriptor(descriptor, 14, nil)
        let name = CTFontCopyPostScriptName(font) as String
        XCTAssertEqual(name, "JetBrainsMono-Bold",
                       "JetBrainsMono-Bold not registered — check Info.plist ATSApplicationFontsPath")
    }

    // MARK: - Spacing Tests

    func test_allSpacingConstants_areMultiplesOf4() {
        let constants: [CGFloat] = [
            RetroSpacing.xs, RetroSpacing.sm, RetroSpacing.md,
            RetroSpacing.lg, RetroSpacing.xl, RetroSpacing.xxl
        ]
        for value in constants {
            XCTAssertEqual(value.truncatingRemainder(dividingBy: 4), 0,
                           "\(value) is not a multiple of 4")
        }
    }

    // MARK: - RetroProgressBar Block Tests

    func test_retroProgressBar_allFilled_atFraction1() {
        // fraction 1.0, 8 blocks -> "████████"
        let bar = RetroProgressBar(fraction: 1.0, blockCount: 8)
        let display = bar.displayString
        XCTAssertEqual(display, "████████")
    }

    func test_retroProgressBar_allEmpty_atFraction0() {
        let bar = RetroProgressBar(fraction: 0.0, blockCount: 8)
        XCTAssertEqual(bar.displayString, "░░░░░░░░")
    }

    func test_retroProgressBar_halfFilled_atFraction0point5() {
        let bar = RetroProgressBar(fraction: 0.5, blockCount: 8)
        XCTAssertEqual(bar.displayString, "████░░░░")
    }

    func test_retroProgressBar_clamps_aboveOne() {
        let bar = RetroProgressBar(fraction: 1.5, blockCount: 8)
        XCTAssertEqual(bar.displayString, "████████")
    }

    func test_retroProgressBar_clamps_belowZero() {
        let bar = RetroProgressBar(fraction: -0.5, blockCount: 8)
        XCTAssertEqual(bar.displayString, "░░░░░░░░")
    }

    // MARK: - Helpers

    private func assertColor(_ color: Color, hex: String,
                              file: StaticString = #file, line: UInt = #line) {
        let hexClean = hex.trimmingCharacters(in: .init(charactersIn: "#"))
        var rgb: UInt64 = 0
        Scanner(string: hexClean).scanHexInt64(&rgb)
        let er = Double((rgb >> 16) & 0xFF) / 255
        let eg = Double((rgb >> 8)  & 0xFF) / 255
        let eb = Double(rgb         & 0xFF) / 255

        let resolved = NSColor(color).usingColorSpace(.sRGB)!
        XCTAssertEqual(Double(resolved.redComponent),   er, accuracy: 0.005, file: file, line: line)
        XCTAssertEqual(Double(resolved.greenComponent), eg, accuracy: 0.005, file: file, line: line)
        XCTAssertEqual(Double(resolved.blueComponent),  eb, accuracy: 0.005, file: file, line: line)
    }
}
