# The rendered row

**Number**: 02-03  
**Source spec**: 02  
**Status**: complete  

## What this epic left unclaimed, and why

Three of the four requirements this epic delivers against are left without a coverage claim. Every coverage row under them is verified; what is missing in each case is an obligation in the requirement's own sentence that no bound fragment reaches, and a claim is a judgement rather than a sum of rows.

**FR4 — "as the CPM board's `InverseOptionList` paints it".** The three bound fragments cover the muted bar, the row's own colour and the rejection of Textual's block, and all four rows are verified. Nothing compares the two renderers, and this epic deliberately made them differ: `SURFACE_LIFT` mixes the bar into a background lifted 8% toward the row default, which the CPM board does not do. That divergence is NFR3's — without it a dark green row's cursor quantises to pure black on a 256-colour terminal — and it is the right call, but it means "as that board paints it" is now true of the design and not of the arithmetic. Someone who wants the clause discharged should decide whether the CPM board should take the same lift.

**NFR3 and ENVX4 — the raster half.** Both sentences name two things: the cursor, which blends two colours, and the markdown raster, which asks for a colour system by name. This epic delivered the cursor half and tested it against a console reporting 256 colours. The raster does not exist yet — it is epic 4, story 2 — so half of each requirement is bound to nothing. They are the natural claims to make at the end of epic 4 rather than here.

FR5 is claimed. Its clauses — the right edge at any column width, and each marker keeping its own colour over the row's — are each bound to a verified criterion, and the width clause is exercised at both the column's minimum and its maximum as well as across a resize.

## Story 1 — The cursor in the row's own colour

**Status**: complete  
**Blocked by**: Story 3  

### Acceptance Criteria

- The strip rendered for the highlighted row carries that row's own colour blended toward the background — a red row and a green row highlight differently, and neither highlights in a fixed accent colour. `[unit]`
- must NOT — Textual's own highlight style appears on no rendered row, whether or not the list has focus. `[unit]`
- control — With the CSS override removed, the criterion above fails — so a board rendering no highlight at all could not satisfy it by having nothing to find. `[unit]`
- Moving the cursor onto a row on a running board paints that row's strip in its own colour. `[feature]`

### Task 1 — Port InverseOptionList from the CPM board

**Status**: complete  

The render_line override that repaints the highlighted strip in the row's own colour, blended toward the background. Addresses the cursor's appearance only — the row's content composition belongs to story 2.

### Task 2 — Neutralise Textual's highlight style in the board's CSS

**Status**: complete  

Addresses the default highlight block showing through the repainted strip, which the render_line override alone does not stop. It is the thing the story's control criterion removes.

### Task 3 — Write tests for The cursor in the row's own colour

**Status**: complete  

Covers the four criteria: the three tagged unit, including the control — which has to fail with the CSS override removed, so that a board rendering no highlight at all cannot satisfy the rejection by having nothing to find — and the one tagged feature, which drives a running board rather than the render function.

### Retro

- The CSS override and the render_line repaint look like two ways of doing the same thing, and they are not: the repaint reads the background it blends toward off the strip Textual handed it, so a block cursor left in the stylesheet is not a second highlight underneath the board's — it is the colour the board's own highlight gets mixed with. Removing the override paints the blocked row #6c467b (red mixed with Textual's #0178D4) instead of #760a0a (red mixed with the board's own #121212). That is what made a real control possible: the naive rejection — "the block cursor colour appears on no rendered row" — passes with the override removed, because the repaint overwrites the background either way. The rejection that has purchase asserts the painted bar is the row's colour blended toward the surface the *unhighlighted* rows share, and the control fails it by 137 in the blue channel.

## Story 2 — The pill against the right edge

**Status**: complete  
**Blocked by**: Story 3  

### Acceptance Criteria

- A projects row rendered at column width 24 and again at 48 puts the pill's last character in the row's last column both times. `[unit]`
- The pill and the badge each render in their own colour rather than the row's status colour, on a row whose status colour differs from both. `[unit]`
- must NOT — Neither pill nor badge is truncated on a row too narrow to hold everything: the project name is what gives. `[unit]`

### Task 1 — Compose the projects row as a grid with a right-justified pill cell

**Status**: complete  

Replaces the string suffix the DPM board appends today. Addresses placement only; the colours the pill and badge carry are the next task.

### Task 2 — Give the pill and the integrity badge their own styles over the row's status colour

**Status**: complete  

Addresses colour independence from the row. The badge is a DPM capability with no CPM counterpart to copy, so its style is decided here rather than ported.

### Task 3 — Make the row composition follow the projects column's width

**Status**: complete  

Addresses width-independence at any column width, not only the two the criterion names, and the re-render when that width changes.

### Task 4 — Write tests for The pill against the right edge

**Status**: complete  

