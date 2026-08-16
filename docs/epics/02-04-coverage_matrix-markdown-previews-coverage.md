# Coverage — Markdown previews

**Number**: 02-04  
**Source epic**: 02-04  
**Status**: pending  

## Coverage

| # | Requirement | Spec Text | Story Criterion | Covered by | Test Approach | Verified |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | FR6 | headings, emphasis, lists and tables draw as the CPM board draws them | Source containing a heading, emphasis, a list and a table renders each as a styled construct rather than as its source characters. | Story 2 | `[unit]` | ✓ |
| 2 | FR6 | at the panel's own width | The same source rendered at two panel widths breaks its lines differently, so the render is using the panel's width rather than a default. | Story 2 | `[unit]` | ✓ |
| 3 | FR6 | re-rendered when the panel is resized | Resizing the panel re-renders its contents at the new width. | Story 2 | `[feature]` | ✓ |
| 4 | FR6 | with the rendered text still selectable | The panel's renderable is built from styled text rather than being a live markdown widget, which is what leaves the rendered preview selectable. | Story 2 | `[unit]` | ✓ |
| 5 | FR6 | render markdown rather than showing its source | must NOT — No markdown marker survives into the rendered output for a construct that was rendered — no `##` before a heading, no `- ` before a list item, no `**` around emphasis. | Story 2 | `[unit]` | ✓ |
| 6 | FR6a | the document's title, each section's heading | `document_preview` returns the document's title as a markdown heading and each section's heading as a heading beneath it. | Story 1 | `[unit]` | ✓ |
| 7 | FR6a | a story's criteria and tasks | `story_preview` returns the story's criteria and tasks as markdown lists, with a task's description subordinate to the task rather than beside it. | Story 1 | `[unit]` | ✓ |
| 8 | FR6a | The preview builders emit markdown source rather than plain text | must NOT — No plain-text scaffolding label survives in either builder's output — a bare `Acceptance criteria:` line renders as prose and is the shape this requirement exists to remove. | Story 1 | `[unit]` | ✓ |
| 9 | FR8 | every further difference found is either closed or recorded as deliberate | Column layout, row composition, CSS and preview behaviour each have a recorded outcome: a difference closed, a difference recorded as deliberate, or a statement that the surface agrees. | Story 5 | `[manual]` |  |
| 10 | FR8 | A difference nobody has looked at is neither. | must NOT — None of column layout, row composition, CSS or preview behaviour is left with no outcome recorded. A surface nobody compared reads exactly like one that was compared and agreed. | Story 5 | `[manual]` |  |
| 11 | NFR1 | a held arrow key does not queue one render per row passed over | A render for a row the cursor has since left is discarded rather than painted, so moving quickly through a list leaves the panel showing the row the cursor is on. | Story 3 | `[feature]` | ✓ |
| 12 | NFR1 | Moving the cursor through a list stays responsive. | Rendering the largest document in the fixture at 80 columns completes within 50 ms. | Story 3 | `[unit]` | ✓ |
| 13 | NFR2 | renders as something and does not take the board down | A preview whose source is malformed, pathologically nested, or a single very long line renders something and leaves the board running. | Story 4 | `[unit]` |  |
| 14 | NFR2 | renders as something and does not take the board down | control — With the guard removed, the same input takes the board down — so the criterion above cannot pass against a renderer that was never at risk from it. | Story 4 | `[unit]` |  |
| 15 | NFR3 | the raster asks for a colour system by name | A preview the raster produced reaches a terminal reporting 256 colours as 8-bit colour and no 24-bit codes, so no colour system named where the terminal cannot be seen decides whether a preview is legible. | Story 2 | `[unit]` | ✓ |
| 16 | ENVX4 | the raster names a colour system | A preview the raster produced reaches a terminal reporting 256 colours as 8-bit colour and no 24-bit codes, so no colour system named where the terminal cannot be seen decides whether a preview is legible. | Story 2 | `[unit]` | ✓ |
