---
phase: 01-testing-infrastructure
plan: 02
type: execute
wave: 2
depends_on: ["01-PLAN"]
files_modified:
  - GoProStitcherKit/Sources/GoProStitcherKit/TestHelpers/TempDirectoryHelper.swift
  - GoProStitcherKit/Sources/GoProStitcherKit/TestHelpers/GoProFileFactory.swift
  - GoProStitcherKit/Tests/GoProStitcherKitTests/TestHelpersTests.swift
  - GoProStitcherIntegrationTests/Resources/README.md
  - test-data/.gitkeep
  - .gitignore
  - scripts/run-tests.sh
autonomous: true

must_haves:
  truths:
    - "TempDirectoryHelper creates a unique temp directory, returns its URL, and deletes it on teardown with a single call"
    - "GoProFileFactory.makeChunk(chapter:fileNumber:prefix:sizeBytes:) creates a file at the correct GoPro name (e.g. GH010001.MP4) with the specified number of bytes in a given directory"
    - "GoProFileFactory.makeSequence(count:prefix:fileNumber:) creates a properly ordered sequence of GoPro chunks ready for stitch order tests"
    - "scripts/run-tests.sh runs the full Xcode test suite and exits 0 on pass, non-zero on failure"
    - "test-data/ directory is gitignored; tiny fixture placeholder (README) is tracked in GoProStitcherIntegrationTests/Resources/"
  artifacts:
    - path: "GoProStitcherKit/Sources/GoProStitcherKit/TestHelpers/TempDirectoryHelper.swift"
      provides: "TempDirectoryHelper struct with create() -> URL and cleanup(url:) methods; can be used in setUp/tearDown"
      exports: ["TempDirectoryHelper"]
    - path: "GoProStitcherKit/Sources/GoProStitcherKit/TestHelpers/GoProFileFactory.swift"
      provides: "GoProFileFactory with static factory methods for creating synthetic GoPro-named MP4 files at arbitrary byte sizes"
      exports: ["GoProFileFactory"]
    - path: "GoProStitcherKit/Tests/GoProStitcherKitTests/TestHelpersTests.swift"
      provides: "Tests verifying TempDirectoryHelper and GoProFileFactory behave correctly"
    - path: "scripts/run-tests.sh"
      provides: "CI-ready shell script that runs xcodebuild test and produces clean pass/fail output"
    - path: ".gitignore"
      provides: "Entries for test-data/, DerivedData/, .DS_Store, *.xcuserstate"
  key_links:
    - from: "GoProStitcherKitTests"
      to: "TempDirectoryHelper + GoProFileFactory"
      via: "import within test files"
      pattern: "TempDirectoryHelper|GoProFileFactory"
    - from: "scripts/run-tests.sh"
      to: "GoProStitcher.xcodeproj"
      via: "xcodebuild -project ... test"
      pattern: "xcodebuild.*test"
---

<objective>
Add test helper utilities — TempDirectoryHelper and GoProFileFactory — plus a CI-ready test runner script, gitignore entries, and the test-data directory skeleton.

Purpose: Feature phases (2-4) use these helpers in every test. Without them, every test has to re-implement temp directory setup and synthetic file creation. This plan makes the infrastructure reusable.
Output: Two Swift helper types with tests, a CI script, and a .gitignore that keeps large test fixtures out of git.
</objective>

<execution_context>
@/Users/rishizamvar/.claude/get-shit-done/workflows/execute-plan.md
@/Users/rishizamvar/.claude/get-shit-done/templates/summary.md
</execution_context>

<context>
@.planning/PROJECT.md
@.planning/phases/01-testing-infrastructure/01-CONTEXT.md
@.planning/phases/01-testing-infrastructure/01-01-SUMMARY.md
</context>

<tasks>

