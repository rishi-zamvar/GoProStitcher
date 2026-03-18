# Domain Pitfalls: Audio Extraction + Multi-Tool Architecture

**Project:** GoPro Toolkit v1.1
**Researched:** 2026-03-18
**Scope:** Audio extraction and multi-tool restructure (home screen)
**Confidence:** HIGH (based on v1.0 lessons + audio processing domain patterns)

---

## Critical Pitfalls

Mistakes that cause rewrites, major issues, or user-facing failures.

### Pitfall 1: ffmpeg Not Installed, User Gets Cryptic Error

**What goes wrong:**
User launches app, clicks "Extract Audio", selects an MP4, and gets error: "ffmpeg not found" or "exit code 127".

User thinks app is broken. Uninstalls. Never discovers solution (brew install ffmpeg).

**Why it happens:**
No pre-flight check. Code assumes ffmpeg is in PATH. ~50% of macOS users don't have Homebrew installed.

**Consequences:**
- App appears broken to half the user base
- Support emails: "why doesn't extract work?"
- Bad first impression (app doesn't work on day 1)
- User never tries again

**Prevention:**
1. **At app launch:** Search for ffmpeg in standard paths (`/opt/homebrew/bin/ffmpeg`, `/usr/local/bin/ffmpeg`, `/usr/bin/ffmpeg`)
2. **If not found:** Show error dialog with installation instructions:
   ```
   "ffmpeg not installed. Install with: brew install ffmpeg"
   ```
3. **Or:** Disable audio extraction button if ffmpeg missing (graceful degradation)

**Detection:**
- Test on clean macOS installation (Homebrew not installed)
- Try "Extract Audio" button → verify helpful error message

**Recommended:**
Implement check at app launch (v1.0 ChunkStitcher already does this). Show one-time alert if missing. Link to installation instructions.

---

### Pitfall 2: Output MP3 File Overwrites Without Warning

**What goes wrong:**
User extracts `video.mp4` → `video.mp3`.

User repeats extraction (accidentally, or intentionally).

ffmpeg silently overwrites `video.mp3` with new output. User loses first extraction.

**Why it happens:**
ffmpeg `-y` flag (overwrite) is standard. Code doesn't check if destination exists before extraction.

**Consequences:**
- Silent data loss (user doesn't notice until later)
- User loses trust in reliability
- Potential support complaint: "I lost my extracted audio!"

**Prevention:**
1. **Before extraction:** Check if output path exists
2. **If exists:** Show dialog:
   - "Replace?" (overwrite with warning)
   - "Cancel" (user picks different file/directory)
   - "Save As..." (pick new filename)
3. **Only proceed if user confirms**

**Detection:**
- Manual test: Extract same file twice → verify dialog appears before overwrite
- Unit test: file existence check works correctly

**Recommended:**
Implement file existence check + dialog in AudioExtractionProgressFeature before calling AudioExtractor.extract(). Standard pattern (matches Word, Finder, etc.).

---

### Pitfall 3: Extraction Appears to Hang (No Progress Feedback)

**What goes wrong:**
User selects 2GB MP4, clicks Extract. App shows nothing for 60 seconds.

User thinks app is frozen. Force-quits. Partial MP3 left behind.

**Why it happens:**
Process.run() is synchronous and blocking. UI doesn't update while ffmpeg subprocess runs. No visual feedback ("Extracting...").

**Consequences:**
- App appears non-responsive/frozen
- User force-quits, loses trust in reliability
- Partial file left behind on disk (cleanup problem)

**Prevention:**
1. **Show status immediately:** Display "Extracting..." before calling AudioExtractor.extract()
2. **Update UI periodically:** Every 5-10 seconds, even simple "Still extracting... 45 seconds elapsed" shows responsiveness
3. **Optional:** Smooth progress bar (parse ffmpeg stderr). Defer to v1.2 if complex.
4. **Safety timeout:** 10-minute max. If ffmpeg hangs, cancel gracefully with error.

**Detection:**
- Manual test: Extract large file (>1GB). Watch for immediate UI feedback.
- UI should show "Extracting..." within 100ms.
- Every 10 seconds, update should fire.

**Recommended:**
Implement AudioExtractionProgressFeature showing "Extracting..." immediately. Update status every N seconds. Add timeout safety (10 minutes = 600 seconds).

---

### Pitfall 4: CBR vs. VBR Confusion (Bitrate Doesn't Match)

**What goes wrong:**
Developer uses `-qscale:a` (VBR) instead of `-b:a 320k` (CBR).

ffmpeg produces MP3 with average bitrate 180-280k (varies).

User expects "320kbps MP3" to mean exactly 320k. Checks with ffprobe, sees "avg 240k". Thinks extraction is broken or low quality.

**Why it happens:**
Confusion between VBR (Variable Bitrate, efficient) and CBR (Constant Bitrate, predictable).

Online recommendations are mixed (some recommend VBR for "quality", some CBR for "consistency").

**Consequences:**
- User thinks extraction is broken or low quality
- Support complaints about "wrong bitrate"
- Code refactoring required later

**Prevention:**
1. **Use verified flags from STACK.md:** `-b:a 320k` (CBR mode only)
2. **Document reasoning in code comment:** "CBR 320k guarantees exactly 320kbps. VBR is variable and unpredictable."
3. **Unit test:** Extract sample MP4, verify output bitrate is exactly 320k using ffprobe

**Detection:**
- Unit test: Extract, run `ffprobe -v error -select_streams a:0 -show_entries stream=bit_rate`, verify bitrate is 320000

**Recommended:**
Use flags from STACK.md. Add comment. Include bitrate verification in unit test.

---

### Pitfall 5: Tool State Entanglement (Shared State Between Stitch and Audio)

**What goes wrong:**
Both tools share a `processingProgress` field or similar in AppFeature.State.

User starts stitching. Mid-way, user hits home and starts audio extraction.

Stitch progress and audio progress fight over same UI state. Progress jumps around or gets stuck.

**Why it happens:**
Trying to save code by reusing state structs. Both progress indicators look similar (both show %, both show status), so developer assumes they can share.

**Consequences:**
- State management becomes fragile and hard to debug
- Adding tool 3 requires refactoring both existing tools
- Testing becomes impossible (state is entangled)
- Race conditions if both tools run concurrently (future feature)

**Prevention:**
1. **Each tool has completely independent state struct**
2. **No shared progress fields.** AudioExtractionProgressFeature.State and StitchProgressFeature.State are separate, never mixed
3. **Enforce in code review:** Each tool feature is self-contained
4. **Document as architectural principle:** "Tools are independent; no shared state"

**Detection:**
- Code review: Check that tool state structs don't import each other
- Grep for "progress" across feature files: should be isolated per-tool
- Test: Can both tools run independently? (No state conflicts?)

**Recommended:**
Follow ARCHITECTURE.md design: each tool has independent state hierarchy. No sharing. Non-negotiable principle. Document in README.

---

### Pitfall 6: Process Subprocess Doesn't Fail Gracefully

**What goes wrong:**
ffmpeg exits with error code (corrupted MP4, missing audio stream, disk full, permissions denied).

Code doesn't check exit code. Treats non-zero exit as success.

User gets silent/corrupted MP3 (0 bytes, or empty audio).

**Why it happens:**
Swift Process API doesn't throw on command failure (unlike shell scripting). Developers must explicitly check `process.terminationStatus`.

Stderr is often ignored (redirected to /dev/null).

**Consequences:**
- User gets unplayable output (silent confusion)
- No error message to guide user
- Wasted time debugging
- If batch extraction exists, silent corruption amplifies (100 files corrupted)

**Prevention:**
1. **Always check exit code:**
   ```swift
   guard process.terminationStatus == 0 else {
       throw AudioExtractorError.ffmpegFailed("exit code \(process.terminationStatus)")
   }
   ```
2. **Capture stderr and log errors:**
   ```swift
   let pipe = Pipe()
   process.standardError = pipe
   // ... run process ...
   let errorData = pipe.fileHandleForReading.readDataToEndOfFile()
   let errorMessage = String(data: errorData, encoding: .utf8) ?? "Unknown"
   // Log or show to user
   ```
3. **Pre-flight checks:** Verify input exists, output directory writable, disk space available
4. **Cleanup on failure:** Delete incomplete output file if extraction fails

**Detection:**
- Unit test: Run ffmpeg with invalid arguments → verify AudioExtractorError is thrown
- Manual test: Try extracting video-only file (no audio) → verify error message appears (not silent failure)
- Manual test: Fill disk, attempt extraction → verify error message (not silent corruption)

**Recommended:**
Implement comprehensive error handling (check exit code + capture stderr). Add pre-flight validation. Cleanup partial files on failure. Test with actual failure scenarios.

---

## Moderate Pitfalls

Mistakes that cause delays or technical debt.

### Pitfall 7: Output File Paths Have Edge Cases

**What goes wrong:**
Code derives output path: `video.mp4` → `video.mp3` (simple string replacement).

Edge cases break it:
- `my-video (1).mp4` → `my-video (1).mp3` (looks ok, works)
- `.mp4` (hidden file) → `.mp3` (becomes hidden MP3, confusing)
- `video.backup.mp4` → `video.backup.mp3` (not what user wanted; wanted sibling with different name)
- `video..mp4` → `video..mp3` (weird, but works)
- Special characters: `café.mp4` → `café.mp3` (encoding issues if not careful)

**Why it happens:**
Simple string replacement without using Foundation URL APIs. Path handling is tricky.

**Consequences:**
- Output files have unexpected names
- Hidden files cause user confusion
- Potential collisions if multiple variants exist
- Support complaints: "where's my extracted file?"

**Prevention:**
1. **Use Foundation URL APIs:**
   ```swift
   let outputURL = sourceURL.deletingPathExtension().appendingPathExtension("mp3")
   ```
2. **Test edge cases:**
   - Files with spaces, dots, special characters
   - Hidden files
   - Long filenames (256+ char limit)
   - Filenames with extensions like `.backup.mp4`
3. **Collision handling:** If destination exists, append timestamp or version number

**Detection:**
- Unit test: Path derivation with various inputs (spaces, dots, special chars, hidden files)
- Manual test: Extract files with non-standard names

**Recommended:**
Use Foundation URL APIs. Add unit tests for edge cases. Implement collision detection with timestamp suffix.

---

### Pitfall 8: No Timeout on ffmpeg Process

**What goes wrong:**
ffmpeg hangs on corrupted MP4 or network stream.

User's app hangs indefinitely. Force-quit required. Partial file left behind.

**Why it happens:**
Process.run() blocks forever if subprocess doesn't exit. No timeout implemented.

**Consequences:**
- App appears frozen
- User force-quits
- Partial/corrupted MP3 on disk
- Next user attempt finds corrupted file, tries to extract again

**Prevention:**
1. **Set timeout:** If ffmpeg doesn't finish in 10 minutes, kill process and return error
2. **Use DispatchSourceTimer:** Monitor process duration. Send SIGTERM if timeout exceeded.
3. **Show error:** "Extraction took too long. The file may be corrupted. Try a different file."

**Detection:**
- Manual test: Try extracting corrupted or unusual MP4 (network stream, very large). Verify app doesn't hang.

**Recommended (MVP):**
Not critical for v1.1 (most extractions < 2 minutes). Add to future roadmap as safety valve.

---

### Pitfall 9: File Permissions / Disk Space Issues

**What goes wrong:**
User selects MP4 on read-only external drive or restricted folder.

User's output directory doesn't have write permissions.

ffmpeg fails with "permission denied" (confusing — which permission?).

**Why it happens:**
Assuming output directory is always writable. It might not be (external drive, restricted folder, mounted network drive, full disk).

**Consequences:**
- Confusing error message
- User doesn't know if it's input or output permission
- Wasted time troubleshooting

**Prevention:**
1. **Check output directory writable before extraction:**
   ```swift
   guard FileManager.default.fileExists(atPath: outputDir.path) &&
         FileManager.default.isWritableFileAtPath(outputDir.path) else {
       throw AudioExtractorError.invalidDestination(outputDir)
   }
   ```
2. **Clear error message:** "Can't save to this location. Check folder permissions or try a different folder."
3. **Suggest fallback:** "Would you like to save to Desktop instead?"
4. **Check disk space before extraction:** Warn if < 1GB free

**Detection:**
- Manual test: Try extracting to read-only directory (chmod 444)
- Manual test: Try with almost-full disk (< 100MB free)

**Recommended (MVP):**
Catch FileManager errors, show user-friendly error. Add disk space check. Pre-flight validation of output directory.

---

## Minor Pitfalls

Mistakes that cause annoyance but are fixable.

### Pitfall 10: Misleading Error Messages from ffmpeg

**What goes wrong:**
User gets error: "ffmpeg failed: exit code 1"

User has no idea what "exit code 1" means. Is input corrupted? Is ffmpeg broken? Not enough disk space?

**Why it happens:**
Showing raw ffmpeg exit codes without context. Different codes mean different things (invalid input, missing audio, disk full, etc.).

**Consequences:**
- User confusion and frustration
- Support emails asking "what does exit code 1 mean?"
- User feels app is unreliable

**Prevention:**
1. **Parse ffmpeg stderr for error details**
2. **Map to user-friendly messages:**
   - stderr contains "audio" → "This file doesn't have audio"
   - stderr contains "space" → "Not enough disk space"
   - default → "Extraction failed. The file may be corrupted."
3. **Show helpful next steps:** "Try a different file" or "Free up disk space"

**Detection:**
- Manual test: Various failure scenarios (bad file, full disk, etc.)
- Verify error messages are clear and actionable

**Recommended:**
Use ChunkStitcherError pattern (LocalizedError + errorDescription). Add specific error cases for common ffmpeg failures.

---

## Phase-Specific Warnings

| Phase | Topic | Likely Pitfall | Mitigation |
|-------|-------|---------------|-----------|
| Phase 1 (Core) | ffmpeg availability | Pitfall 1: Not installed | Pre-flight check at launch; show installation instructions |
| Phase 1 (Core) | CBR bitrate | Pitfall 4: VBR confusion | Use `-b:a 320k`; add comment; unit test bitrate |
| Phase 2 (UI) | Output paths | Pitfall 7: Edge cases | Use Foundation URL APIs; test special chars |
| Phase 2 (UI) | Progress feedback | Pitfall 3: Appears hung | Show "Extracting..." immediately; update every 10s |
| Phase 2 (UI) | File collision | Pitfall 2: Overwrites silently | Check destination exists; show dialog before overwrite |
| Phase 2 (UI) | Error handling | Pitfall 6: Silent failures | Check exit code; capture stderr; log errors |
| Phase 2 (UI) | Permissions | Pitfall 9: Permission denied | Pre-flight validation; helpful error messages |
| Phase 3 (Home screen) | Tool state | Pitfall 5: State entanglement | Enforce independent state; code review; test isolation |

---

## Validation Checklist

Before shipping v1.1, verify:

- [ ] ffmpeg availability checked at app launch; helpful error shown if missing
- [ ] Use `-b:a 320k` (CBR) flag verified in code
- [ ] Unit test: AudioExtractor extracts MP3 with exactly 320k bitrate
- [ ] Output file collision detected; user prompted before overwrite
- [ ] "Extracting..." status shown immediately (within 100ms of clicking Extract)
- [ ] Progress status updated every 5-10 seconds
- [ ] Process timeout implemented (10 minutes max)
- [ ] Pre-flight checks: input readable, output writable, disk space available
- [ ] ffmpeg exit code checked; non-zero treated as error
- [ ] ffmpeg stderr captured and logged for debugging
- [ ] Partial output file deleted on extraction failure
- [ ] Error messages are user-friendly (not "exit code 127")
- [ ] File path derivation tested with edge cases (spaces, dots, special chars, hidden files)
- [ ] Manual test: Extract with various MP4 sources (GoPro, iPhone, etc.)
- [ ] Manual test: Extract to different directories (Desktop, Documents, external drive)
- [ ] Integration test: Home screen → stitch and audio flows both work
- [ ] Integration test: Back button returns home; state clears properly
- [ ] Code review: Tool state structs are independent; no sharing

---

## Sources & References

### Audio Extraction Best Practices
- [FFmpeg Known Issues and Limitations](https://ffmpeg.org/faq.html)
- [LAME MP3 Encoder Documentation](https://wiki.hydrogenaud.io/index.php?title=LAME)
- [FFmpeg Audio Encoding Guide](https://trac.ffmpeg.org/wiki/Encode/MP3)

### macOS File I/O Pitfalls
- Foundation documentation: URL, FileManager APIs
- macOS file permissions with external drives and network filesystems

### Domain Experience from v1.0
- ChunkStitcher.swift error handling patterns
- Integration test patterns and subprocess management
- User-facing error message lessons

---

**Summary:** Audio extraction introduces new failure modes (ffmpeg unavailable, bitrate confusion, output paths, progress feedback). All preventable with careful API usage and testing. Tool state isolation critical to prevent entanglement as app grows. Focus on reliable error handling and clear user feedback.

Last updated: 2026-03-18
