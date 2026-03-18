# Phase 9: VideoDownscaler Engine - Context

**Gathered:** 2026-03-18
**Status:** Ready for planning

<domain>
## Phase Boundary

Build the VideoDownscaler engine in GoProStitcherKit — wraps ffmpeg to downscale 4K MP4 to 1080p H.264 with audio passthrough. Test-first: full test suite before any UI wiring. Must follow the same patterns and hygiene as AudioExtractor (caseless enum, typed errors, TempDirectoryHelper tests).

</domain>

<decisions>
## Implementation Decisions

### Encoding Quality
- Preset: `slow` (best compression, smallest file size)
- CRF: 18 (high quality, visually lossless)
- Codec: H.264 via libx264
- Audio: `-c:a copy` (zero quality loss, non-negotiable)
- Full ffmpeg flags: `-vf scale=-2:1080 -c:v libx264 -preset slow -crf 18 -c:a copy`

### Output Naming Convention
- Default: `source_1080p.mp4` (append `_1080p` before extension, lowercase .mp4)
- Collision handling: `_1`, `_2` suffixes (same pattern as AudioExtractor)
- The user will be able to edit the filename before encoding starts (Phase 10 UI concern) — the engine just accepts an output name parameter
- Engine method signature: `downscale(url:outputName:progress:) throws -> URL`

### Progress Data
- Surface full encoding stats: percentage, time processed/total, current bitrate (kbps), current fps
- Parse from ffmpeg `-progress pipe:1` output: `out_time_us`, `bitrate`, `fps`, `progress=end`
- Progress callback type: `(DownscaleProgress) -> Void` where DownscaleProgress is a struct with fraction, secondsProcessed, totalSeconds, bitrateKbps, fps
- Total duration obtained via ffprobe (same pattern as AudioExtractor)

### Error Handling
- Source already 1080p or lower: **block it** — return typed error `.alreadyAtTargetResolution` before starting encode
- Check resolution via ffprobe before starting ffmpeg
- Missing ffmpeg: `.ffmpegNotFound` (same pattern as AudioExtractor)
- Missing input: `.inputNotFound(URL)`
- Encoding failure (non-zero exit): `.encodingFailed(String)` — delete partial output file
- Mid-encode failure: always clean up partial output (defer block removes incomplete file)

### Test-First Approach
- Follow exact same test hygiene as AudioExtractorTests
- Use TempDirectoryHelper, ffmpeg lavfi fixtures, XCTSkipUnless(ffmpegPresent)
- Tests: encoding produces valid 1080p output, audio stream preserved, collision handling, all error paths, progress callback fires, already-1080p blocked
- Must pass with `swift test --package-path GoProStitcherKit` and `xcodebuild test`

### Claude's Discretion
- Exact ffprobe resolution detection approach (parse stream width/height)
- Whether to add `-movflags +faststart` for web-friendly output
- Buffer size for progress pipe reading
- Whether DownscaleProgress struct lives in GoProStitcherKit or the engine file

</decisions>

<specifics>
## Specific Ideas

- Mirror AudioExtractor pattern exactly: caseless enum, static method, typed error enum, progress callback
- Engine should be as light and efficient as possible — no unnecessary abstractions
- Same test fixture approach (ffmpeg lavfi for generating test MP4s with known resolution)

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 09-videodownscaler-engine*
*Context gathered: 2026-03-18*
