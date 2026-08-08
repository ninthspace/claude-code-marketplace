# Coverage Matrix: Skills — Lifecycle

**Source spec**: docs/specifications/47-spec-dpm-sqlite-persistence.md  
**Epic**: docs/epics/47-09-epic-skills-lifecycle.md  
**Date**: 2026-08-08

> **Verification rule**: Verification status (✓) is bound to criterion text. Any change to a story criterion or its spec mapping resets that row to unverified.

| # | Spec Requirement | Spec Text (verbatim) | Story Criterion (verbatim) | Covered by | Spec Test Approach | Verified |
|---|------------------|----------------------|----------------------------|------------|--------------------|----------|
| 1 | FR25 | each rewritten against the tool surface | A pivot run amends artefacts through update tools, and cascades to downstream documents by traversing foreign keys rather than by discovering chains from back-reference prose | Story 1 | `[feature]` | |
| 2 | FR21 | Every coverage matrix CPM writes states this rule in prose and relies on an agent to honour it; here the database enforces it. | Coverage verification is cleared by FR21's triggers when a criterion's text changes, so the skill no longer edits `\| ✓ \|` to `\| \|` and no longer needs to derive a matrix path from an epic path | Story 1 | `[integration]` | |
| 3 | FR25 (must NOT) | no procedure that recovers an entity by reading what an earlier skill wrote | must NOT — the skill recovers an entity by reading a generated markdown file rather than by calling a read tool | Story 1 | `[unit]` | |
| 4 | FR25 | Each of those is a tool call. | An archive run sets `archived_at` and leaves `status` untouched, so a document is archived *and* complete rather than forced to choose | Story 2 | `[feature]` | |
| 5 | FR5 | Human-facing artefact numbers are allocated monotonically and are never reused, including after archival. No glob, no filename parse, no archive-mirror contract. | Numbers allocated before archival are never reissued after it, with no mirrored `docs/archive/{type}/` tree and no glob over one | Story 2 | `[integration]` | |
| 6 | FR25 (must NOT) | no procedure that recovers an entity by reading what an earlier skill wrote | must NOT — the skill recovers an entity by reading a generated markdown file rather than by calling a read tool | Story 2 | `[unit]` | |
| 7 | FR11 | The progress-file subsystem — session-suffixed filenames, hook injection, adoption on `--resume`, compact-summary companions — is replaced by a session table. Adoption is an `UPDATE`; staleness is a `WHERE` clause. | A clean run selects stale `session` rows by age and removes them, with no filename stem to glob and no session-suffix convention to match | Story 3 | `[integration]` | |
| 8 | FR25 (must NOT) | no procedure that recovers an entity by reading what an earlier skill wrote | must NOT — the skill recovers an entity by reading a generated markdown file rather than by calling a read tool | Story 3 | `[unit]` | |
| 9 | FR11 | Adoption is an `UPDATE` | A ralph run carries its loop state in `session` rows, and a resume under a new session id adopts the prior row rather than reading a progress file | Story 4 | `[feature]` | |
| 10 | FR25 (must NOT) | no procedure that recovers an entity by reading what an earlier skill wrote | must NOT — the skill recovers an entity by reading a generated markdown file rather than by calling a read tool | Story 4 | `[unit]` | |
| 11 | FR25 | The twenty-two skills named in FR25 all exist, and no skill exists that FR25 does not name | The twenty-two skills named in FR25 all exist, and no skill exists that FR25 does not name | Story 5 | `[unit]` | |
| 12 | FR25 | Every pipeline stage a CPM user can reach has a dpm skill, asserted by comparing the corpus against CPM's own skill directory | Every pipeline stage a CPM user can reach has a dpm skill, asserted by comparing the corpus against CPM's own skill directory | Story 5 | `[integration]` | |
| 13 | FR25 | No skill file contains a filename pattern under `docs/`, a glob, a number-allocation procedure, or a progress-file lifecycle | No skill file contains a filename pattern under `docs/`, a glob, a number-allocation procedure, or a progress-file lifecycle — swept across all twenty-two | Story 5 | `[unit]` | |
| 14 | FR3 | Every dpm SKILL.md contains no SQL keyword and no `sqlite3` invocation | Every dpm SKILL.md contains no SQL keyword and no `sqlite3` invocation — swept across all twenty-two | Story 5 | `[unit]` | |
| 15 | FR25 (must NOT) | must NOT — a skill recovers an entity by reading a generated markdown file rather than by calling a read tool | must NOT — a skill recovers an entity by reading a generated markdown file rather than by calling a read tool, swept across all twenty-two | Story 5 | `[unit]` | |
| 16 | FR10 | Every artefact type CPM produces is modelled from the outset | Every artefact whose lineage roots at spec 47 loads through create tools, and the projection regenerates each of them — the spec, every review and retro sourced from it or from its epics, the nine epic documents, their nine coverage matrices, and every artifact registered against any of them. The set is derived by walking lineage, not enumerated here, so an artefact the corpus gains after this criterion was written is still covered | Story 6 | `[feature]` | |
| 17 | FR14 | A verification tool reports orphans, dangling links, and each entry in the cross-row invariant register (Data Model), so a corrupted state is diagnosable without SQL. | The loaded corpus passes `PRAGMA foreign_key_check` and every entry in the invariant register | Story 6 | `[integration]` | |
| 18 | FR10 | The list and every vocabulary in it are taken from a real CPM project's `docs/` tree, not from CPM's documentation — the two disagree. | Every entry in the self-hosting register is closed, or explicitly waived with a recorded reason; no entry remains OPEN | Story 6 | `[integration]` | |
| 19 | NFR6 (must NOT) | Any condition that could produce a false pass — a constraint violation swallowed, a projection silently stale, a search index behind the data — reports and blocks. This spec's subject applied to itself: the failure being designed against is one that looks like success. | must NOT — a corpus artefact loads with content dropped because no column held it, and the load reports success | Story 6 | `[integration]` | |
| 20 | FR28 (must NOT) | A stored number would go stale the moment a merge renumbered its target, and no tool could find it to repair (FR8). | No skill writes a literal artefact number into a prose column; a reference to another artefact is written `{{ref:<id>}}` — swept across all twenty-two | Story 5 | `[unit]` | |
| 21 | FR25 | What remains is the facilitation — the questions, the gates, the judgement | The facilitation survives: every downstream change is still gated individually rather than applied as a batch, and a status change still edits the token while leaving the human note tail intact | Story 1 | `[feature]` | |
| 22 | FR25 | What remains is the facilitation — the questions, the gates, the judgement | The facilitation survives: a coverage matrix is still never archived apart from its epic, and a retired epic sitting in a chain whose other members are live is still archived alone rather than taking the chain with it | Story 2 | `[feature]` | |
| 23 | FR25 | What remains is the facilitation — the questions, the gates, the judgement | The facilitation survives: every candidate is still listed before anything is asked, only what was named and confirmed is deleted, and the skill is still unreachable from an autonomous loop | Story 3 | `[feature]` | |
| 24 | FR25 | What remains is the facilitation — the questions, the gates, the judgement | The facilitation survives: pre-flight still probes the stop hook and branches on what it finds, and a detected previous run is still offered as a resume rather than restarted over | Story 4 | `[feature]` | |
| 25 | FR25 (must NOT) | must NOT — a skill satisfies every subtraction sweep while retaining none of its counterpart's facilitation, so a corpus of twenty-two files each carrying a title and a single tool call passes | Every one of the twenty-two carries a passing facilitation criterion on its own story, checked here as a roll-up: the five sweeps above are all negative, and a corpus of twenty-two files each holding a title and a single tool call satisfies every one of them | Story 5 | `[unit]` | |
| 26 | FR25 (must NOT) | must NOT — the pipeline-stage comparison reports success because CPM's `skills/` directory was absent, rather than failing on a fixture it could not read | must NOT — the pipeline-stage comparison reports success because CPM's `skills/` directory was absent, rather than failing on a fixture it could not read | Story 5 | `[integration]` | |

