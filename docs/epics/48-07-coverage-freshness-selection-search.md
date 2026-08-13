# Coverage Matrix: Freshness, Ralph Multi-Select and Cross-Project Search

**Source spec**: docs/specifications/48-spec-dpm-board.md  
**Epic**: docs/epics/48-07-epic-freshness-selection-search.md  
**Date**: 2026-08-13

> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|------------------|----------------------|----------------------------|------------|--------------------|----------|
| 1 | FR13 | "A second read within the freshness window is served from cache; a touched database invalidates it" | "A second read within the freshness window is served from cache; a touched database invalidates it" | Story 1 | `[unit]` | |
| 2 | AD6 | "the cache stamp is the database file's mtime and size, plus a schema-version stamp that invalidates old entries" | "The cache stamp is the database file's mtime and size, and a schema-version stamp invalidates entries written under an earlier schema" | Story 1 | `[unit]` | |
| 3 | FR13 (added) | "Derived per-project status is cached and invalidated by the database file's own mtime and size, with a force-refresh and a clear." | "A force-refresh bypasses the cache and a clear removes it, both reachable from the board" | Story 1 | `[feature]` | |
| 4 | ENVX6 | "A registered project that is not a git repository renders normally" | "A registered project that is not a git repository renders normally" | Story 1 | `[integration]` | |
| 5 | FR10 (added, must NOT) | "no file under a registered project is written — `.dpm/` included. Observing a project leaves it byte-identical." | "must NOT write the cache anywhere inside a registered project — it lives beside the registry under XDG" | Story 1 | `[unit]` | |
| 6 | FR14 | "A non-empty ralph selection retargets the launch keys to one `/dpm:ralph <epics…>` command" | "A non-empty ralph selection retargets the launch keys to one `/dpm:ralph <epics…>` command" | Story 2 | `[unit]` | |
| 7 | FR14 (added) | "`space` selects runnable epics; while the selection is non-empty the launch keys build one `/dpm:ralph <epics…>` command instead of a single-epic `/dpm:do`." | "`space` selects a runnable epic and deselects it, and the selection is visible in the row" | Story 2 | `[feature]` | |
| 8 | FR14 (added) | "instead of a single-epic `/dpm:do`" | "With an empty selection the launch keys behave exactly as 48-05 specifies, asserted against the same targets" | Story 2 | `[unit]` | |
| 9 | FR14 (must NOT) | "must NOT allow selection of a blocked, retro or needs-epics row" | "must NOT allow selection of a blocked, retro or needs-epics row" | Story 2 | `[unit]` | |
| 10 | FR15 | "A search runs across registered projects and each result navigates back to its project and epic" | "A search runs across registered projects and each result navigates back to its project and epic" | Story 3 | `[integration]` | |
| 11 | FR15 (added) | "The `search` tool, run across registered projects, with results navigable back to their project and epic." | "Results come from the `search` tool, asserted from the calls made" | Story 3 | `[integration]` | |
| 12 | NFR2 (added) | "One unreadable project never takes the board down. A failure is contained to its own row." | "A project whose server cannot start contributes no results and does not stop the other projects' results appearing" | Story 3 | `[integration]` | |

## Notes

**Row 5 maps to FR10, not FR13,** and is the reason it is in this matrix at all. The cache is a write, and
FR10's proof at `docs/epics/48-06-coverage-failure-surface.md` rows 9 and 10 runs over a board session that
may never have triggered a cache entry. This row hashes the project tree across a session that definitely
does. If the cache is ever cut from scope, this row moves to 48-06 rather than being dropped with it.

**Row 3 is the half of FR13 its criterion omits.** The requirement names a force-refresh and a clear; the
criterion tests only the caching and the invalidation. A cache with neither control passes row 1, and
mtime-and-size has a real blind spot — a write that preserves both — which is what those controls exist for.

**Row 8 is what stops FR14 breaking FR8.** Row 6 says a non-empty selection retargets the launch keys and is
satisfied by a board that always builds a `/dpm:ralph` command, with one epic in it when nothing is
selected. That board passes every row in this matrix and fails
`docs/epics/48-05-coverage-launch-and-live-sessions.md` rows 1 and 2. Row 8 asserts the empty case against
those same targets rather than restating them, so the two cannot drift.

**Row 7 is FR14's reachability half.** Row 6 is about what the launch keys compute; nothing in FR14's own
criteria says a user can build a selection or see one. Both halves are needed — a correct retargeting over
an unreachable selection is not a feature.

**Row 11 is the provenance half of FR15.** Row 10 is satisfied by results assembled any way at all, including
from a cache or from a local index. FR15 names the `search` tool specifically, and this is the row that
carries it — the same shape as 48-03's row 4 and 48-02's row 25.

**Row 12 maps to NFR2 rather than FR15.** Search is the one action that fans out across every registered
project at once, which makes it the path where a single failing server most plausibly takes the whole result
set down. 48-06's row 6 verifies containment for per-project reads; this verifies it for the fan-out, and
neither ✓ is evidence about the other.

**Every row here belongs to a Should-have except rows 5 and 12.** Those two are Must-have coverage that
happens to live in this epic because the code that could violate them is here.