<task type="auto">
  <name>Task 1: TempDirectoryHelper + GoProFileFactory with tests</name>
  <files>
    GoProStitcherKit/Sources/GoProStitcherKit/TestHelpers/TempDirectoryHelper.swift
    GoProStitcherKit/Sources/GoProStitcherKit/TestHelpers/GoProFileFactory.swift
    GoProStitcherKit/Tests/GoProStitcherKitTests/TestHelpersTests.swift
  </files>
  <action>
    Create GoProStitcherKit/Sources/GoProStitcherKit/TestHelpers/ directory.

    **TempDirectoryHelper.swift:**
    ```swift
    public struct TempDirectoryHelper {
        /// Creates a uniquely-named temp directory under FileManager.default.temporaryDirectory.
        /// Caller must call cleanup(url:) in tearDown.
        public static func create() throws -> URL {
            let dir = FileManager.default.temporaryDirectory
                .appendingPathComponent("GoProStitcherTests-\(UUID().uuidString)", isDirectory: true)
            try FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
            return dir
        }
        /// Deletes the directory and all contents. Silently ignores "does not exist" errors.
        public static func cleanup(url: URL) {
            try? FileManager.default.removeItem(at: url)
        }
    }
    ```

    **GoProFileFactory.swift:**
    Public struct with these static methods:
    - `makeChunk(in directory: URL, chapter: Int, fileNumber: Int, prefix: String = "GH", sizeBytes: Int = 1024) throws -> URL`
      - Validates prefix is "GH" or "GX", chapter 1-99, fileNumber 1-9999
      - Formats filename as "\(prefix)\(String(format: "%02d", chapter))\(String(format: "%04d", fileNumber)).MP4"
      - Writes `sizeBytes` of zero-filled Data to that URL in `directory`
      - Returns the file URL
    - `makeSequence(in directory: URL, count: Int, prefix: String = "GH", fileNumber: Int = 1, chunkSizeBytes: Int = 1024) throws -> [URL]`
      - Creates `count` chunks with chapter numbers 1..count (chapter increments per chunk, fileNumber stays fixed)
      - Returns URLs in correct stitch order (chapter 1 first)
    - `goProName(prefix: String, chapter: Int, fileNumber: Int) -> String`
      - Pure name formatter, no file system access — useful in unit tests for name parsing

    **TestHelpersTests.swift:**
    XCTestCase with:
    - `testTempDirectoryCreateAndCleanup`: calls create(), confirms directory exists, calls cleanup(), confirms directory is gone
    - `testMakeChunkCreatesCorrectFilename`: makeChunk(chapter: 1, fileNumber: 1, prefix: "GH") → file named "GH010001.MP4" at returned URL
    - `testMakeChunkCreatesCorrectFilenameGX`: prefix "GX" → "GX010001.MP4"
    - `testMakeChunkHasCorrectSize`: sizeBytes: 512 → returned file's size is 512 bytes
    - `testMakeSequenceOrder`: makeSequence(count: 3) → [GH010001.MP4, GH020001.MP4, GH030001.MP4] in that order
    - `testGoProNameFormatter`: goProName(prefix: "GH", chapter: 2, fileNumber: 15) == "GH020015.MP4"

    Each test creates a temp dir via TempDirectoryHelper and cleans up in tearDown.
  </action>
  <verify>
    Run: `swift test --package-path GoProStitcherKit --filter TestHelpersTests`
    Expected: 6 tests pass, 0 failures.
  </verify>
  <done>
    TempDirectoryHelper and GoProFileFactory are public API in GoProStitcherKit.
    All 6 TestHelpersTests pass via `swift test`.
    Filenames produced match GoPro naming format exactly: prefix (2 chars) + chapter (2-digit zero-padded) + fileNumber (4-digit zero-padded) + ".MP4".
  </done>
</task>