**Mapping notes.**

**Rows 11, 12 and 26 have a Story Criterion verbatim identical to their Spec Text; rows
13–15 differ only by an appended scope phrase.** FR25's corpus-wide criteria are already
written as assertions over the finished corpus, so there is little to specialise — rows 13–15
add "swept across all twenty-two", which names what "no skill file" means once the corpus is
closed, and rows 11, 12 and 26 add nothing because the spec criterion is already an assertion
about exactly this story.

This note previously claimed rows 11–15 were **the only** such rows in the breakdown. That was
wrong twice over and is corrected here rather than carried. It was internally inconsistent on
its own terms — it called 13–15 identical in one clause and described the phrase they add in
the next — and the uniqueness claim has since been falsified by the two pivots of 2026-08-08,
which added Epic 47-01 rows 82–85 and Epic 47-05 row 18 and rewrote Epic 47-05 row 1, all
verbatim-identical, alongside Epic 47-04 row 6. Ten rows across four matrices now have the
property. It is unremarkable where a spec criterion is already scoped to one story, which is
the case in every one of them.

**Row 26 settles what dpm's suite may read outside its own tree**, and is the second half of
a distinction the spec now draws in *What the suite reads outside dpm*. Row 12's comparison
reads CPM's `skills/` **directory names** — CPM ships at `cpm/` in the same marketplace
repository, so it is a sibling directory in the same commit, needing no version pin and no
install step. Row 26 is the guard on it: a suite run from an extracted plugin copy has no
`cpm/` beside it, and a set comparison against a directory that does not exist passes
trivially. The check that exists to catch a short list is the one most easily satisfied by
finding nothing at all, which is NFR6's false pass in its purest form. **Nothing here reads
CPM's `SKILL.md` content** — the retention criteria on rows 21–24 and across Epics 47-06 to
47-08 name their behaviours in the criterion and drive the dpm skill, because an oracle that
the thing under test can edit is not an oracle.

