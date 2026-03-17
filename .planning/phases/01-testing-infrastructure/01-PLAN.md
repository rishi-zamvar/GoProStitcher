---
phase: 01-testing-infrastructure
plan: 01
type: execute
wave: 1
depends_on: []
files_modified:
  - GoProStitcher.xcodeproj/project.pbxproj
  - GoProStitcher/GoProStitcherApp.swift
  - GoProStitcher/ContentView.swift
  - GoProStitcherKit/Package.swift
  - GoProStitcherKit/Sources/GoProStitcherKit/GoProStitcherKit.swift
  - GoProStitcherKit/Tests/GoProStitcherKitTests/GoProStitcherKitTests.swift
  - GoProStitcherIntegrationTests/GoProStitcherIntegrationTests.swift
  - GoProStitcherUITests/GoProStitcherUITests.swift
autonomous: true

must_haves:
  truths:
    - "xcodebuild -scheme GoProStitcher -destination 'generic/platform=macOS' build succeeds with zero errors"
    - "GoProStitcherKit is a local Swift Package dependency of the app target"
    - "Three test targets exist: GoProStitcherKitTests (unit), GoProStitcherIntegrationTests (integration), GoProStitcherUITests (UI)"
    - "xcodebuild test -scheme GoProStitcher runs all three test targets and reports pass/fail for each"
  artifacts:
    - path: "GoProStitcher.xcodeproj/project.pbxproj"
      provides: "Xcode project with app + 3 test targets, macOS 13 deployment target, TCA dependency"
    - path: "GoProStitcherKit/Package.swift"
      provides: "Local Swift Package manifest declaring GoProStitcherKit library product and GoProStitcherKitTests test target"
    - path: "GoProStitcherKit/Sources/GoProStitcherKit/GoProStitcherKit.swift"
      provides: "Minimal public API surface (empty enum or placeholder type) so the package compiles"
    - path: "GoProStitcherIntegrationTests/GoProStitcherIntegrationTests.swift"
      provides: "Skeleton integration test target that imports GoProStitcherKit and compiles"
    - path: "GoProStitcherUITests/GoProStitcherUITests.swift"
      provides: "Skeleton UI test target wired to GoProStitcher app target"
  key_links:
    - from: "GoProStitcher app target"
      to: "GoProStitcherKit"
      via: "local Swift Package dependency in project.pbxproj"
      pattern: "GoProStitcherKit"
    - from: "GoProStitcherIntegrationTests"
      to: "GoProStitcherKit"
      via: "import GoProStitcherKit in test file"
      pattern: "import GoProStitcherKit"
---

<objective>
Scaffold the Xcode project with the app target, a local Swift Package (GoProStitcherKit) for all core logic, and three test targets (unit inside the package, integration, UI).

Purpose: All subsequent phases write into GoProStitcherKit and the test targets created here. Nothing builds without this foundation.
Output: A compilable Xcode project with three runnable (empty) test suites.
</objective>

<execution_context>
@/Users/rishizamvar/.claude/get-shit-done/workflows/execute-plan.md
@/Users/rishizamvar/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/ROADMAP.md
@.planning/STATE.md
@.planning/phases/01-testing-infrastructure/01-CONTEXT.md
</context>

<tasks>

