# Review: dpm — SQLite-Backed Artefact Persistence (nine 47-series epics)

**Date**: 2026-08-08  
**Source**: docs/epics/47-01-epic-substrate.md … docs/epics/47-09-epic-skills-lifecycle.md  
**Scope**: Epic — all nine 47-series epics and their nine coverage matrices  
**Agents**: Margot (Architect), Bella (Senior Developer), Tomas (QA Engineer), Jordan (Product Manager)  
**Findings**: 12 (3 critical, 6 warnings, 3 suggestions)

## Summary

Nine epics, 57 stories, 229 acceptance criteria and 241 coverage rows, reviewed against spec
47 and its 130 tagged criteria. The breakdown is in good order: dependencies resolve at both
levels with no cycles, no verification mark is set prematurely, the skill corpus reconciles to
FR25's twenty-two exactly, and the epic-to-matrix set comparison is clean in both directions
apart from one roll-up the matrix notes declare precisely as retro 34 recommended. Retro 34's
FR28 producer/consumer lesson was applied — 47-09 Task 5.4 sweeps the authoring skills for the
marker write side that the original cascade missed.

The three criticals are all traceability failures rather than design failures, and each was
found by running a check rather than reading: one spec criterion covered by no story
(FR26's), one pair of acceptance criteria in the same epic that cannot both pass (47-03), and
one coverage row bound to a story that does not exist (47-02). The design itself holds up
under all four lenses. **The artefacts are ready for execution once the criticals are closed**;
the warnings are cross-reference and sizing risks that will cost time rather than correctness.

One pattern runs through the warnings and is worth naming on its own: every restated fact in
this corpus that is not derived has drifted — five spec line-references, one entity-type
count, one story reference, one hand-kept corpus list. That is retro 33's "count in code,
quote in prose" recommendation returning for a third session, now generalised past counts to
references of every kind.

## Findings

### Spec Compliance

- **[Critical]** 📋 **Jordan**: FR26's must-NOT criterion is carried by no story in any of the  
  nine epics, while the matrix that should hold it asserts the requirement is fully covered.  
  → Spec:1311 — *"must NOT — completeness is derived from fragment offsets rather than  
  claimed, so connective prose must be bound to satisfy it."* The words `offset` and  
  `connective` appear nowhere in `docs/epics/`, and no matrix row cites this criterion.  
  47-01's matrix note (:129) states **"FR26 is complete here."** This is retro 34's FR21  
  omission recurring one requirement over, and the irony is load-bearing rather than  
  decorative: FR26 exists precisely to stop a partially-bound requirement reading as covered,  
  and it is itself a partially-covered requirement reading as covered. The practical cost is  
  that an implementer may derive completeness from fragment offsets, pass the other six FR26  
  criteria and both control cases, and reintroduce the alternative the Data Model (:679–688)  
  spends a paragraph rejecting — with nothing in the suite failing.

- **[Suggestion]** 🔍 **Tomas**: The matrix column named "Spec Test Approach" carries the  
  epic's tag rather than the spec's, in one row of 241.  
  → 47-09 coverage row 11 reads `[integration]`; spec:1263 tags that same criterion `[unit]`,  
  and 47-09 Story 5 (:129) also says `[integration]`. The rate is one in 241, so the  
  discipline is sound — but the column's name asserts a provenance it does not have, and a  
  reader using it to check the epic against the spec is checking the epic against itself.

### Unclear Requirements

- **[Critical]** 💻 **Bella**: Two acceptance criteria in Epic 47-03 cannot both pass, and the  
  stricter one also exceeds the spec.  
  → 47-03 Story 5 (:150) requires that "every table in `sqlite_master` is reachable through  
  **at least one** read tool"; Story 8 (:238) requires that "every table appears in **exactly  
  one** tool's declared coverage". `document` is read by the read tool of every one of the  
  thirteen kinds, and `taxonomy` by `finding`, `observation` and `audit_finding` — so  
  exactly-one is not merely stricter, it is unsatisfiable against this schema. NFR7  
  (spec:1383) says at-least-one, so Story 8 also invents an obligation the spec does not  
  carry. Neither criterion is wrong read alone, which is exactly the reading retro 33 warned  
  is the one that cannot find this.

- **[Warning]** 📝 The count of entity types remaining after the spine is stated as two  
  different numbers in two epics.  
  → 47-03 says "the remaining **fifteen** are Epic 47-05" (:276) and "47-05 the remaining  
  fifteen types" (:254); 47-05 titles its Story 1 "Give the remaining **sixteen** entity  
  types…" (:13, :54). 47-05's notes (:211–221) concede the count "does not resolve cleanly"  
  and route around it by reading the enumeration from the live schema, which is the right  
  answer — but 47-03's two statements are unqualified and point the other way. Reconciling  
  them requires finding 47-03's FR11 placement note (:266), which is what makes the two  
  numbers consistent. That is a derivation held in a third location and stated in neither.

- **[Warning]** 💻 **Bella**: A task description sends the implementer to the wrong story for  
  the criterion that justifies its own design note.  
  → 47-01 Task 5.1 (:189) says the migration runner "is a second path to the same schema as  
  the DDL, which is what **Story 7's** first criterion exists to catch". Story 7's first  
  criterion (:243) is about editing a story criterion's text clearing verification. The  
  DDL-versus-migration parity criterion is **Story 8's** (:296). The note is correct about the  
  risk and wrong about where it is closed.

- **[Suggestion]** 📝 A structured field carries a prose tail.  
  → 47-09 Story 6 (:167) reads `**Satisfies**: FR10, FR14, NFR6, and the self-hosting check`.  
  Every other `Satisfies` across the nine epics is a clean comma-separated label list, so any  
  reader splitting on commas gets a bogus fourth label here. Spec 47's own  
  constraint-to-drift table lists "status carrying an unparseable free-text qualifier" as a  
  drift class it ends with `status` + `status_note`; this is the same shape in the  
  breakdown's metadata.

### Testability Concerns

- **[Critical]** 🔍 **Tomas**: A coverage row is bound to a story that does not exist, and its  
  mapping note repeats the error.  
  → 47-02 coverage matrix row 12 (:22) names **Story 4** under `Covered by`. Epic 47-02 has  
  three stories; the criterion — "A dump taken before and after a no-op read produces  
  identical bytes" — sits on **Story 3** (:94). The matrix's own note (:30–34) says "the  
  criterion was already on Story 4", so the error is recorded twice and self-corroborating.  
  A row that cannot resolve to a story is retro 34's "coverage row naming a criterion that  
  does not exist" with the column changed: it will either break a roll-up or be silently  
  dropped from one, and a dropped row lowers the denominator rather than raising an error.

- **[Suggestion]** The "Story Criterion (verbatim)" column is not byte-verbatim when a  
  criterion contains a pipe.  
  → 47-09 coverage row 2 escapes the epic's `| ✓ |` as `\| ✓ \|`, which markdown table syntax  
  requires. Recording it matters because the both-directions set comparison retro 34  
  recommends institutionalising reports this row as divergent on every run. The check needs  
  to unescape before comparing; the risk otherwise is that someone closes the false positive  
  by editing the criterion.

### Architectural Risks

- **[Warning]** 🏗️ **Margot**: Five references from the epics into the spec by line number are  
  stale, four of them by the same offset.  
  → `§195` and `§202` (47-04:210, :211, :215), `§201` (47-04 coverage:40), `§332`  
  (47-05:216), `§1234` (47-01 coverage:114). None resolves to the passage it quotes: the  
  actual locations are 205, 212, 211, 345 and 1440. Four are off by exactly **+10** — the  
  number of lines the spec gained when the pivot inserted FR26, FR27 and FR28 above them —  
  and the fifth by 206. The references were correct when written and were invalidated by an  
  amendment to the document they point into, within the same session. Two of the five sit in  
  the Notes of Epic 47-04, which is the passage explaining why FR28 makes a prose reference a  
  marker rather than a number, on the grounds that a stored number "would go stale the moment  
  a merge renumbered its target, and no tool could find it to repair". The breakdown proves  
  its own requirement against itself. Practically: these are the citations an implementer  
  follows to recover the rationale for a decision, and each lands on blank space or the wrong  
  paragraph.

- **[Warning]** 📋 **Jordan**: The self-hosting corpus — the standing acceptance gate for the  
  entire build — is enumerated by hand and is already incomplete.  
  → 47-09 Story 6 (:171) names "Spec 47, review 04, retro 33, the nine epic documents and  
  their nine coverage matrices". Two members of that corpus are missing: **retro 34**, whose  
  `**Source**` is spec 47 and which was written the same day, and the **schema-map artifact**  
  registered in the spec's own `**Artifacts**:` field (spec:5, source  
  `docs/artifacts/47-dpm-schema-map.html`). The artifact omission has teeth beyond  
  completeness — `artifact` and `artifact_document` are two of the twenty-three entity types  
  and two of the schema's three standalone-table concerns, and with no artifact in the corpus  
  the check that is meant to prove dpm can hold its own planning history never exercises  
  either. The list is also the wrong shape for the job: it will need editing every time the  
  corpus gains a member, which is the hand-kept-enumeration failure the spec removes  
  everywhere else by reading the set from the live schema.

