# Coverage — The rendered row

**Number**: 02-03  
**Source epic**: 02-03  
**Status**: pending  

## Coverage

| # | Requirement | Spec Text | Story Criterion | Covered by | Test Approach | Verified |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | FR4 | renders as a muted bar in the row's own colour, blended partway toward the background | The strip rendered for the highlighted row carries that row's own colour blended toward the background — a red row and a green row highlight differently, and neither highlights in a fixed accent colour. | Story 1 | `[unit]` | ✓ |
| 2 | FR4 | Textual's default highlight block does not show through it. | must NOT — Textual's own highlight style appears on no rendered row, whether or not the list has focus. | Story 1 | `[unit]` | ✓ |
| 3 | FR4 | Textual's default highlight block does not show through it. | control — With the CSS override removed, the criterion above fails — so a board rendering no highlight at all could not satisfy it by having nothing to find. | Story 1 | `[unit]` | ✓ |
| 4 | FR4 | The highlighted row renders as a muted bar in the row's own colour | Moving the cursor onto a row on a running board paints that row's strip in its own colour. | Story 1 | `[feature]` | ✓ |
| 5 | FR5 | sit against the right edge of the projects column whatever width that column has | A projects row rendered at column width 24 and again at 48 puts the pill's last character in the row's last column both times. | Story 2 | `[unit]` | ✓ |
| 6 | FR5 | each keeps its own colour over the row's status colour | The pill and the badge each render in their own colour rather than the row's status colour, on a row whose status colour differs from both. | Story 2 | `[unit]` | ✓ |
| 7 | FR5 | sit against the right edge of the projects column whatever width that column has | must NOT — Neither pill nor badge is truncated on a row too narrow to hold everything: the project name is what gives. | Story 2 | `[unit]` | ✓ |
| 8 | NFR3 | The highlighted row and the pill stay legible on a terminal that does not report truecolor. | With the console limited to 256 colours, the highlighted row is still distinguishable from an unhighlighted one, and the pill from the row's own colour. | Story 3 | `[unit]` | ✓ |
| 9 | ENVX4 | the board must not require a truecolor terminal | The board renders against a console reporting 256 colours without error, and the render is not silently a monochrome one. | Story 3 | `[unit]` | ✓ |