<task type="auto">
  <name>Task 1: Create Xcode project with app target (macOS 13, SwiftUI, TCA)</name>
  <files>
    GoProStitcher.xcodeproj/project.pbxproj
    GoProStitcher/GoProStitcherApp.swift
    GoProStitcher/ContentView.swift
  </files>
  <action>
    Use `xcodegen` if available, or create the project via `swift package init` scaffold + manual xcodeproj, or use the Xcode command-line approach. The preferred method is to run `xcodegen generate` with a project.yml — create the project.yml first then generate.

    project.yml spec:
    - name: GoProStitcher
    - macOS deployment target: 13.0
    - Swift version: 5.9+
    - App target: GoProStitcher, sources in GoProStitcher/, bundle ID com.rishizamvar.GoProStitcher
    - Dependencies: The Composable Architecture via Swift Package (https://github.com/pointfreeco/swift-composable-architecture, version "~> 1.15")
    - Code signing: DEVELOPMENT_TEAM = "", CODE_SIGN_IDENTITY = "-" (unsigned, for local builds)
    - Integration test target: GoProStitcherIntegrationTests, sources in GoProStitcherIntegrationTests/, test host = none (not hosted by the app), depends on GoProStitcherKit package
    - UI test target: GoProStitcherUITests, sources in GoProStitcherUITests/, test host = GoProStitcher app

    GoProStitcherApp.swift: minimal @main App struct with ContentView as WindowGroup content.
    ContentView.swift: Text("Hello, GoProStitcher!") placeholder — zero business logic.

    Do NOT add any app logic, navigation, or feature code. This is purely scaffolding.

    If xcodegen is not installed, install via `brew install xcodegen` and then generate. If brew is unavailable, create the Xcode project manually using Swift Package Manager + xcodeproj manipulation, but prefer xcodegen.
  </action>
  <verify>
    Run: `xcodebuild -project GoProStitcher.xcodeproj -scheme GoProStitcher -destination 'generic/platform=macOS' build`
    Expected: BUILD SUCCEEDED with zero errors.
  </verify>
  <done>App target compiles cleanly for macOS 13. TCA package is resolved. GoProStitcherApp.swift and ContentView.swift exist with minimal stubs.</done>
</task>

<task type="auto">
  <name>Task 2: Create GoProStitcherKit local Swift Package + wire as local dependency</name>
  <files>
    GoProStitcherKit/Package.swift
    GoProStitcherKit/Sources/GoProStitcherKit/GoProStitcherKit.swift
    GoProStitcherKit/Tests/GoProStitcherKitTests/GoProStitcherKitTests.swift
    GoProStitcherIntegrationTests/GoProStitcherIntegrationTests.swift
    GoProStitcherUITests/GoProStitcherUITests.swift
  </files>
  <action>
    1. Create GoProStitcherKit/ directory at project root (sibling to GoProStitcher/).
    2. Run `swift package init --name GoProStitcherKit --type library` inside GoProStitcherKit/.
    3. Edit Package.swift:
       - swift-tools-version: 5.9
       - platforms: [.macOS(.v13)]
       - products: library GoProStitcherKit (from "GoProStitcherKit" target)
       - targets: GoProStitcherKit (sources in Sources/GoProStitcherKit/), GoProStitcherKitTests (test target, depends on GoProStitcherKit)
    4. GoProStitcherKit.swift: single public enum GoProStitcherKit with a static let version = "1.0.0". This gives the package a public symbol and ensures it compiles.
    5. GoProStitcherKitTests.swift: one placeholder XCTestCase with `func testPlaceholder() { XCTAssertTrue(true) }`.
    6. Wire GoProStitcherKit as a local package dependency in the Xcode project (via xcodegen project.yml `localPackages` or via `File > Add Local Packages` equivalent in project.pbxproj). The app target must list GoProStitcherKit as a dependency.
    7. Create GoProStitcherIntegrationTests/GoProStitcherIntegrationTests.swift with: `import XCTest; import GoProStitcherKit; final class GoProStitcherIntegrationTests: XCTestCase { func testPlaceholder() { XCTAssertTrue(true) } }`
    8. Create GoProStitcherUITests/GoProStitcherUITests.swift with: `import XCTest; final class GoProStitcherUITests: XCTestCase { func testPlaceholder() { XCTAssertTrue(true) } }`

    The xcodegen project.yml must declare the integration and UI test targets. Update the project.yml from Task 1 before regenerating if needed.
  </action>
  <verify>
    Run: `swift build --package-path GoProStitcherKit`
    Expected: Build complete with no errors.

    Run: `swift test --package-path GoProStitcherKit`
    Expected: Test Suite 'All tests' passed — GoProStitcherKitTests.testPlaceholder passes.

    Run: `xcodebuild -project GoProStitcher.xcodeproj -scheme GoProStitcher -destination 'platform=macOS' test`
    Expected: All three test targets run and pass (3× testPlaceholder).
  </verify>
  <done>
    GoProStitcherKit package builds and its unit tests pass via `swift test`.
    The Xcode project resolves GoProStitcherKit as a local dependency.
    `xcodebuild test` reports all three test targets (GoProStitcherKitTests, GoProStitcherIntegrationTests, GoProStitcherUITests) as passed.
  </done>
</task>

</tasks>

<verification>
After both tasks complete:
1. `xcodebuild -project GoProStitcher.xcodeproj -scheme GoProStitcher -destination 'platform=macOS' build` → BUILD SUCCEEDED
2. `swift build --package-path GoProStitcherKit` → Build complete
3. `swift test --package-path GoProStitcherKit` → All tests passed
4. `xcodebuild -project GoProStitcher.xcodeproj -scheme GoProStitcher -destination 'platform=macOS' test` → 3 test suites all passed
5. GoProStitcherKit directory exists at project root with Package.swift, Sources/, and Tests/
6. No business logic in the app target — only App struct + ContentView placeholder
</verification>

<success_criteria>
- Xcode project created with macOS 13 deployment target and TCA dependency resolved
- GoProStitcherKit local Swift Package exists with library product and unit test target
- Three distinct test targets exist and all pass with placeholder tests via xcodebuild test
- Zero compilation errors across app + package
</success_criteria>

<output>
After completion, create `.planning/phases/01-testing-infrastructure/01-01-SUMMARY.md` with:
- What was created (project structure, key files)
- How to build and test (exact commands)
- Any deviations from plan (e.g., xcodegen not available → fallback approach used)
- Whether xcodegen was used or manual project creation
</output>