### Dependency Risks

- **[Warning]** 🏗️ **Margot**: The declared blocker inverts the milestone order, because  
  `Blocked by` is expressed per epic and one epic spans two milestones.  
  → 47-05 is M3 and declares `**Blocked by**: … Epic 47-04-epic-projection-guard-and-merge`.  
  47-04 spans **M2 and M4** — its merge tool is M4 work. Followed literally, M3 cannot start  
  until M4's merge tool is complete, which reverses AD6's build order for a third of the  
  build. 47-05's note (:8–11) states the real dependency is narrow — Story 2's projection  
  assertion and Story 6's parity closure, both against 47-04's M2 half — but nothing  
  machine-readable records that, and `cpm:do`'s readiness pass reads the field, not the note.  
  The irony is available here too: FR22 exists to make blocking a typed edge whose source and  
  target "may each be a document or a story", and this is the case that needs it.

### Hidden Complexity

- **[Warning]** 💻 **Bella**: 47-01 Story 1 is the root of the entire dependency graph and is  
  sized as one story.  
  → It carries **17 acceptance criteria** against FR1, FR2, FR27, AD7, AD9 and NFR6 — the  
  whole 38-table schema — in four implementation tasks plus one test task. Task 1.2 alone is  
  "the nine per-kind detail tables and fourteen child tables with kind-pinned composite FKs".  
  It blocks six of its epic's seven other stories, and 47-02 and 47-03 block on the epic, so  
  four further epics wait behind it transitively. Nothing partial can land and no criterion  
  can be verified until most of the schema exists. Splitting it — identity and numbering,  
  then delivery and coverage, then the remaining detail tables — would let the criteria close  
  in groups; the composite `(id, kind)` parent key from Task 1.1 is the only genuine  
  serialisation point.

