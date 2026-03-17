import XCTest
@testable import GoProStitcherKit

final class GoProStitcherKitTests: XCTestCase {
    func testPlaceholder() {
        XCTAssertTrue(true)
    }

    func testVersion() {
        XCTAssertFalse(GoProStitcherKit.version.isEmpty)
    }
}
