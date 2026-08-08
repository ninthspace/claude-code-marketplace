# Coverage Matrix: Projection, Guard and Merge

**Source spec**: docs/specifications/47-spec-dpm-sqlite-persistence.md  
**Epic**: docs/epics/47-04-epic-projection-guard-and-merge.md  
**Date**: 2026-08-08

> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|------------------|----------------------|----------------------------|------------|--------------------|----------|
| 1 | FR6 | Every artefact renders to markdown under `docs/`, regenerated from the database and committed | Regenerating the projection twice from one database state yields byte-identical output | Story 1 | `[integration]` | |
| 2 | FR6 | so that pull requests show a readable prose diff of what changed | A value written through a create tool appears in the rendered markdown for its document — determinism without this is satisfied by a renderer that emits nothing | Story 1 | `[integration]` | |
| 3 | AD9 | A ULID is lexicographically sortable by its timestamp prefix, which gives every table a stable default order for free — the tiebreak FR6's determinism criterion needs. | Two databases holding identical logical content, with child rows inserted in different orders, render byte-identical markdown | Story 1 | `[integration]` | |
| 4 | FR6 (must NOT) | The projection is a render, not a store (AD3). | must NOT — a projected collection has no ordering column and no declared tiebreak, so its render order is whatever the query returns | Story 1 | `[unit]` | |
| 5 | AD8 | nothing in dpm reads markdown, so the component that would have inherited CPM's parsing failures — retro 21's `awk -v` collapse among them — has no counterpart here | No source file outside the projection renderer imports a markdown parser, and the renderer's only filesystem calls under `docs/` are writes — asserted over the module list, not over behaviour | Story 1 | `[integration]` | |
| 6 | FR10 | Each of the thirteen `document_kind` rows has a projection template; the ten non-document types and the ADR render inside a parent's template and are asserted to appear in one | Each of the thirteen `document_kind` rows has a projection template; the ten non-document types and the ADR render inside a parent's template and are asserted to appear in one | Story 2 | `[integration]` | |
| 7 | FR10 | the enumeration has no member without one | The template registry is enumerated against the seeded `document_kind` rows, so a kind seeded without a template fails rather than rendering | Story 2 | `[unit]` | |
| 8 | FR10 (must NOT) | The list and every vocabulary in it are taken from a real CPM project's `docs/` tree | must NOT — a missing template falls back to a generic renderer, so an untyped dump ships in place of a failure | Story 2 | `[unit]` | |
| 9 | FR7 | A pre-commit guard regenerates both generated artefacts — the markdown projection and `.dpm/dpm.sql` — and fails on divergence in either, naming what diverged. | A hand-edited generated file causes the pre-commit guard to exit non-zero, naming the file | Story 3 | `[feature]` | |
| 10 | FR7 (must NOT) | Silent loss of a user's edit is one failure this prevents | must NOT — a hand-edit is silently overwritten with no diagnostic | Story 3 | `[feature]` | |
| 11 | FR7 | a commit carrying a fresh projection and a stale dump is the other | A write made since the last commit leaves `.dpm/dpm.sql` stale, and the guard regenerates it and fails, naming it | Story 3 | `[feature]` | |
| 12 | FR7 (must NOT) | a commit carrying a fresh projection and a stale dump is the other | must NOT — a commit is accepted carrying a regenerated projection and an unregenerated dump | Story 3 | `[feature]` | |
| 13 | AD8 (must NOT) | Because the projection is one-way, an edit made to a generated file is lost at the next regeneration. | must NOT — the pre-commit divergence guard compares by parsing a generated file rather than by regenerating and diffing bytes | Story 3 | `[integration]` | |
| 14 | FR8 | Surrogate keys are ULIDs and never collide, so the conflict is confined to the human numbers | Two branches each adding a spec allocate distinct ULIDs for every row, so the merged dump has no primary-key collision on any table | Story 4 | `[integration]` | |
| 15 | FR8 | Two branches that both add artefacts produce an ordinary text conflict (AD4). | Two branches each adding an epic produce a resolvable text conflict, and the merged dump restores | Story 4 | `[feature]` | |
| 16 | FR8 | dpm ships a **merge tool** that restores the merged dump, detects the rows rejected by `document_root_number` and `document_child_number`, re-allocates the loser's number from `number_sequence`, renames its projection file, and re-renders the artefacts that referenced it (AD9). | When both branches allocated the same human number, the merge tool renumbers one, renames its projection file, and re-renders the artefacts that referenced it; the restored database then passes `PRAGMA foreign_key_check` and the register's checks | Story 4 | `[feature]` | |
| 17 | FR8 (must NOT) | re-allocates the loser's number from `number_sequence` | must NOT — a number collision is resolved by silently overwriting one side, or left for the user to find when the projection renders two artefacts with the same number | Story 4 | `[feature]` | |
| 18 | FR6 | Every artefact renders to markdown under `docs/` | A database holding one document of each of the thirteen kinds regenerates byte-identically twice, so determinism is asserted across the full template set rather than the single kind Story 1 used | Story 5 | `[integration]` | |
| 19 | FR7 | A pre-commit guard regenerates both generated artefacts | The pre-commit guard runs against the real renderer and the real dumper, and a commit carrying only a database write is rejected until both generated artefacts are regenerated | Story 5 | `[feature]` | |
| 20 | FR8 | renames its projection file, and re-renders the artefacts that referenced it | A merge that renumbers a spec yields a projection tree whose filenames and cross-references agree, and regenerating from the merged database changes no bytes | Story 5 | `[feature]` | |
| 21 | NFR6 | Any condition that could produce a false pass — a constraint violation swallowed, a projection silently stale, a search index behind the data — reports and blocks. | must NOT — the guard passes because it regenerates with a renderer that silently skips a kind it has no template for | Story 5 | `[integration]` | |
| 22 | FR28 | are written `{{ref:<id>}}` and resolved by the renderer to the target's current human identifier | A `{{ref:<id>}}` marker in a section body and in a `requirement.text` both render as the target's current human identifier | Story 1 | `[integration]` | |
| 23 | FR28 (must NOT) | A stored number would go stale the moment a merge renumbered its target, and no tool could find it to repair (FR8). | must NOT — a projected body contains a literal artefact number that no row produced | Story 1 | `[unit]` | |
| 24 | FR28 | A reference from one artefact's prose to another is a marker, never a number. | Renumbering a document through the merge tool changes no stored text, and the next render resolves every marker naming it to the new number | Story 4 | `[feature]` | |

