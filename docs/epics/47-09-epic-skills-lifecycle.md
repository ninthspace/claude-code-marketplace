# Skills: Lifecycle

**Source spec**: docs/specifications/47-spec-dpm-sqlite-persistence.md  
**Date**: 2026-08-08  
**Status**: Pending  
**Blocked by**: Epic 47-06-epic-skills-spine, Epic 47-07-epic-skills-authoring, Epic 47-08-epic-skills-read-surface

Milestone M4 (AD6), and the end of the build. Four of FR25's twenty-two skills, then the two
stories that close the spec: Story 5 asserts the corpus is complete, and Story 6 is Chris's
standing check — **dpm must be able to hold dpm's own planning corpus**.

These four are the skills whose entire reason for existing is a markdown-store constraint.
`archive` maintains a mirrored directory tree solely so a glob can find retired numbers;
`clean` deletes files that are only files because state had nowhere else to live. Converting
them is mostly deletion.

## Convert `pivot` [plan]
**Story**: 1  
**Status**: Pending  
**Blocked by**: —  
**Satisfies**: FR25, FR21, FR2

**Acceptance Criteria**:

- A pivot run amends artefacts through update tools, and cascades to downstream documents by traversing foreign keys rather than by discovering chains from back-reference prose [feature]
- Coverage verification is cleared by FR21's triggers when a criterion's text changes, so the skill no longer edits `| ✓ |` to `| |` and no longer needs to derive a matrix path from an epic path [integration]
- must NOT — the skill recovers an entity by reading a generated markdown file rather than by calling a read tool [unit]

### Rewrite amendment as update-tool calls, and cascade discovery as foreign-key traversal
**Task**: 1.1  
**Description**: Chain discovery today reads back-reference fields, falls back to slug matching when they do not resolve, and presents partial chains when neither works. All three disappear into one join.  
**Status**: Pending

### Delete the coverage-matrix invalidation procedure
**Task**: 1.2  
**Description**: The triggers do it. The procedure being deleted derives a matrix path from an epic path by substituting `-epic-` for `-coverage-` and then edits `✓` cells — a failure that is silent, because a matrix it fails to find keeps asserting that changed criteria were verified.  
**Status**: Pending

### Write tests for Convert `pivot`
**Task**: 1.3  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`, `[integration]`, or `[feature]`.  
**Status**: Pending

---

## Convert `archive`
**Story**: 2  
**Status**: Pending  
**Blocked by**: —  
**Satisfies**: FR25, FR5

**Acceptance Criteria**:

- An archive run sets `archived_at` and leaves `status` untouched, so a document is archived *and* complete rather than forced to choose [feature]
- Numbers allocated before archival are never reissued after it, with no mirrored `docs/archive/{type}/` tree and no glob over one [integration]
- must NOT — the skill recovers an entity by reading a generated markdown file rather than by calling a read tool [unit]

### Set `archived_at` without touching `status`
**Task**: 2.1  
**Description**: The two are orthogonal. Collapsing them into one enum forces a false choice and loses the completion state on archival.  
**Status**: Pending

### Remove the mirrored-tree contract
**Task**: 2.2  
**Description**: `number_sequence` retains allocations, so nothing needs a directory layout to remember them. A load-bearing directory structure existing solely to keep a glob working is the clearest single instance of the class of problem this spec addresses.  
**Status**: Pending

### Write tests for Convert `archive`
**Task**: 2.3  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`, `[integration]`, or `[feature]`.  
**Status**: Pending

---

## Convert `clean`
**Story**: 3  
**Status**: Pending  
**Blocked by**: —  
**Satisfies**: FR25, FR11

**Acceptance Criteria**:

- A clean run selects stale `session` rows by age and removes them, with no filename stem to glob and no session-suffix convention to match [integration]
- must NOT — the skill recovers an entity by reading a generated markdown file rather than by calling a read tool [unit]

### Select stale `session` rows by age and remove them
**Task**: 3.1  
**Description**: Staleness is a `WHERE` clause. The exact-stem convention that every reader of the progress file must match today has nothing left to protect.  
**Status**: Pending