<task type="auto">
  <name>Task 2: CI test runner script + .gitignore + test-data directory</name>
  <files>
    scripts/run-tests.sh
    .gitignore
    test-data/.gitkeep
    GoProStitcherIntegrationTests/Resources/README.md
  </files>
  <action>
    **scripts/run-tests.sh:**
    Create scripts/ directory at project root. Create run-tests.sh:
    ```bash
    #!/usr/bin/env bash
    set -euo pipefail

    PROJECT_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
    SCHEME="GoProStitcher"
    DESTINATION="platform=macOS"

    echo "=== GoProStitcher Test Suite ==="
    echo "Project: $PROJECT_ROOT"
    echo ""

    # Run Swift Package unit tests
    echo "--- GoProStitcherKit unit tests ---"
    swift test --package-path "$PROJECT_ROOT/GoProStitcherKit" 2>&1
    PACKAGE_EXIT=$?

    # Run Xcode test suite (integration + UI tests)
    echo ""
    echo "--- Xcode test suite (integration + UI) ---"
    xcodebuild test \
      -project "$PROJECT_ROOT/GoProStitcher.xcodeproj" \
      -scheme "$SCHEME" \
      -destination "$DESTINATION" \
      -resultBundlePath "$PROJECT_ROOT/.build/TestResults.xcresult" \
      2>&1 | xcpretty || true
    XCODE_EXIT=${PIPESTATUS[0]}

    echo ""
    if [ $PACKAGE_EXIT -eq 0 ] && [ $XCODE_EXIT -eq 0 ]; then
      echo "=== ALL TESTS PASSED ==="
      exit 0
    else
      echo "=== TEST FAILURES DETECTED ==="
      echo "Package tests exit: $PACKAGE_EXIT"
      echo "Xcode tests exit: $XCODE_EXIT"
      exit 1
    fi
    ```
    Make executable: `chmod +x scripts/run-tests.sh`

    Note: xcpretty is optional — the script uses `|| true` so it doesn't fail if xcpretty isn't installed. Raw xcodebuild output is still captured.

    **.gitignore:**
    Create .gitignore at project root with:
    ```
    # Xcode
    .DS_Store
    *.xcuserstate
    xcuserdata/
    DerivedData/
    .build/
    *.xcscmblueprint

    # Large test fixtures (real GoPro clips — gitignored, copy manually)
    test-data/

    # Swift Package Manager
    .swiftpm/
    GoProStitcherKit/.build/

    # OS
    .DS_Store
    Thumbs.db
    ```

    **test-data/.gitkeep:**
    Create test-data/ directory at project root. Add empty .gitkeep file inside it so the directory is tracked via the .gitkeep, but the actual video files will be gitignored. Add a comment in .gitignore: `test-data/*.mp4` to be explicit — or just `test-data/` which ignores everything inside.

    Actually: because .gitignore says `test-data/`, the .gitkeep inside won't be tracked. That's fine — just create the directory and document it. Add test-data/ to .gitignore.

    **GoProStitcherIntegrationTests/Resources/README.md:**
    Create GoProStitcherIntegrationTests/Resources/ directory. Add README.md:
    ```
    # Integration Test Fixtures

    Tiny GoPro clip fixtures (~1-5 MB each) for CI-safe integration tests go here.
    These files are committed to git and bundled with the integration test target.

    ## Required files (add before running integration tests in Phase 2+)
    - GH010001.MP4 — first chunk, trimmed to ~2 MB
    - GH020001.MP4 — second chunk, trimmed to ~2 MB
    - GH030001.MP4 — third chunk, trimmed to ~2 MB

    ## Full-size fixtures
    Full-size 4GB GoPro chunks go in test-data/ at the project root.
    That directory is gitignored. Copy files there manually for local integration testing.
    ```
  </action>
  <verify>
    Run: `bash scripts/run-tests.sh`
    Expected: Script runs to completion. "ALL TESTS PASSED" printed. Exit code 0.

    Check gitignore is working: `git check-ignore -v test-data/` should output a match.
    Check script is executable: `ls -la scripts/run-tests.sh` shows -rwxr-xr-x.
  </verify>
  <done>
    scripts/run-tests.sh is executable, runs all tests, exits 0 when tests pass.
    .gitignore covers DerivedData, xcuserstate, test-data/, .build/.
    test-data/ directory exists at project root and is gitignored.
    GoProStitcherIntegrationTests/Resources/README.md documents fixture expectations for Phase 2.
  </done>
</task>

</tasks>

<verification>
After both tasks complete:
1. `swift test --package-path GoProStitcherKit --filter TestHelpersTests` → 6 tests passed
2. `swift test --package-path GoProStitcherKit` → All tests passed (includes placeholder from Plan 01)
3. `bash scripts/run-tests.sh` → exits 0, prints "ALL TESTS PASSED"
4. `git check-ignore -v test-data/` → matched by .gitignore
5. GoProFileFactory.makeChunk(in:chapter:fileNumber:prefix:sizeBytes:) and makeSequence(in:count:) are callable from any test target that imports GoProStitcherKit
6. TempDirectoryHelper.create() and cleanup(url:) are callable from any test target
</verification>

<success_criteria>
- 6 new unit tests in TestHelpersTests all pass
- GoProFileFactory produces filenames matching GoPro naming convention exactly (GH/GX + 2-digit chapter + 4-digit file number + .MP4)
- TempDirectoryHelper correctly manages temp directory lifecycle (create + cleanup confirmed by test)
- CI script runs full test suite and exits 0
- test-data/ and DerivedData/ are gitignored
- Resources/README.md documents what real fixture clips are needed and where full-size files go
</success_criteria>

<output>
After completion, create `.planning/phases/01-testing-infrastructure/01-02-SUMMARY.md` with:
- Public API of TempDirectoryHelper and GoProFileFactory (method signatures)
- How feature phase test authors should use these helpers
- Location of CI script and how to run it
- Test fixture strategy recap (tiny fixtures in Resources/, full-size in test-data/)
</output>