**Mapping notes.**

**Row 3 maps to AD9, not FR6**, even though the spec's Acceptance Criteria Coverage table
files that criterion under FR6. The property being asserted — an insertion-order-independent
render — is delivered by ULIDs sorting by creation time, and AD9 §201 says so in the words
quoted. FR6 states the obligation; AD9 supplies the mechanism, so the mechanism is what the
row is bound to.

**Rows 5 and 13 map to AD8.** Row 5 is the module-list assertion the spec tags AD8. Row 13's
clause the spec also tags AD8, and its Spec Text is FR7's own explanation of why one-wayness
requires refusal — the sentence the guard exists to honour.

**Row 8's Spec Text is the nearest requirement text, not a verbatim must-NOT.** FR10 carries
no clause about template fallback; this one was proposed during breakdown and accepted by
Chris on 2026-08-08. It is recorded here with FR10's text so the row is traceable rather
than appearing to quote a line the spec does not contain.

**Row 21 maps to NFR6, not FR6 or FR7.** The composition failure it describes — a guard that
diffs clean because the renderer skipped a kind — is a false pass, and NFR6 is the
requirement that forbids false passes generally. It is not in NFR6's sixteen-entry register,
because that register enumerates *schema* conditions; this one lives between two components.

**Rows 16 and 20 were rewritten by the pivot of 2026-08-08, and rows 22–24 added.** FR8's
"rewrites the references that named it" was either vacuous or unimplementable under FR2 —
register entry 5. FR28 closed it: a prose reference is a `{{ref:<id>}}` marker, so the merge
tool re-renders rather than rewrites and nothing writes text into a row. Both rows are
unverified under the verification rule, as is row 6, whose count moved from nine to ten plus
the ADR.

**Row 6's Spec Text and Story Criterion are identical, which is deliberate.** FR10's template
clause is already written as an assertion over the finished projection, so there is nothing
to specialise. The ADR is named separately from the ten non-document types because it is not
one of them — it is a `document_kind` with `dir IS NULL`, a document that renders inside
another document, and it is the only member of that class.