Covers the three criteria tagged unit — placement at two column widths, the colours over a differing row colour, and the rejection that what gives on a narrow row is the project name.

### Retro

- A right-justified cell keeps a marker at the edge only while some other cell can give. The badge and the pill with their two-space gaps are 25 cells; the Projects column's own minimum is 24 — so a row carrying both at that width has already surrendered the whole of its name, and what Rich takes next is the end of the last column, which is the pill. min_width on the marker columns does not save it: it changes the truncation from an ellipsis to a silently dropped session count, which is worse. The floor is recorded in board_view.markers and the rejection is tested at the widths where a layout is actually possible (24 with one marker, 30 and 48 with both), because a criterion asserted at a width where nothing can satisfy it is a criterion that gets edited later rather than met.

Two smaller things fell out of the same task. The string form of a row and the painted form had drifted apart the moment the markers moved into cells — different order, and nearly different spacing — so both are now built from one markers() call; a per-marker suffix is a rule each marker gets right alone and wrong together. And the highlighted row loses the pill's blue, because the cursor bar paints one style across the strip: that is the CPM board's behaviour too, and it is why the colour criterion is read from a row the cursor is not on.

## Story 3 — Legible without truecolor

**Status**: complete  
**Blocked by**: —  

### Acceptance Criteria

- With the console limited to 256 colours, the highlighted row is still distinguishable from an unhighlighted one, and the pill from the row's own colour. `[unit]`
- The board renders against a console reporting 256 colours without error, and the render is not silently a monochrome one. `[unit]`

### Task 1 — Choose blend and pill colours that survive a 256-colour downgrade

**Status**: complete  

Addresses the palette values rather than the render path, which stories 1 and 2 deliver. What is at stake is that the blend and the pill remain distinguishable once the terminal has quantised them.

### Task 2 — Write tests for Legible without truecolor

**Status**: complete  

Covers the two criteria tagged unit, driving the render against a console that reports 256 colours rather than truecolor.

### Retro

- The failure this story is about was already on the board and invisible from here: a blurred cursor on a dark green (complete) row is #0e2a0e, a legible tint in 24-bit colour, and palette entry 16 — pure black — once a 256-colour terminal quantises it, against a surface at entry 233. Every other state was clear; nothing in the code said which of the seven would collapse, which is the argument for building the fixture from status_model.EPIC_STATES rather than from a sample.

The fix is one constant and it is in the right place: the bar is mixed into a background lifted 8% toward the row default rather than into the raw surface, so a near-black row colour still lands on a colour. Raising the blurred weight would have fixed the same case by making every blurred column louder, which is the distinction between focused and blurred that story 1 spent the weights on.

Two measurement lessons. Luminance is the wrong metric for "distinguishable" on this board — Rec. 709 weights red at a fifth, so a blocked row's bar (#5f0000 quantised) is 2 from the surface by luminance and 77 in the channel a reader actually sees; the check compares widest single channel instead. And the quantisation is Rich's own downgrade rather than a nearest-colour rule written in the test, because a second colour model would agree with the terminal until the day it did not.

## Retro Applied

- 02 · A criterion can read as the natural test of a rule and have no purchase on it · deferred — Criteria gap. Deferred unreviewed in autonomous mode: re-judging whether a criterion has purchase on its rule is a re-planning call.
- 02 · A criterion warranted by an ADR carries no coverage rows and is invisible to the roll-up · deferred — Criteria gap. Deferred unreviewed in autonomous mode: every criterion in epic 3 carries a coverage row, so nothing here is invisible to the roll-up; changing how ADR-warranted criteria are traced is a human's call.
- 02 · A must-NOT control needs one arm per code path that could reach the rejected behaviour · deferred — Testing gap. Deferred unreviewed in autonomous mode: widening a control to one arm per path changes what the criteria ask for, which is a human's call.
- 01 · A must-NOT stated as an equality is a change detector wearing a rejection's clothes · applied — Pattern worth reusing, applied autonomously. Story 1's must-NOT is about Textual's own highlight style appearing on no row; it is written as a rejection over what was rendered rather than an equality against a fixed expected strip.
- 01 · Check a control mutation compiles into the path it is aimed at before believing the red · deferred — Testing gap. Deferred unreviewed in autonomous mode: it implies a re-planning call about how controls are written across the epic, which belongs to a human. The control this story already carries is run and read regardless.
- 01 · Read the tree before building; expect the ratio to favour already-there · applied — Codebase discovery, applied autonomously. Epic 3 ports a renderer the CPM board already has, so the first move on every task is reading cpm/tools/board/board.py rather than designing one here.
- 01 · Stubbed tests and a real one are not the same test at different fidelities · applied — Pattern worth reusing, applied autonomously. The story's feature criterion drives a running board through the pilot and reads painted strips; nothing here asserts against a widget's self-report.