## Remediation

**Path**: Epic amendment, applied per epic  
**Target**: the six epics that carry a critical or warning finding  
**Stories**: 47-01 Story 9, 47-02 Story 4, 47-03 Story 9, 47-04 Story 6, 47-05 Story 7,
47-09 Story 7 — each titled "Address review findings"

A single remediation story was not appropriate here: the findings span six epics, and a fix
detached from the epic whose criteria it repairs is a fix `cpm:do` reaches in the wrong
order. Each story is inserted before its epic's `## Notes` section so the trailing structure
holds. The three suggestions generated no tasks, as designed.

| # | Finding | Severity | Task |
|---|---------|----------|------|
| 1 | FR26's must-NOT criterion is carried by no story in any epic | critical | 47-01 · 9.1 |
| 2 | 47-03 Stories 5 and 8 state reachability requirements that cannot both pass | critical | 47-03 · 9.1 |
| 3 | 47-02 coverage row 12 is bound to a story that does not exist | critical | 47-02 · 4.1 |
| 4 | `§195`, `§201`, `§202` resolve to the wrong passages | warning | 47-04 · 6.1 |
| 5 | `§1234` resolves to the wrong passage | warning | 47-01 · 9.3 |
| 6 | `§332` resolves to the wrong passage | warning | 47-05 · 7.2 |
| 7 | "the remaining fifteen" vs "the remaining sixteen" | warning | 47-03 · 9.2 |
| 8 | Task 5.1 cites Story 7's first criterion, which is Story 8's | warning | 47-01 · 9.2 |
| 9 | The self-hosting corpus enumeration is hand-kept and already incomplete | warning | 47-09 · 7.1 |
| 10 | The epic-level blocker inverts the milestone order | warning | 47-05 · 7.1 |
| 11 | 47-01 Story 1 is the graph root and is sized as one story | warning | 47-01 · 9.4 |

Eleven tasks from nine findings: the stale-reference finding splits across the three epics
that carry an instance, since each is repaired in its own file.

**One thing to watch when applying these.** Epic 47-02's remediation story is numbered 4,
and the defect it repairs is a coverage row citing a Story 4 that did not exist. The epic now
has one. Task 4.1 says so explicitly, but the correct fix is still to repoint row 12 at
Story 3 — not to let the new numbering make a stale citation resolve by accident.