### Write tests for Convert `clean`
**Task**: 3.2  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`, `[integration]`, or `[feature]`.  
**Status**: Pending

---

## Convert `ralph`
**Story**: 4  
**Status**: Pending  
**Blocked by**: —  
**Satisfies**: FR25, FR11

**Acceptance Criteria**:

- A ralph run carries its loop state in `session` rows, and a resume under a new session id adopts the prior row rather than reading a progress file [feature]
- must NOT — the skill recovers an entity by reading a generated markdown file rather than by calling a read tool [unit]

### Carry loop state in `session` rows, with resume-adoption as an `UPDATE`
**Task**: 4.1  
**Description**: An autonomous loop is the case where progress-file recovery matters most and is least observable — nobody is watching when it fails to adopt.  
**Status**: Pending

### Write tests for Convert `ralph`
**Task**: 4.2  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`, `[integration]`, or `[feature]`.  
**Status**: Pending

---

## Close the corpus
**Story**: 5  
**Status**: Pending  
**Blocked by**: Story 1, Story 2, Story 3, Story 4  
**Satisfies**: FR25, FR3, FR28

**Acceptance Criteria**:

- The twenty-two skills named in FR25 all exist, and no skill exists that FR25 does not name [integration]
- No skill writes a literal artefact number into a prose column; a reference to another artefact is written `{{ref:<id>}}` — swept across all twenty-two [unit]
- Every pipeline stage a CPM user can reach has a dpm skill, asserted by comparing the corpus against CPM's own skill directory [integration]
- No skill file contains a filename pattern under `docs/`, a glob, a number-allocation procedure, or a progress-file lifecycle — swept across all twenty-two [unit]
- Every dpm SKILL.md contains no SQL keyword and no `sqlite3` invocation — swept across all twenty-two [unit]
- must NOT — a skill recovers an entity by reading a generated markdown file rather than by calling a read tool, swept across all twenty-two [unit]

### Enumerate the twenty-two skills against FR25's list in both directions
**Task**: 5.1  
**Description**: Both directions, because a corpus missing one skill and a corpus holding an unnamed twenty-third are different failures and a one-way check finds only the first.  
**Status**: Pending

### Compare the corpus against CPM's own skill directory
**Task**: 5.2  
**Description**: FR25's list could itself be short. Comparing against the directory is what makes "every pipeline stage a user can reach" checkable rather than a claim about the list.  
**Status**: Pending

### Sweep all twenty-two files for the five subtractions and for SQL
**Task**: 5.3  
**Description**: Each epic swept its own files; this sweeps the corpus, so a skill converted early and edited later is caught.  
**Status**: Pending

### Sweep the corpus for prose references written as numbers rather than as markers
**Task**: 5.4  
**Description**: FR28's write side. Epic 47-04 resolves markers at render time and forbids a projected body holding a number no row produced; nothing before this asserts that the skills *emit* markers. The failure is deferred and asymmetric — a skill that writes `spec 47` into a prose column ships clean and fails at someone else's render, months later, in a file it did not write. Every authoring skill is a candidate, so the check belongs to the corpus rather than to any one of them.  
**Status**: Pending

### Write tests for Close the corpus
**Task**: 5.5  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`, `[integration]`, or `[feature]`.  
**Status**: Pending

---

## Verify dpm holds its own planning corpus [plan]
**Story**: 6  
**Status**: Pending  
**Blocked by**: Story 5  
**Satisfies**: FR10, FR14, NFR6

**Acceptance Criteria**:

- Every artefact whose lineage roots at spec 47 loads through create tools, and the projection regenerates each of them — the spec, every review and retro sourced from it or from its epics, the nine epic documents, their nine coverage matrices, and every artifact registered against any of them. The set is derived by walking lineage, not enumerated here, so an artefact the corpus gains after this criterion was written is still covered [feature]
- The loaded corpus passes `PRAGMA foreign_key_check` and every entry in the invariant register [integration]
- Every entry in the self-hosting register is closed, or explicitly waived with a recorded reason; no entry remains OPEN [integration]
- must NOT — a corpus artefact loads with content dropped because no column held it, and the load reports success [integration]

### Derive the corpus from spec 47's lineage and load every member through create tools
**Task**: 6.1  
**Description**: Through the tools, not by import — AD8 means there is no import path, so this is a fixture written against the tool surface like every other. **Derive the membership, do not list it.** This criterion named "spec 47, review 04, retro 33, the nine epics and the nine coverage matrices" until review 05, and by then it was already short by three: retro 34, whose `**Source**` is spec 47 and which was written the same day; the schema-map artifact registered in the spec's own `**Artifacts**:` field (`docs/artifacts/47-dpm-schema-map.html`); and review 05 itself. The artifact omission had teeth beyond completeness — `artifact` and `artifact_document` are two of the twenty-three tables, and with no artifact in the corpus the check that gates the whole build never exercised either. A hand-kept enumeration needs editing every time the corpus grows, which is the failure this spec removes everywhere else by reading the set from the live schema; the same answer applies to the corpus itself.  
**Status**: Pending

### Regenerate the projection and compare it against what was loaded
**Task**: 6.2  
**Description**: This is the mechanism behind the story's final criterion. A load that drops what no column holds reports success; only comparing the regenerated projection against the source makes the loss visible.  
**Status**: Pending

### Run `PRAGMA foreign_key_check` and the full register sweep over the loaded corpus
**Task**: 6.3  
**Description**: The corpus is the largest realistic fixture available, and it was authored before the schema was, so it exercises shapes no test written alongside the schema would think to try.  
**Status**: Pending

### Resolve the self-hosting register
**Task**: 6.4  
**Description**: Every entry closed or waived with a recorded reason. A waiver is a decision and is written down; an entry left OPEN fails the story.  
**Status**: Pending

### Write tests for Verify dpm holds its own planning corpus
**Task**: 6.5  
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`, `[integration]`, or `[feature]`.  
**Status**: Pending

