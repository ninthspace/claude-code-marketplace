# The rendered row

**Number**: 02-03  
**Source spec**: 02  
**Status**: pending  

## Story 1 — The cursor in the row's own colour

**Status**: pending  
**Blocked by**: Story 3  

### Acceptance Criteria

- The strip rendered for the highlighted row carries that row's own colour blended toward the background — a red row and a green row highlight differently, and neither highlights in a fixed accent colour. `[unit]`
- must NOT — Textual's own highlight style appears on no rendered row, whether or not the list has focus. `[unit]`
- control — With the CSS override removed, the criterion above fails — so a board rendering no highlight at all could not satisfy it by having nothing to find. `[unit]`
- Moving the cursor onto a row on a running board paints that row's strip in its own colour. `[feature]`

### Task 1 — Port InverseOptionList from the CPM board

**Status**: pending  

The render_line override that repaints the highlighted strip in the row's own colour, blended toward the background. Addresses the cursor's appearance only — the row's content composition belongs to story 2.

### Task 2 — Neutralise Textual's highlight style in the board's CSS

**Status**: pending  

Addresses the default highlight block showing through the repainted strip, which the render_line override alone does not stop. It is the thing the story's control criterion removes.

### Task 3 — Write tests for The cursor in the row's own colour

**Status**: pending  

Covers the four criteria: the three tagged unit, including the control — which has to fail with the CSS override removed, so that a board rendering no highlight at all cannot satisfy the rejection by having nothing to find — and the one tagged feature, which drives a running board rather than the render function.

## Story 2 — The pill against the right edge

**Status**: pending  
**Blocked by**: Story 3  

### Acceptance Criteria

- A projects row rendered at column width 24 and again at 48 puts the pill's last character in the row's last column both times. `[unit]`
- The pill and the badge each render in their own colour rather than the row's status colour, on a row whose status colour differs from both. `[unit]`
- must NOT — Neither pill nor badge is truncated on a row too narrow to hold everything: the project name is what gives. `[unit]`

### Task 1 — Compose the projects row as a grid with a right-justified pill cell

**Status**: pending  

Replaces the string suffix the DPM board appends today. Addresses placement only; the colours the pill and badge carry are the next task.

### Task 2 — Give the pill and the integrity badge their own styles over the row's status colour

**Status**: pending  

Addresses colour independence from the row. The badge is a DPM capability with no CPM counterpart to copy, so its style is decided here rather than ported.

### Task 3 — Make the row composition follow the projects column's width

**Status**: pending  

Addresses width-independence at any column width, not only the two the criterion names, and the re-render when that width changes.

### Task 4 — Write tests for The pill against the right edge

**Status**: pending  

Covers the three criteria tagged unit — placement at two column widths, the colours over a differing row colour, and the rejection that what gives on a narrow row is the project name.

## Story 3 — Legible without truecolor

**Status**: pending  
**Blocked by**: —  

### Acceptance Criteria

- With the console limited to 256 colours, the highlighted row is still distinguishable from an unhighlighted one, and the pill from the row's own colour. `[unit]`
- The board renders against a console reporting 256 colours without error, and the render is not silently a monochrome one. `[unit]`

### Task 1 — Choose blend and pill colours that survive a 256-colour downgrade

**Status**: pending  

Addresses the palette values rather than the render path, which stories 1 and 2 deliver. What is at stake is that the blend and the pill remain distinguishable once the terminal has quantised them.

### Task 2 — Write tests for Legible without truecolor

**Status**: pending  

Covers the two criteria tagged unit, driving the render against a console that reports 256 colours rather than truecolor.
