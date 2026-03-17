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