---

## Address review findings
**Story**: 7  
**Status**: Complete — applied by `/cpm:pivot` on 2026-08-08 from review 05  
**Blocked by**: —

**Acceptance Criteria**:

- Each critical and warning finding from review 05 scoped to this epic has been addressed
- Existing acceptance criteria on other stories continue to pass

### Fix: the self-hosting corpus enumeration is hand-kept and already incomplete
**Task**: 7.1  
**Description**: [warning] Story 6's first criterion names "Spec 47, review 04, retro 33, the nine epic documents and their nine coverage matrices". Two members of that corpus are missing: **retro 34**, whose `**Source**` is spec 47 and which was written the same day, and the **schema-map artifact** registered in the spec's own `**Artifacts**:` field (source `docs/artifacts/47-dpm-schema-map.html`). The artifact omission has teeth beyond completeness — `artifact` and `artifact_document` are two of the twenty-three tables, and with no artifact in the corpus the standing check that gates the whole build never exercises either. Review 05 is a further member. The list is also the wrong shape for the job: it needs editing every time the corpus gains a member, which is the hand-kept-enumeration failure the spec removes everywhere else by reading the set from the live schema. Prefer deriving the corpus — every artefact whose lineage roots at spec 47 — over naming it.  
**Status**: Complete — Story 6's criterion, Task 6.1 and matrix row 16 now derive membership by lineage

---

## Notes

### Self-hosting register — this epic is where it must be empty

The register lives in Epic 47-01's Notes. It held five OPEN entries when this epic was
written; the pivot of 2026-08-08 closed all five. Story 6's third criterion requires every one
closed or explicitly waived, which is why this epic is last and why Story 6 is blocked by
Story 5 rather than running alongside it. **The criterion is not thereby satisfied** — it
asserts the register is empty at the end of the build, and later epics may add to it.

None of the five was fixable in this epic: every one needed a **spec** change, and those
changes went through `/cpm:pivot` after the breakdown, not during it. What this epic owns is
the check, not the repair:

| # | Bears on | Where it surfaces here | Closed by |
|---|---|---|---|
| 1 | Partial coverage indistinguishable from full | FR25 is covered across four matrices and complete in none; Story 5's enumeration is the closest thing to a fix without a schema change | FR26 — completeness is a claim on the requirement, decayed by four triggers |
| 2 | AD6's milestones have no table | This epic is M4, as are 47-06 through 47-08; nothing recorded that | FR27 — `milestone` rows and the `document_milestone` join |
| 3 | Inline ADs in a spec degrade to prose | Story 6 loads spec 47, which carries ten of them | `document_kind.dir` nullable — `adr` renders inside its parent and keeps its child tables |
| 4 | `retro→spec` parentage is unseeded | Story 6 loads retro 33, whose `**Source**` is a spec | Seeding widened to `retro→epic, spec or quick` |
| 5 | Body-prose references cannot be rewritten | Story 6 loads epics whose Notes name other epics by number | FR28 — `{{ref:<id>}}` markers resolved at render time |

**Entries 3, 4 and 5 were all exercised by Story 6's first criterion**, and each would have
failed it. That was the intended behaviour: the story is the check, and a failing check before
the pivot is the check working. It should now pass — which is a prediction this story exists
to test, not a result.

### Requirements only partially covered by this epic

**FR25** — four of twenty-two skills in Stories 1–4; **complete** in Story 5, which is where
FR25's corpus-wide criteria are asserted and where FR25 stops being partially covered for the
first time since Epic 47-06. **FR3** — same shape: the skill-corpus half completes here.
