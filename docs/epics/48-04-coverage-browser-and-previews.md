# Coverage Matrix: Three-Column Browser and Previews

**Source spec**: docs/specifications/48-spec-dpm-board.md  
**Epic**: docs/epics/48-04-epic-browser-and-previews.md  
**Date**: 2026-08-13

> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|------------------|----------------------|----------------------------|------------|--------------------|----------|
| 1 | FR4 | "Projects, Epics and Stories columns render, and focus moves between them with ← / →" | "Projects, Epics and Stories columns render, and focus moves between them with ← / →" | Story 1 | `[feature]` | ✓ |
| 2 | FR4 | "The highlighted row's preview panel renders beneath its column" | "The highlighted row's preview panel renders beneath its column" | Story 1 | `[feature]` | ✓ |
| 3 | FR4 (added) | "Projects → Epics → Stories in Miller columns, with a preview panel beneath the Epics and Stories columns and colour carrying state." | "Each derived state maps to a distinct style, asserted from the rendered row rather than from the mapping table, and no two states share one" | Story 1 | `[feature]` | ✓ |
| 4 | ENV7 | "Feature-level tests drive the TUI through Textual's `run_test()` pilot" | "Feature-level tests drive the TUI through Textual's `run_test()` pilot" | Story 1 | `[feature]` | ✓ |
| 5 | FR7 | "Preview text for an epic, spec or retro equals what the read tool returned for it" | "Preview text for an epic, spec or retro equals what the read tool returned for it" | Story 2 | `[integration]` | ✓ |
| 6 | FR7 | "A story's preview renders that story's own criteria and tasks, not the whole epic" | "A story's preview renders that story's own acceptance criteria and tasks, not the whole epic" | Story 2 | `[integration]` | ✓ |
| 7 | FR7 (added) | "the story preview renders that story's own acceptance criteria and tasks as rows" | "A story whose epic has several stories previews only the selected one, asserted against a fixture where another story's criteria would be visible if the scope were wrong" | Story 2 | `[integration]` | ✓ |
| 8 | FR7 (must NOT) | "must NOT open a projected `.md` file to build any preview" | "must NOT open a projected `.md` file to build any preview" | Story 2 | `[unit]` | ✓ |
| 9 | NFR3 | "The Projects column renders before any spawned server has completed its handshake" | "The Projects column renders before any spawned server has completed its handshake" | Story 3 | `[feature]` | ✓ |
| 10 | NFR3 (added) | "Over ten registered projects the Projects column renders without waiting on server startup" | "Over ten registered projects the Projects column renders without waiting on server startup" | Story 3 | `[feature]` | ✓ |
| 11 | NFR3 (must NOT) | "must NOT block the UI thread on a server spawn or a tool call" | "must NOT block the UI thread on a server spawn or a tool call" | Story 3 | `[feature]` | ✓ |
| 12 | FR18 | "`Ctrl+P` opens the palette directly on the board's own actions" | "`Ctrl+P` opens the palette directly on the board's own actions" | Story 4 | `[feature]` | ✓ |
| 13 | FR18 (added) | "`Ctrl+P` opens straight to the board's own actions." | "The palette lists the board's actions and not Textual's default system commands" | Story 4 | `[feature]` | ✓ |
| 14 | FR1 | "Registration works from the CLI and from inside the TUI via a directory picker." | "A directory picker reached from the board registers a project, and the new project appears in the Projects column without a restart" | Story 5 | `[feature]` | ✓ |
| 15 | FR1 (added) | "Register, list and remove projects, persisted under XDG config." | "The picker refuses a directory that is not a dpm project with the same message the CLI gives" | Story 5 | `[feature]` | ✓ |

## Notes

**Row 3 is added because FR4's own criteria do not test the colour claim.** Rows 1 and 2 assert that the
columns and the preview panel render, and a stylesheet applying one class to every row passes both while
the requirement's third clause — colour carrying state — is false. Row 3 asserts distinctness from the
rendered rows and compares the whole map for collisions, with the state enumeration coming from 48-03, so
a state added later has no style and fails rather than silently sharing one.

**Row 7 is the fixture the scoping claim needs.** FR7's "not the whole epic" is unfalsifiable against an
epic holding one story, and a minimal fixture holds one story. Row 6 keeps the spec's wording; row 7 names
the fixture where a wrong scope is visible. Both are needed and neither substitutes for the other.

**Row 10 is NFR3's own text, promoted to a criterion.** The requirement states the ten-project condition
in its body and its criteria assert only the single-project handshake case. A board that renders promptly
with one project and serialises over ten satisfies row 9 and fails the requirement.

**Row 13 is what FR18's "directly" means.** Row 12 passes on a palette that opens and can be filtered down
to the board's actions, which is what an unconfigured Textual command provider gives. The requirement's
word is *straight*, and row 13 is the assertion that carries it.

**Rows 14 and 15 cover half of FR1.** The CLI half is
`docs/epics/48-02-coverage-board-foundation.md` row 3. FR1 is covered only across the two matrices, and
a ✓ here is not evidence about the CLI affordance. Row 15 asserts the picker's refusal against the CLI's
message rather than restating it, so the two cannot drift into different explanations of one condition.

**Rows 9–11 are driven from a fixture server, not a seam.** The delay that makes pre-handshake rendering
observable lives in a fixture the test spawns. An injection point added to the board for the test's benefit
would be production code with no production caller, and a call site could trip over it.

**FR4's preview panel and FR7's preview content are separate rows on purpose.** Row 2 asserts the panel is
there and beneath the right column; rows 5–7 assert what is in it. A panel rendering the wrong content
passes row 2, and a correct preview rendered in the wrong place passes rows 5–7.
