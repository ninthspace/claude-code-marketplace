# Markdown previews

**Number**: 02-04  
**Source spec**: 02  
**Status**: pending  

## A criterion added to story 2, and what it closes

Story 2 gained a sixth criterion during the run: *"A preview the raster produced reaches a terminal reporting 256 colours as 8-bit colour and no 24-bit codes, so no colour system named where the terminal cannot be seen decides whether a preview is legible."* It is tagged `unit`, covered by `tests/test_raster.py`, and bound to NFR3 and ENVX4.

**The citation is the two requirements' own text.** NFR3 names two things — "The cursor blends two colours and **the raster asks for a colour system by name**" — and ENVX4 names the same pair: "The cursor blends two colours and **the raster names a colour system**". Epic 3 delivered the cursor half of both and left them unclaimed for exactly this reason: half of each sentence was bound to nothing, because the raster did not exist yet. Story 2 built it, and none of story 2's five criteria as written reached the colour system — so the requirement would have been discharged in full by an epic that never checked the half it was written about.

The board's own answer is to name no colour system at all. The CPM board rasterises with `color_system="truecolor"`, which it can afford because Rich's segments carry `Style` objects rather than escape codes and Textual downgrades them at output; the argument decides nothing there and would decide everything if the raster ever wrote its own output. Leaving it off makes the code say what the requirement says.

Recorded here rather than pivoted because it amends this epic's rows only: one criterion, its approach, and two coverage rows. The source spec is untouched.

## Story 4's control, amended: no input takes the renderer down

Story 4's control criterion read: *"With the guard removed, the same input takes the board down — so the criterion above cannot pass against a renderer that was never at risk from it."* It cannot be satisfied as written, and the citation is the renderer's own behaviour.

Eighteen pathological sources were put through `markdown_content` before the guard existed — 20,000 nested blockquotes, 2,000 nested list levels, an unclosed code fence, a 100,000-character single line, 5,000 unbalanced brackets, an emphasis storm, a ragged table, a 200-column table at a 10-cell width, a fence naming a lexer that does not exist, one containing NUL bytes, ANSI escapes, an unpaired surrogate, an empty source, whitespace only, 3,000 ordered items, and 5,000 horizontal rules. Every one of them rendered. Rich and markdown-it are tolerant by design: malformed markdown is *text*, and text is what they fall back to.

So the input half of the control is unavailable, and the honest control drives the failure through the renderer instead: with the guard removed and a renderer that raises, the exception escapes into the board; with the guard, the panel paints the source unrendered and the board carries on. That demonstrates the guard is load-bearing, which is what the control is for — it just cannot also demonstrate that any particular input is dangerous.

The criterion's text was amended to say that. The guard was kept: the resize path runs the raster on the event loop with nothing catching for it, the markdown comes from whatever wrote the rows rather than from this board, and eighteen inputs that did not raise is not a proof about the nineteenth.

## Story 1 — Builders that emit markdown source

**Status**: complete  
**Blocked by**: Story 5  

### Acceptance Criteria

- `document_preview` returns the document's title as a markdown heading and each section's heading as a heading beneath it. `[unit]`
- `story_preview` returns the story's criteria and tasks as markdown lists, with a task's description subordinate to the task rather than beside it. `[unit]`
- must NOT — No plain-text scaffolding label survives in either builder's output — a bare `Acceptance criteria:` line renders as prose and is the shape this requirement exists to remove. `[unit]`

### Task 1 — Rewrite document_preview to emit markdown

**Status**: complete  

The document's title as a heading and each section's heading as a heading beneath it. Addresses the source the builder returns; how the panel renders it is story 2.

### Task 2 — Rewrite story_preview to emit markdown

**Status**: complete  

Criteria and tasks as markdown lists, with a task's description subordinate to its task rather than beside it. The plain-text scaffolding labels go here, not somewhere else.

### Task 3 — Write tests for Builders that emit markdown source

**Status**: complete  

Covers the three criteria tagged unit. The existing tests/test_previews.py pins the plain-text shapes these builders no longer produce, so its assertions move with them rather than being left to fail.

### Retro

