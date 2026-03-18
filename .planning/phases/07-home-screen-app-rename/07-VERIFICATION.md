---
phase: 07-home-screen-app-rename
verified: 2026-03-18T16:30:00Z
status: gaps_found
score: 5/6 must-haves verified
gaps:
  - truth: "App display name reads 'GoPro Toolkit' — no 'GoProStitcher' visible to the user"
    status: failed
    reason: "FolderPickerView still displays user-visible 'GoProStitcher' title string instead of 'GoPro Toolkit'"
    artifacts:
      - path: "GoProStitcher/Features/FolderPicker/FolderPickerView.swift"
        issue: "Line 12 shows Text('GoProStitcher') — should be Text('GoPro Toolkit')"
    missing:
      - "Update FolderPickerView line 12 from Text('GoProStitcher') to Text('GoPro Toolkit')"
---

# Phase 7: Home Screen & App Rename Verification Report

**Phase Goal:** App is named "GoPro Toolkit" throughout, presents a home screen with two tool buttons, and both tools are reachable and dismissible without breaking any existing functionality.

**Verified:** 2026-03-18T16:30:00Z
**Status:** gaps_found
**Re-verification:** No — initial verification

## Goal Achievement

### Observable Truths

| # | Truth | Status | Evidence |
|---|-------|--------|----------|
| 1 | App display name reads "GoPro Toolkit" — no "GoProStitcher" visible to the user | FAILED | FolderPickerView line 12 still shows `Text("GoProStitcher")` user-facing title; all other config correctly updated (project.yml, Info.plist, StitchProgressView updated) |
| 2 | App launches directly to a home screen with "Stitch Video" and "Extract Audio" buttons | VERIFIED | GoProStitcherApp initializes AppFeature.State() with activeTool=nil; ContentView switches on activeTool, showing HomeView when nil; HomeView renders two ToolDescriptor buttons with correct titles |
| 3 | Tapping "Stitch Video" enters the existing stitch flow (folder picker through stitching) | VERIFIED | HomeView dispatches .home(.stitchVideoTapped); AppFeature sets activeTool=.stitch; ContentView routes to FolderPickerView/ChunkReviewView/StitchProgressView sub-tree; all existing logic preserved |
| 4 | Tapping "Extract Audio" enters the existing audio flow (file picker through extraction) | VERIFIED | HomeView dispatches .home(.extractAudioTapped); AppFeature sets activeTool=.audio; ContentView routes to AudioFilePickerView/AudioExtractionView sub-tree; all existing logic preserved |
| 5 | Both tool screens have a back/close action that returns to the home screen | VERIFIED | Stitch: ContentView shows "< Back" button on FolderPickerView sending .backToHome; Audio: AudioFilePickerFeature sends .userCancelledPicker which AppFeature handles by setting activeTool=nil; both routes return to HomeView |
| 6 | All v1.0 user actions inside each tool work identically to before | VERIFIED | FolderPickerView, ChunkReviewView, StitchProgressView, AudioFilePickerView, AudioExtractionView all unchanged except for rename (Truth 1); stitch flow (detect→review→reorder→stitch→archive) unchanged; audio flow (pick→extract→reveal) unchanged |

**Score:** 5/6 truths verified

### Required Artifacts

| Artifact | Expected | Status | Details |
|----------|----------|--------|---------|
| `GoProStitcher/Features/Home/HomeFeature.swift` | HomeFeature reducer with stitchVideoTapped / extractAudioTapped actions | ✓ VERIFIED | 18 lines, correct structure, exported, used by AppFeature Scope |
| `GoProStitcher/Features/Home/HomeView.swift` | Two-button home screen built from extensible ToolDescriptor array | ✓ VERIFIED | 68 lines, defines ToolDescriptor struct, renders two buttons (Stitch Video, Extract Audio), takes StoreOf<AppFeature> |
| `GoProStitcher/AppFeature.swift` | enum ActiveTool routing replacing showAudioPicker flag | ✓ VERIFIED | 119 lines, defines ActiveTool enum, has activeTool: ActiveTool? = nil state, handles home actions, backToHome action |
| `GoProStitcher/ContentView.swift` | Switch on activeTool driving HomeView / stitch / audio sub-trees | ✓ VERIFIED | 48 lines, switches on store.activeTool with three cases (.none→HomeView, .stitch→FolderPicker/ChunkReview/StitchProgress, .audio→AudioFilePicker/AudioExtraction) |
| `project.yml` | CFBundleDisplayName: "GoPro Toolkit" | ✓ VERIFIED | Line 25 shows `CFBundleDisplayName: GoPro Toolkit` |
| `GoProStitcher/Info.plist` | CFBundleDisplayName: "GoPro Toolkit" | ✓ VERIFIED | Line 8 shows `<string>GoPro Toolkit</string>` |

