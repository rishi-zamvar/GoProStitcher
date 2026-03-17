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