- The rewrite was four lines of builder and the whole of the risk was in how it gets checked. Asserting a leading `#` would have been a second markdown parser written in the test file, so both must criteria are read from `rich.markdown.Markdown(source).parsed` — the markdown-it token stream story 2's panel will actually rasterise. That paid immediately on the nesting criterion: "subordinate to the task" is a claim about the content column the `- ` marker leaves, not about two spaces, and the token's `level` is the only thing that knows. The old shape (`  {description}`, no marker) is a lazy paragraph continuation and merges into the task's own inline token, which the level check catches as a missing key rather than as a passing test.

The must-NOT is stated as a property rather than as a search for the label that was there. `Acceptance criteria:` in nobody's output is satisfied by a builder that renames it to `Criteria:`; what the check asks is that every line the builder contributed *itself* — every line whose text, after its list marker, appears in none of the rows — is markdown structure. Its control is the old composition, and the failure names the label it found.

## Story 2 — Markdown rendered in the preview panel

**Status**: complete  
**Blocked by**: Story 3, Story 4, Story 5  

### Acceptance Criteria

- Source containing a heading, emphasis, a list and a table renders each as a styled construct rather than as its source characters. `[unit]`
- The same source rendered at two panel widths breaks its lines differently, so the render is using the panel's width rather than a default. `[unit]`
- Resizing the panel re-renders its contents at the new width. `[feature]`
- The panel's renderable is built from styled text rather than being a live markdown widget, which is what leaves the rendered preview selectable. `[unit]`
- must NOT — No markdown marker survives into the rendered output for a construct that was rendered — no `##` before a heading, no `- ` before a list item, no `**` around emphasis. `[unit]`
- A preview the raster produced reaches a terminal reporting 256 colours as 8-bit colour and no 24-bit codes, so no colour system named where the terminal cannot be seen decides whether a preview is legible. `[unit]`

### Task 1 — Port markdown_content and HardBreakMarkdown from the CPM board

**Status**: complete  

Rasterise markdown through a Console at a given width and rebuild the segments into styled text. The rebuild is the part that matters: it is what leaves the rendered preview selectable, which a live markdown widget does not.

### Task 2 — Feed the preview panel the rasterised renderable instead of a plain string

**Status**: complete  

Addresses the panel's content only. The builders that supply the source it rasterises are story 1.

### Task 3 — Re-render the preview at the panel's new width on resize

**Status**: complete  

Addresses the raster being width-specific: a resize invalidates it, and a panel left holding the old raster shows lines broken for a width it no longer has.

### Task 4 — Write tests for Markdown rendered in the preview panel

**Status**: complete  

Covers the five criteria — four tagged unit, and the resize one tagged feature, which drives the board rather than the render function.

### Retro

- The resize criterion nearly passed against a board that re-rendered nothing, and finding that out took a deliberate control. A Textual `Content` re-wraps itself to whatever panel it is in, so "the preview text changed after the resize" is true of a stale raster too — the paragraph reflows either way. What only re-rendering fixes is a construct laid out at the raster's width rather than wrapped to the panel's: a heading is *centred*, so a stale one arrives with the old width's padding still on it and spills onto a second line. That is what the criterion asserts now.

The same control found a real bug. Re-rendering from the app's own `on_resize` reads the panel's width before the columns beneath have been laid out again, so it rasterises at the width the panel had a moment ago — the exact stale layout it exists to replace, one step later. The source moved onto a `PreviewBody` widget that re-renders on *its own* `Resize`, which is delivered with its new size. The CPM board drives both panels from the app's event; it gets away with it because its panels are wider and its documents wrap at paragraph level, not because the shape is right.

One deliberate divergence from CPM, in the other direction: the raster names no colour system. CPM asks for `truecolor` and can afford to — Rich's segments carry `Style` objects and Textual downgrades at output — but NFR3 and ENVX4 both name the raster's colour system as a thing that must not decide legibility, and neither had a criterion reaching it. One was added, with a coverage row against each.

## Story 3 — The cursor stays ahead of the raster

**Status**: complete  
**Blocked by**: Story 5  

### Acceptance Criteria

