# Coverage Matrix: Coverage Gaps and the Integrity Badge

**Source spec**: docs/specifications/48-spec-dpm-board.md  
**Epic**: docs/epics/48-08-epic-coverage-gaps-and-integrity.md  
**Date**: 2026-08-15

> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|------------------|----------------------|----------------------------|------------|--------------------|----------|
| 1 | FR16 | "Requirements with no coverage row, from `list_coverage` — a question CPM's board could not ask of a markdown corpus." | "The derivation returns exactly those requirements with no coverage row, over a fixture holding both traced and untraced requirements in one project" | Story 1 | — (none in spec) | ✓ |
| 2 | AD5 | "a single written source of truth for how state, progress and next actions are derived, conformed to by the board (in code) and `/dpm:status` (in prose), expressed in rows and tool calls" | "The rule is registered in `DERIVATIONS` under a name that exists as a `###` heading in `dpm/shared/status-model.md`, and the reconciliation passes in both directions" | Story 1 | — (none in spec) | ✓ |
| 3 | AD5 | "a single written source of truth for how state, progress and next actions are derived, conformed to by the board (in code) and `/dpm:status` (in prose), expressed in rows and tool calls" | "`dpm:status`'s Phase 3b is dispositioned against the new rule in `docs/maintenance/README.md`, saying whether the skill conforms, was amended, or deliberately differs" | Story 1 | — (none in spec) | ✓ |
| 4 | NFR5 | "Every tool name and argument the board declares resolves against the live server's `tools/list`" | "`list_requirement` and `list_coverage` appear in the contract's Inputs table, and both are reached through `declare()` rather than as bare strings at a call site" | Story 1 | `[integration]` | ✓ |
| 5 | FR16 (added) | "Requirements with no coverage row" | "A read that comes back with `more` set is followed to the next offset rather than reported as the answer" | Story 1 | — (none in spec) | ✓ |
| 6 | FR10 (must NOT) | "must NOT call any tool whose name is a mutating verb, in any code path" | "must NOT call any tool whose name is a mutating verb, in any code path" | Story 1 | `[unit]` | ✓ |
| 7 | FR16 | "Coverage gaps view. Requirements with no coverage row, from `list_coverage`" | "`ctrl+g` and a palette entry both open a view listing every untraced requirement across registered projects" | Story 2 | — (none in spec) | ✓ |
| 8 | FR16 (added) | "Requirements with no coverage row, from `list_coverage`" | "Each row carries its project and the requirement's own label, and selecting one moves the cursor to that project" | Story 2 | — (none in spec) | ✓ |
| 9 | FR16 (added) | "Requirements with no coverage row" | "A project with no untraced requirements contributes no rows, and an empty result renders as *no gaps* distinctly from *not read yet*" | Story 2 | — (none in spec) | ✓ |
| 10 | NFR2 | "With one project unreadable, every other registered project still renders its state" | "A project whose server cannot start contributes no rows and does not stop the other projects' rows appearing" | Story 2 | `[integration]` | ✓ |
| 11 | FR16 (added, must NOT) | "a question CPM's board could not ask of a markdown corpus" | "must NOT resolve a row to a spec the Epics column does not hold — where there is no row to move to, the result carries its project and no document" | Story 2 | — (none in spec) | ✓ |
| 12 | FR17 | "`check_integrity` per project, surfaced as a per-project badge." | "A project whose `check_integrity` reports violations shows a badge on its row carrying the count; a project reporting `ok` shows none" | Story 3 | — (none in spec) | ✓ |
| 13 | FR17 (added) | "surfaced as a per-project badge" | "The badge's marker is distinct from the `● live` pill and the `▸` ralph marker" | Story 3 | — (none in spec) | ✓ |
| 14 | FR17 (added) | "`check_integrity` per project" | "The badge's value comes from the `check_integrity` tool, asserted from the calls made" | Story 3 | — (none in spec) | ✓ |
| 15 | NFR2 | "One unreadable project never takes the board down. A failure is contained to its own row." | "A project whose check fails renders its FR11 state, and every other project still renders its badge" | Story 3 | `[integration]` | ✓ |
| 16 | FR10 | "After a full board session over a fixture project, the database file's hash, size and mtime are unchanged" | "A full board session that opens the gaps view and renders badges for every project leaves each project byte-identical" | Story 4 | `[integration]` | ✓ |
| 17 | FR13 | "A second read within the freshness window is served from cache; a touched database invalidates it" | "Both new reads are served from the cache on a second survey within the freshness window, rather than reaching the server again" | Story 4 | `[unit]` | ✓ |

## Notes

**Every row whose Spec Test Approach reads "— (none in spec)" maps to FR16 or FR17, and that is a
fact about the spec rather than a gap in this matrix.** Both requirements are Could-haves that the
spec deferred, so neither has a row in its Acceptance Criteria Coverage table. Every criterion on
those rows was written for this epic and tagged by judgement, defaulting to automation; none was
transcribed from the spec and none inherited a must-NOT from it. The rows that *do* carry a tag —
4, 6, 10, 15, 16, 17 — are Must-have coverage that this epic touches because the code that could
violate it is here.

**Rows 2 and 3 are the two halves AD5 needs and neither substitutes for the other.** Row 2 is the
mechanical half: a registry the code fills at import, reconciled against the contract's parsed `###`
headings in both directions, so a rule added to either side alone fails. Row 3 is the half no parse
can do — `dpm:status` is prose, and no comparison tells a passage that agrees with a rule from one
that never met it. What is checkable is that every rule was looked at, which is why the disposition
is the criterion.

**Row 5 is the half of FR16 the requirement's own words omit.** "Requirements with no coverage row"
is satisfiable by an answer over one page of requirements, and every fixture fits in one page and
always will. The contract already carries the rule — a truncated read is a wrong count, not a
smaller project — and this row is where the new reads are held to it. A derivation that silently
read one page would report requirements as untraced because their coverage rows were on page two.

**Row 8 is FR16's navigation half and row 11 is its limit.** The board holds documents and stories;
a requirement belongs to a spec, and the Epics column does not hold specs. So a gap row can always
name its project and can name a document only where the column holds one. This is the same boundary
48-07 recorded for FR15 on row 10 of its matrix, reached from the other direction, and the answer is
the same: carry the absence rather than invent it or hide the row.

**Row 14 is the provenance half of FR17.** Row 12 is satisfied by a badge assembled any way at all,
including from a count the board computed itself. FR17 names `check_integrity` specifically, and
this is the row that carries it — the same shape as 48-07's row 11, 48-03's row 4 and 48-02's row 25.

**Row 16 does not make 48-06's rows 9 and 10 redundant, and neither makes it redundant.** FR10's
existing proof runs over a board session that never opened this epic's two paths; this row runs one
that definitely does. A ✓ on either is not evidence about the other, which is the same reason 48-07
added row 5 rather than pointing at 48-06's.

**Row 17's criterion says "a second survey", and two of the three reads are not survey reads.**
`check_integrity` is inside `read_view`; `list_requirement` and `list_coverage` are in the gaps
fan-out, which is an action a user takes rather than part of a repaint. The criterion is a claim
about the wire, so the test drives both entry points twice and counts every call off one
transcript — and asserts the invalidation half as well, so a path that cached nothing but was
called once cannot satisfy it. Recorded here because the wording, read literally, describes a
placement the code deliberately does not have.
