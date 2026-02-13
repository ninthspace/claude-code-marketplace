# Discussion: Optional TDD Mode for CPM Execution Pipeline

**Date**: 2026-02-13
**Agents**: Casey, Margot, Bella, Ren

## Discussion Highlights

### Key points so far
- Casey: Acceptance criteria in epic docs already read like test specs — TDD is a natural fit. Main challenge is discipline constraint (Claude writing failing test first without jumping to implementation).
- Margot: TDD changes the inside of the task execution step, not the overall pipeline — containable. Key design decision: skill-level flag vs per-story marker in epic doc vs per-task decision.
- Bella: TDD works well for greenfield with clear criteria but is backwards for exploratory tasks. "Only as an option" is critical. Refactor step needs scoping constraints.
- **User decision**: Per-story toggle is the preferred approach.
- Margot: Piggyback on existing test approach tags — add `[tdd]` tag. cpm:epics already propagates test tags from spec → stories → tasks. cpm:do switches to TDD sub-loop when it encounters a `[tdd]`-tagged story.
- Casey: `[tdd]` should be orthogonal to test level tags (`[unit]`, `[integration]`, etc.). It describes a *workflow mode*, not a test level. The verification gate moves forward — test is the first thing written, not the last thing checked.
- **User decision**: `[tdd]` as orthogonal workflow mode tag is the preferred approach.
- Ren: Opt-in per story enables incremental adoption. Flags that review and retro skills need to be aware of which mode was used — retro observations about testing gaps mean different things for TDD vs post-implementation stories.

### Design decisions made
1. TDD is a per-story toggle, not a skill-level flag or per-task decision
2. `[tdd]` is a new test approach tag, orthogonal to level tags (`[unit]`, `[integration]`, `[feature]`, `[manual]`)
3. Existing tag propagation machinery in cpm:epics carries `[tdd]` from spec → stories → tasks
4. cpm:do switches to a TDD sub-loop (red → green → refactor) when it encounters `[tdd]`-tagged stories
5. The change is contained inside the task execution step — no pipeline-level restructuring needed

### Open questions for specification
- Precise per-task workflow for TDD mode in cpm:do (red → green → refactor steps)
- How the refactor step is scoped to prevent over-restructuring
- Whether review and retro skills need to track which execution mode was used per story
- How cpm:spec's testing strategy section surfaces `[tdd]` as an available tag
- How cpm:epics decides (or the user decides) which stories get `[tdd]`
- Handling of exploratory tasks within a `[tdd]`-tagged story