- A render for a row the cursor has since left is discarded rather than painted, so moving quickly through a list leaves the panel showing the row the cursor is on. `[feature]`
- Rendering the largest document in the fixture at 80 columns completes within 50 ms. `[unit]`

### Task 1 — Discard a render whose row is no longer the highlighted one

**Status**: complete  

Addresses the stale paint — a panel showing a row the cursor has left — rather than the cost of the render itself, which is the next task.

### Task 2 — Keep the raster off the key-handling path

**Status**: complete  

Addresses a held arrow key queueing one render per row passed over, and key handling blocking while a render runs.

### Task 3 — Write tests for The cursor stays ahead of the raster

**Status**: complete  

Covers the feature criterion on fast cursor movement and the unit criterion holding the render of the fixture's largest document at 80 columns within 50 ms.

### Retro

- The staleness guard now has to be checked twice, and the second check is the one this story added. The read was already stamped and compared; the raster was not, and it is the wait that grows with the document — so a board that checked only before rendering would spend a whole render on a row the user had left and then paint it over the row they were on. The render also moved off the event loop with `asyncio.to_thread`, which is the codebase's existing idiom for the tmux poll: a markdown render is arithmetic rather than I/O, so awaiting it on the loop puts every queued keystroke behind it. The width is read on the loop and only the rendering goes to the thread.

**The timing criterion is weaker than it reads, and the fixture is why.** "Rendering the largest document in the fixture at 80 columns completes within 50 ms" names a document that is about 130 characters: it renders in well under a millisecond, and a budget met by it says nothing about a board previewing a real spec. The fixture is small deliberately — every test in the suite reads it — so the test times that document *and* the same source repeated forty times, which is the size of an actual epic doc and the one that could fail. Enlarging the shared fixture to make the criterion mean what it says would be a change to every other story's ground.

The cancellation route was considered and left alone: making the preview worker exclusive would stop a held key queueing reads, and it would cancel an in-flight call on a shared MCP pool to do it. The guard discards the stale result for free, and a cancelled JSON-RPC request is a different risk to take on for a queue that is already bounded by how fast a key repeats.

## Story 4 — A preview it cannot render does not take the board down

**Status**: complete  
**Blocked by**: Story 5  

### Acceptance Criteria

- A preview whose source is malformed, pathologically nested, or a single very long line renders something and leaves the board running. `[unit]`
- control — With the guard removed, a render that raises takes the board down — so the criterion above cannot pass against a panel that was never protecting itself. No markdown source has been found that makes the renderer raise, so the control drives the failure through the renderer rather than through the input. `[unit]`

### Task 1 — Guard the preview render so a source it cannot handle yields something renderable

**Status**: complete  

Covers malformed markdown, pathological nesting and a body that is one very long line. This guard is the thing the story's control criterion removes.

### Task 2 — Write tests for A preview it cannot render does not take the board down

**Status**: complete  

Covers both criteria tagged unit, including the control — which has to fail with the guard removed, so the rejection cannot pass against a renderer that was never at risk from the input.

### Retro

- The story assumed a renderer that could be broken by its input, and it cannot be. Eighteen pathological sources went through the raster before any guard existed — 20,000 nested blockquotes, 2,000 list levels, an unclosed fence, a 100,000-character line, unbalanced brackets, NUL bytes, ANSI escapes, an unpaired surrogate, a 200-column table at ten cells — and every one rendered. Rich and markdown-it treat malformed markdown as text, which is the correct answer and leaves the criterion's "renders something" asserting that the output is sane rather than that a crash was caught.

That made the control unsatisfiable as written ("the same input takes the board down"), so it was amended to say what a control can actually show here: the failure is driven through a renderer that raises, which demonstrates the guard is load-bearing and demonstrates nothing about any particular input. The evidence is on the epic as a section.

The guard was kept rather than dropped as unnecessary, for a reason the probe does not cover: the resize path runs the raster on the event loop with nothing catching for it, the markdown comes from whatever wrote the rows rather than from this board, and eighteen inputs that did not raise is not a proof about the nineteenth. Its fallback is the source itself, so a preview that cannot be rendered still has its text on screen.

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
