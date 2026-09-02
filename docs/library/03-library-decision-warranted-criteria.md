# A Decision Constrains a Story Exactly as a Requirement Does

**Number**: 03  
**Status**: complete — In force. Promoted from retro 02's four instances of a criterion whose warrant is an accepted ADR rather than requirement text. It records a known limitation of the coverage model and the two ways out; taking one of them is a change to the model and is not decided here.  

**Type**: architecture  
**Scope**: epics, spec  

## A criterion warranted by an ADR carries no coverage rows, and the roll-up cannot say why

Four instances across one spec — epic 1 story 5 had two, epic 2 story 1 one, epic 2 story 4 one — which is a shape rather than a coincidence.

The coverage graph binds a criterion to a verbatim fragment of a requirement. A criterion whose warrant is an accepted ADR has no such fragment: "the stamp skew adds a second top-level field distinct from the neighbour's" cites AD1 in its own wording and traces to a decision, not to requirement text. `dpm:epics` correctly refuses to bind it. The criterion is tested; the verification is invisible to the roll-up.

**The cost is not the missing row, it is that the absence is ambiguous.** A criterion warranted by a decision and a criterion nobody got round to binding read identically — a story criterion with no coverage rows — and what separates them is a sentence there is nowhere on the row to write.

Two ways out, and choosing between them is a change to the coverage model rather than something a run decides: make an accepted ADR bindable, or require that a decision constraining a story also produces a requirement. Until one is taken, say at spec time which criteria are decision-warranted, so the roll-up's silence is readable.
