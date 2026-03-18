---
status: testing
phase: 04-stitching-archive
source: 02-03-SUMMARY.md, 03-03-SUMMARY.md, 04-03-SUMMARY.md
started: 2026-03-18T13:30:00Z
updated: 2026-03-18T13:30:00Z
---

## Current Test

number: 1
name: Folder Picker Opens
expected: |
  Click "Select Folder" button. A native macOS file picker dialog appears.
awaiting: user response

## Tests

### 1. Folder Picker Opens
expected: Click "Select Folder" button. A native macOS file picker dialog appears.
result: [pending]

### 2. Scan Results Display
expected: After selecting a folder with GoPro MP4s, app shows count of detected clips and total combined file size.
result: [pending]

### 3. Review Screen Transition
expected: After scanning, app automatically transitions from folder picker to review screen showing a scrollable list of clips with filenames, metadata (duration, size, resolution), and thumbnails.
result: [pending]

### 4. Drag to Reorder
expected: Drag a clip in the list to a different position. The reorder happens immediately.
result: [pending]

### 5. Preview Modal
expected: Click a clip in the list. A preview modal opens showing the first few seconds of that clip. Can be dismissed with Close button or Escape.
result: [pending]

### 6. Start Stitching Button
expected: "Start Stitching" button is visible in the review screen header. Clicking it transitions to a full-screen progress view (review screen disappears).
result: [pending]

### 7. Progress Bar and Phase Labels
expected: Progress screen shows a linear progress bar and a text label. Label shows "Saving manifest..." initially, then "Stitching N/M: filename.MP4" during concat.
result: [pending]

### 8. Stitch Completion
expected: When stitching finishes, progress view shows "Done! Your video is ready." with a green checkmark icon.
result: [pending]

### 9. Output File Correct
expected: The stitched output file exists at the original first chunk's path. It plays as one continuous video containing all segments. Source chunks are deleted. stitch_manifest.json exists alongside the output.
result: [pending]

## Summary

total: 9
passed: 0
issues: 0
pending: 9
skipped: 0

## Gaps

[none yet]
