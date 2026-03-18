# Phase 8: UX Redesign — 8-Bit Design System - Context

**Gathered:** 2026-03-18
**Status:** Ready for planning

<domain>
## Phase Boundary

Apply the GoProToolkit-8bit-system design language across all existing screens. Create a design tokens file, restyle every view, and validate progressively with screenshots. Test-first: build a test suite verifying design system integration before restyling screens.

</domain>

<decisions>
## Implementation Decisions

### Test-First Approach
- Build test suite FIRST — verify design tokens, color application, font registration, spacing compliance
- Tests should confirm the design system is properly integrated across all screens
- UI snapshot tests or structural tests to catch regressions during restyling

### Progress Screens (Stitch + Audio Extraction)
- Block-fill progress bar: segmented blocks filling left-to-right (████░░░░) — custom SwiftUI view, not system ProgressView
- Card-with-status layout: white card on beige background, block progress bar inside the card, 2px black border
- Completion state: pixel-art checkmark icon + "DONE" in bold monospace
- Error state: red accent (#D72638) — same recording red, not separate error color
- All text monospace, metadata in secondary color (#3A3A3A)

### File Picker / Metadata Screens
- Metadata cards: inverted header bar (black background, beige text) + white body with black border
- Chunk review list: full 8-bit restyle — monospace text, black bordered rows, 4pt grid spacing
- Picker buttons: centered narrower black button with icon, not full-width
- NSOpenPanel: leave as system default — don't fight the native dialog
- All spacing on 4pt grid

### Font
- JetBrains Mono throughout — bundled in the app (not system fallback)
- Bold (700) for headers/titles
- Regular (400) for body/metadata
- No italic anywhere

### Home Screen (Claude's ideation freedom)
- Claude has creative freedom to redesign the home screen tool buttons in 8-bit style
- Should feel like a retro game menu — clear, bold, iconic
- Must remain extensible (ToolDescriptor array pattern preserved)

### Claude's Discretion
- Exact pixel art for checkmark and other status icons
- Loading skeleton / shimmer design (if any — may not fit retro aesthetic)
- Exact shade variations within the 6-color palette constraint
- Whether to add subtle 1px inset/outset effects on cards for depth
- How thumbnails in chunk review list adapt to the retro treatment
- Any additional UI polish that fits the 8-bit system (e.g., retro animations, scan lines)

</decisions>

<specifics>
## Specific Ideas

- Design system spec provided in full (GoProToolkit-8bit-system) — colors, typography, spacing, component tokens all defined
- Palette: #F2E9DA (beige bg), #E4D8C4 (secondary bg), #FFFFFF (cards), #000000 (borders/text), #D72638 (accent red), #3A3A3A (muted)
- No gradients, shadows, blur — hard edges only
- All borders visible (1-2px)
- Grid = 4pt system, all spacing multiples of 4
- Icons: pixel-perfect, no anti-aliasing (.imageInterpolation(.none))
- Motion: linear easing only, 100-150ms, no scale transforms >1.05
- SwiftUI: .drawingGroup(opaque: false, colorMode: .linear) for pixel alignment

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 08-ux-redesign-8bit*
*Context gathered: 2026-03-18*