### Key Link Verification

| From | To | Via | Status | Details |
|------|----|----|--------|---------|
| HomeView → AppFeature actions | store.send(tool.action) | .home(.stitchVideoTapped) / .home(.extractAudioTapped) | ✓ WIRED | HomeView line 39 sends actions; AppFeature lines 52-58 handle both cases |
| AppFeature activeTool routing | ContentView switch | state.activeTool = .stitch / .audio / nil | ✓ WIRED | AppFeature sets activeTool in Reduce (lines 53, 57, 64); ContentView switches on it (line 9) |
| ContentView → sub-views | HomeView / stitch tree / audio tree | switch store.activeTool with three cases | ✓ WIRED | ContentView implements full switch statement (lines 9-45) routing to correct sub-trees |
| Back-to-home navigation | activeTool = nil | .backToHome action / .userCancelledPicker | ✓ WIRED | FolderPickerView Back button sends .backToHome (ContentView line 24); AudioFilePickerFeature sends .userCancelledPicker (line 38-39 in AudioFilePickerFeature); both reset activeTool to nil (AppFeature lines 64, 99) |
| Display name propagation | Window title / dock icon | CFBundleDisplayName in config | ✓ WIRED | project.yml and Info.plist both set to "GoPro Toolkit"; GoProStitcherApp uses default scene which reads this config |

### Build Status

✓ **BUILD SUCCEEDED** — xcodebuild reports successful compilation with no errors

### Anti-Patterns Found

| File | Line | Pattern | Severity | Impact |
|------|------|---------|----------|--------|
| FolderPickerView.swift | 12 | User-visible "GoProStitcher" string | 🛑 BLOCKER | User sees old app name in folder picker screen, violating core requirement RENAME-01 |

### Requirements Coverage

| Requirement | Status | Evidence |
|-------------|--------|----------|
| RENAME-01: App renamed to "GoPro Toolkit" | BLOCKED | FolderPickerView line 12 still shows "GoProStitcher" to user; other config files correct |
| HOME-01: Home screen with two tool buttons | SATISFIED | HomeView renders "Stitch Video" and "Extract Audio" buttons from ToolDescriptor array |
| HOME-02: Home screen layout is extensible | SATISFIED | ToolDescriptor array pattern allows adding third button with single entry (lines 14-27 in HomeView) |
| HOME-03: "Stitch Video" button launches existing stitch flow unchanged | SATISFIED | AppFeature routes to stitch sub-tree; all v1.0 logic preserved |
| HOME-04: User can navigate back to home screen from any tool | SATISFIED | FolderPickerView has Back button; AudioFilePickerFeature cancel returns home; both reset activeTool to nil |

## Gaps Summary

### Gap 1: FolderPickerView displays "GoProStitcher" instead of "GoPro Toolkit"

**Location:** `GoProStitcher/Features/FolderPicker/FolderPickerView.swift` line 12

**Issue:** The app display name was updated in project.yml and Info.plist, and StitchProgressView was updated, but FolderPickerView's title text was missed. When the user taps "Stitch Video", they are presented with a screen that says "GoProStitcher" instead of "GoPro Toolkit".

**What's wrong:** 
- Current: `Text("GoProStitcher")`
- Expected: `Text("GoPro Toolkit")`

**Impact:** This is a blocker for requirement RENAME-01 ("App renamed to 'GoPro Toolkit'") and breaks truth #1 ("App display name reads 'GoPro Toolkit' — no 'GoProStitcher' visible to the user").

**Why not caught:** The plan's task 1 action stated "Scan for any hardcoded 'GoProStitcher' strings visible to the user... Update those strings to 'GoPro Toolkit'" but the scan was incomplete — it updated StitchProgressView but missed FolderPickerView.

**Fix needed:** Change line 12 in FolderPickerView.swift from `Text("GoProStitcher")` to `Text("GoPro Toolkit")`.

---

## Summary

The phase implementation is nearly complete:

**What works correctly:**
- App launches to home screen with two tool buttons ✓
- Both tools are reachable from home ✓
- Both tools can return to home screen ✓
- Enum-based routing (ActiveTool) correctly implemented ✓
- ContentView correctly switches between home and tool flows ✓
- All v1.0 functionality preserved and working ✓
- Build succeeds ✓

**What's broken:**
- User-visible app name not fully updated (FolderPickerView still shows "GoProStitcher")

**To complete phase 7:**
1. Update FolderPickerView line 12 to show "GoPro Toolkit"
2. Verify full build succeeds
3. Run human verification checkpoint (launch app, verify all screens show "GoPro Toolkit", test navigation)

---

_Verified: 2026-03-18T16:30:00Z_
_Verifier: Claude (gsd-verifier)_