**Row 2 maps to FR21, not FR25.** The subtraction is real, but what the criterion asserts is
that the triggers do the work — a claim about FR21's decay behaviour reaching the skill
layer. Epic 47-01 Story 7 proves the triggers fire; this proves `pivot` stopped doing it by
hand. The pipe characters in the criterion are escaped for the table and are literal in the
epic document. **Any check comparing this column against the epic's criteria must unescape
before comparing** — review 05 ran exactly that comparison and row 2 was its only false
positive across all nine pairs. The escaping is required by table syntax and is not
divergence; the fix belongs in the check, never in the criterion.

**Row 11's approach was `[integration]` until review 05; the spec tags it `[unit]`.** This
column carries the *spec's* approach, so where the epic and the spec disagree the spec wins
and the epic's own tag is the thing to reconsider. One row in 241 across the breakdown, which
is why it reads as a slip rather than a pattern — but a column named "Spec Test Approach"
that holds the epic's value asserts a provenance it does not have, and a reader using it to
check one document against the other is checking a document against itself.

**Row 16 was rewritten by the pivot that applied review 05.** It enumerated the corpus by
name — "spec 47, review 04, retro 33, the nine epics and the nine coverage matrices" — and
was already short by three when the review ran: retro 34, the schema-map artifact in the
spec's `**Artifacts**:` field, and review 05 itself. It now derives membership by walking
lineage. The artifact was the costly omission: `artifact` and `artifact_document` are two of
the twenty-three tables, and the check that gates the whole build was never exercising
either.

**Row 5's Spec Text is two adjacent sentences of FR5**, quoted together because the criterion
asserts both halves and neither sentence carries it alone: the first says numbers are never
reused after archival, the second says the archive-mirror contract is gone. A criterion
satisfying only the first is met by keeping the mirrored tree.

**Row 18 maps to FR10 by its weakest link and is worth stating plainly.** The self-hosting
register is not a spec construct — it is Chris's standing check, recorded in Epic 47-01's
Notes on 2026-08-08. FR10's parity obligation is the nearest requirement, since every open
entry is something the corpus contains that the model cannot hold. The pivot that followed
this breakdown closed all five entries but did not turn the register itself into spec text,
so the mapping stands; FR26, FR27 and FR28 are the entries' answers, not the register.

**Row 20 was added by that pivot, and is FR28's write side.** Epic 47-04 covers resolution —
markers render as the target's current identifier, and a projected body may hold no number no
row produced. Nothing covered emission until this row. Its failure mode is why it belongs to
the corpus sweep rather than to any authoring skill: a skill that writes `spec 47` into a
prose column ships clean and fails at a render it did not perform, in a file it did not
write. Five of the twenty-two skills are candidates today; the sweep costs the same for all
twenty-two and survives a sixth being added later.

**Row 19 maps to NFR6 and is the spec's own sentence turned on the spec.** NFR6 says "this
spec's subject applied to itself"; row 19 is that sentence made into a test, and it is the
single criterion in the breakdown that most directly asks whether the exercise worked.

**Rows 21–24 were added on 2026-08-08, one per conversion story, and row 25 is the roll-up
that makes the other eighteen across the four skills matrices load-bearing.** Row 25 is the
sharpest row in this matrix and the reason the whole sweep was worth running. Every other
check Story 5 performs is a search for something that must be **absent** — no glob, no
filename pattern, no number allocation, no progress-file lifecycle, no SQL. Absence is what a
gutted skill has most of. Twenty-two files each containing a title and one tool call pass all
five sweeps, pass FR25's existence check, pass the pipeline-stage comparison, and ship a
corpus that does nothing. Nothing in this breakdown caught that before row 25 existed.

**Row 25 does not re-assert the per-skill criteria; it asserts they are all present and all
passing.** The distinction matters because facilitation cannot be checked corpus-wide —
what `clean` must still refuse and what `templates` must still not gate have no common shape,
which is why the retention criteria live on the individual stories. What a corpus check *can*
do is fail when one of the twenty-two has no such criterion at all. That is the failure this
row exists for, and it is the one the breakdown actually had: at the time it was written,
eighteen of the twenty-two conversion stories carried no retention criterion, and all eight
of Epic 47-08's read skills were among them.

**Coverage completes here.** FR25 and FR3 have been partially covered since Epic 47-06 and
are satisfied by rows 11–15 and 25. This is the only matrix in the breakdown that closes a
requirement rather than contributing to one — which is itself the observation behind
self-hosting register entry 1. FR28 is the exception among the pivot's three new
requirements: its two halves sit in Epic 47-04 and in row 20 here, so it closes in this
matrix too.

**Story 7's two criteria have no rows here, and that is declared rather than missed.** It is
the "Address review findings" story, which records repairs to this breakdown rather than
obligations drawn from the spec, so its criteria have no requirement to bind to. The
both-directions set comparison should expect exactly those two as an unmatched remainder.
