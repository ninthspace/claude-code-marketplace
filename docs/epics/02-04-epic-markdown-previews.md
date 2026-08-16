# Markdown previews

**Number**: 02-04  
**Source spec**: 02  
**Status**: pending  

## Story 1 — Builders that emit markdown source

**Status**: pending  
**Blocked by**: Story 5  

### Acceptance Criteria

- `document_preview` returns the document's title as a markdown heading and each section's heading as a heading beneath it. `[unit]`
- `story_preview` returns the story's criteria and tasks as markdown lists, with a task's description subordinate to the task rather than beside it. `[unit]`
- must NOT — No plain-text scaffolding label survives in either builder's output — a bare `Acceptance criteria:` line renders as prose and is the shape this requirement exists to remove. `[unit]`

### Task 1 — Rewrite document_preview to emit markdown

**Status**: pending  

The document's title as a heading and each section's heading as a heading beneath it. Addresses the source the builder returns; how the panel renders it is story 2.

### Task 2 — Rewrite story_preview to emit markdown

**Status**: pending  

Criteria and tasks as markdown lists, with a task's description subordinate to its task rather than beside it. The plain-text scaffolding labels go here, not somewhere else.

### Task 3 — Write tests for Builders that emit markdown source

**Status**: pending  

Covers the three criteria tagged unit. The existing tests/test_previews.py pins the plain-text shapes these builders no longer produce, so its assertions move with them rather than being left to fail.

## Story 2 — Markdown rendered in the preview panel

**Status**: pending  
**Blocked by**: Story 3, Story 4, Story 5  

### Acceptance Criteria

- Source containing a heading, emphasis, a list and a table renders each as a styled construct rather than as its source characters. `[unit]`
- The same source rendered at two panel widths breaks its lines differently, so the render is using the panel's width rather than a default. `[unit]`
- Resizing the panel re-renders its contents at the new width. `[feature]`
- The panel's renderable is built from styled text rather than being a live markdown widget, which is what leaves the rendered preview selectable. `[unit]`
- must NOT — No markdown marker survives into the rendered output for a construct that was rendered — no `##` before a heading, no `- ` before a list item, no `**` around emphasis. `[unit]`

### Task 1 — Port markdown_content and HardBreakMarkdown from the CPM board

**Status**: pending  

Rasterise markdown through a Console at a given width and rebuild the segments into styled text. The rebuild is the part that matters: it is what leaves the rendered preview selectable, which a live markdown widget does not.

### Task 2 — Feed the preview panel the rasterised renderable instead of a plain string

**Status**: pending  

Addresses the panel's content only. The builders that supply the source it rasterises are story 1.

### Task 3 — Re-render the preview at the panel's new width on resize

**Status**: pending  

Addresses the raster being width-specific: a resize invalidates it, and a panel left holding the old raster shows lines broken for a width it no longer has.

### Task 4 — Write tests for Markdown rendered in the preview panel

**Status**: pending  

Covers the five criteria — four tagged unit, and the resize one tagged feature, which drives the board rather than the render function.

## Story 3 — The cursor stays ahead of the raster

**Status**: pending  
**Blocked by**: Story 5  

### Acceptance Criteria

- A render for a row the cursor has since left is discarded rather than painted, so moving quickly through a list leaves the panel showing the row the cursor is on. `[feature]`
- Rendering the largest document in the fixture at 80 columns completes within 50 ms. `[unit]`

### Task 1 — Discard a render whose row is no longer the highlighted one

**Status**: pending  

Addresses the stale paint — a panel showing a row the cursor has left — rather than the cost of the render itself, which is the next task.

### Task 2 — Keep the raster off the key-handling path

**Status**: pending  

Addresses a held arrow key queueing one render per row passed over, and key handling blocking while a render runs.

### Task 3 — Write tests for The cursor stays ahead of the raster

**Status**: pending  

Covers the feature criterion on fast cursor movement and the unit criterion holding the render of the fixture's largest document at 80 columns within 50 ms.

## Story 4 — A preview it cannot render does not take the board down

**Status**: pending  
**Blocked by**: Story 5  

### Acceptance Criteria

- A preview whose source is malformed, pathologically nested, or a single very long line renders something and leaves the board running. `[unit]`
- control — With the guard removed, the same input takes the board down — so the criterion above cannot pass against a renderer that was never at risk from it. `[unit]`

### Task 1 — Guard the preview render so a source it cannot handle yields something renderable

**Status**: pending  

Covers malformed markdown, pathological nesting and a body that is one very long line. This guard is the thing the story's control criterion removes.

### Task 2 — Write tests for A preview it cannot render does not take the board down

**Status**: pending  

Covers both criteria tagged unit, including the control — which has to fail with the guard removed, so the rejection cannot pass against a renderer that was never at risk from the input.

## Story 5 — Sweep the presentation surfaces

**Status**: pending  
**Blocked by**: —  

### Acceptance Criteria

- Column layout, row composition, CSS and preview behaviour each have a recorded outcome: a difference closed, a difference recorded as deliberate, or a statement that the surface agrees. `[manual]`
- must NOT — None of column layout, row composition, CSS or preview behaviour is left with no outcome recorded. A surface nobody compared reads exactly like one that was compared and agreed. `[manual]`

### Task 1 — Compare column layout and row composition across the two boards

**Status**: pending  

Each surface gets a recorded outcome: a difference closed, a difference recorded as deliberate, or a statement that the surface agrees. Reads the repository source of both boards, never the plugin cache.

### Task 2 — Compare CSS and preview behaviour across the two boards

**Status**: pending  

The same three outcomes, over the two surfaces this epic has just moved. A difference introduced by stories 1 to 4 and left unrecorded is the case this task exists to catch.
