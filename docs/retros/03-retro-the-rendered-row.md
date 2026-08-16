# The rendered row — what the strips said and the widget did not

**Number**: 03  
**Source epic**: 02-03  
**Status**: complete  

## Observations

- Criteria gap · Pattern worth reusing — A rejection is only as good as the thing that would have caught it, and twice in this epic the obvious rejection had no purchase. "Textual's block cursor appears on no rendered row" passes with the override deleted, because `render_line` overwrites the background either way — what the block cursor actually does is become the colour the board's own bar is *mixed with*. "No marker is truncated" passes on a board that renders no markers at all. Both were rewritten into a claim about a value someone can compute — the bar is this row's colour blended toward the surface the unhighlighted rows share; this marker string is present whole — and both then had a control that fails them by a nameable amount.

Across all three stories, the criteria that held up were the ones asserting an arithmetic identity rather than an absence. Write the must-NOT as the positive fact whose failure the rejected thing causes, then run the control and read what it says — not merely that it raised.

- Codebase discovery · Testing gap — Every real failure this epic found was invisible on the machine it was developed on, and each surfaced only because a fixture was built from the model rather than from a sample. The blurred cursor on a `complete` row quantises to pure black at 256 colours — nothing in the code said which of the seven states would collapse, and the fixture that caught it enumerates `status_model.EPIC_STATES`. The pill vanished at 24 cells only when the badge was also present, which a one-marker fixture never reaches. A three-row fixture was needed before "the surface is the commonest background" stopped being decided by paint order.

The fixture is where this kind of bug is caught or missed, and enumerating the vocabulary costs nothing at the point of writing. Where a board renders one row per state, render all of them.

- Pattern worth reusing — Two measurement choices decided whether the checks meant anything. Luminance is the wrong metric for "distinguishable" on a board whose most important row is red — Rec. 709 weights red at a fifth, so a blocked row's bar reads 2 from the surface by luminance and 77 in the channel a reader sees; the widest single channel is what the tests compare. And the quantisation is Rich's own `downgrade` rather than a nearest-colour rule written in the test, because a second colour model agrees with the terminal until the day it does not. The same instinct kept `min_width` off the marker columns: it turned a visible ellipsis into a silently dropped session count.

Where a test needs a model of something the runtime already models — colour distance, quantisation, layout — call the runtime's. A parallel model is a second answer that drifts silently.
