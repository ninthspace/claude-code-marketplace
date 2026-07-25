# Skill Assembly and Artifact

**Source spec**: docs/specifications/42-spec-change-set-review.md
**Date**: 2026-07-25
**Status**: Complete
**Blocked by**: Epic 42-01-epic-change-set-resolution, Epic 42-02-epic-intent-adapters-and-join, Epic 42-03-epic-gap-queries, Epic 42-04-epic-change-set-review
**Retro applied**: 16 · Criteria Gaps · Applied — Story 2's backlink criterion is checked against `/cpm:inspect`'s actual shape *before* the story starts, not discovered mid-execution as retro 16's two instances were. Its source artifact is the JSON record, whose byte-determinism (R6) and frozen schema (`cpm.inspect/1`) both collide with writing a backlink into it; the resolution is recorded as a Story 2 decision.
**Retro applied**: 15 · Patterns Worth Reusing · Applied — Story 1 is prose end to end, so the new `SKILL.md` and both amended `description` fields are read in place at the gate. Structural assertions can say a section exists, never that what it claims is still true.
**Retro applied**: 17 · Criteria Gaps · Applied — the description criteria are scoped to the two skills this story owns rather than expressed as a sweep over `cpm/`, which would also match this epic's own planning documents quoting them. "must NOT modify `/cpm:audit`" is a before-and-after content comparison, not a grep that happens to find nothing.
**Retro applied**: 19 · Testing Gaps · Applied — nothing pinned: no version literal, no skill count, no hard-coded selector list. Values the manifest or the skill files already state are read at run time and used as the expected value.

## Assemble the /cpm:inspect skill [plan]
**Story**: 1
**Status**: Complete
**Blocked by**: —
**Satisfies**: AD1
**Decision**: the **dispatcher is code, not prose**. AD5's resolution order had never been written down anywhere executable — Epic 42-01 built both traversals and nothing chose between them — so "assembles the pieces" had to include `cpm/hooks/lib/inspect-resolve.sh`. Left in the SKILL.md it would have been a criterion satisfiable by a grep for four selector names, and the ordering the tool used and the ordering the skill documented could drift without either being wrong on its own.
**Decision**: the ambiguous bare token resolves **toward the branch**. `show-ref` either finds it or it does not, whereas "some adapter might understand this string" cannot be checked without running every adapter and cannot be un-made once one answers. CPM ids carry a space and never reach the rule; it decides for issue keys like `AUTH-4`.
**Inline change**: `cpm/README.md`'s skills file tree gained an `inspect/` row — caught by `test-docs-artifact-pivot.sh`, which derives the expected tree from disk rather than pinning it (2026-07-25)
**Retro**: [Criteria gap] Planning this story found that R1's intent half has no production adapter and never did: `changeset_resolve_intent` and the `<name>_intent_commits` contract have only ever been exercised by `stub-intent-adapter.sh`, and 42-01's coverage rows 5–7 are stub-verified. Three epic gates passed over it because each verified its own layer, and this epic's own coverage note asserted "real adapters arriving in 42-02" as a forward-looking assumption that nothing ever re-checked — 42-02 built the *link* adapters, which run the opposite direction. A criterion satisfied by a stub and one satisfied by a registered channel read identically in a matrix, and the difference is the whole feature. Recorded as Story 4 rather than an inline change, so the adapter arrives with criteria of its own.

**Acceptance Criteria**:

- The skill accepts every selector form from R1 and dispatches to the resolution built in Epic 42-01 [integration]
- Its `description` leads with its subject — code, after execution [integration]
- `/cpm:review`'s `description` leads with its subject — plans, before execution [integration]
- must NOT require CPM artifacts in the target repository [integration]
- must NOT modify `/cpm:audit` [integration]

**Note**: `[plan]` because this story fixes the skill's public surface — its input vocabulary, its run sequence, and its degradation paths — which is the contract every future change to the tool works within.

**Note on the first criterion**: it says *dispatches*, and that is what is verified. Every R1 selector form reaches the correct resolver, asserted as direction and change set together. The intent form's resolution behind that dispatch is stub-backed until Story 4, so this row records that the routing is right — not that this repository can answer `epic 41-03`.

### Write the SKILL.md
**Task**: 1.1
**Description**: Input parsing, the run sequence, degradation paths, and output shape. Assembles the pieces built across Epics 42-01 to 42-04 into one invocable skill.
**Status**: Complete

### Amend both description fields
**Task**: 1.2
**Description**: The naming-collision fix AD1 requires. `review` and `inspect` become distinguishable by subject rather than by verb — the concern raised during architecture, where two similarly-named skills reviewing different things is a trap users fall into permanently.
**Status**: Complete

### Write tests for skill assembly
**Task**: 1.3
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`, `[integration]`, or `[feature]`.
**Status**: Complete

---

## Publish and register the artifact
**Story**: 2
**Status**: Complete
**Blocked by**: Story 1
**Satisfies**: R8, AD4
**Decision**: the `**Artifacts**:` backlink lives in a **sidecar**, `docs/inspect/<slug>.artifacts.md`, not in the record. This is the collision the epic's retro-16 breadcrumb gated before the story started, and it was real: R6 requires the record to be byte-identical across runs of the same selector and a published URL is not, so writing one in would make two runs differ for a reason unrelated to the work — and that diff is what one-file-per-selector exists to produce. The alternatives were a register row alone (which would have meant rewriting the criterion, and the existing no-backlink precedent rests on "no single source", which does not apply here) and writing into the inspected epic docs (which does nothing in a repository with no epic docs — the case AD1 requires the skill to handle).
**Decision**: nothing here emits HTML. The shared **Artifact Publishing** convention composes pages through `artifact-design`, so `inspect_projection` produces the **complete set of facts the page may state** and the page is composed from that. It makes AD4 checkable rather than merely stated: the projection opens the record and never the repository, so "must NOT embed source content" is asserted one level below the page, where it is falsifiable. A page is not a testable unit — one could always be written that happened not to quote a file.
**Retro**: [Scope surprise] A consequence nobody had written down: the record's schema carries provenance and not review commentary, so a page projected from it **cannot show the findings**. That falls straight out of AD4 plus the frozen `cpm.inspect/1` schema, and it means the artifact for a *change-set review* shows orphans and links rather than what the review concluded. It is defensible — the provenance view is the thing no diff can render, which is what earned the artifact its place in the spec — but it was discovered while writing the publishing section rather than decided, and a reader offered "publish this" would reasonably expect otherwise. The SKILL.md now says so at the point of offering.

**Acceptance Criteria**:

- The published artifact registers a row in `docs/artifacts/index.md` and records an `**Artifacts**:` backlink [integration]
- The page is projected from the JSON record, and re-publishing the same run redeploys to the same URL [integration]
- must NOT embed source content in the published page [integration]
- The run does not fail when the Artifact tool is unavailable [integration]

### Build the artifact projection over the JSON
**Task**: 2.1
**Description**: Reads the record from `docs/inspect/`. The page is disposable and the JSON stays the record — per AD4, putting the only copy of provenance data inside a published page would place a record somewhere `grep` cannot reach.
**Status**: Complete

### Wire registration and the backlink
**Task**: 2.2
**Description**: The existing `cpm:artifact` invariant, applied unchanged — a register row plus an `**Artifacts**:` field on the source. No change to `cpm:artifact` itself.
**Status**: Complete

### Write tests for publishing and registration
**Task**: 2.3
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`, `[integration]`, or `[feature]`.
**Status**: Complete

---

## Verify the end-to-end pipeline
**Story**: 3
**Status**: Complete
**Blocked by**: Story 1, Story 2
**Satisfies**: R9 (completion of Epic 42-03's deferred verification)
**Decision**: "a single invocation" is a **function**, `inspect_run` in `cpm/hooks/lib/inspect-run.sh`, not six steps of prose. The criterion says *in one pass*, and with no entry point a test could only assert that six libraries compose when called in the right order by the test itself — which is a claim about the test. Everything except R5's findings is deterministic, so sequencing it in code leaves the SKILL.md describing what the run did and what its output means, and Step 4 as the only part that is genuinely the model's. The record is written **last**, so a run that fails part-way leaves nothing behind claiming to describe it.
**Inline change**: `cpm/skills/inspect/SKILL.md`'s Process was rewired from six invocations to one call plus five sections of interpretation (2026-07-25)
**Retro**: [Testing gap] Three of the four mutations run against this story's suite were caught; the one that survived was the one that mattered most — moving the record write to the *front* of the pipeline changed nothing, because every failure the suite exercised happened during resolution, before either write position. "A run that fails leaves no record" was being asserted by tests that could not tell the two orderings apart. Closing it needed a failure in the narrow window between them: a selector that resolves and then dies in the review selection. The general shape is worth keeping — an ordering claim needs a failure that falls *between* the orderings, and error cases chosen for being easy to trigger cluster at the start of a pipeline where they discriminate least.
**Acceptance Criteria**:

- A single invocation resolves a selector, runs the join, answers both gap queries, produces findings, and emits JSON — in one pass [integration]
- The same invocation in a repository with no intent sources completes with every file an orphan and a review still produced [integration]

**Note**: this story is where Epic 42-03's coverage row 5 finally becomes fully verifiable. That row's criterion — "a repository with no CPM artifacts and no trailers still produces a review" — needs the review to exist, which it does not when 42-03 is executed. Until this story runs, row 5 is verifiable only as far as "the run completes and every file is an orphan".

**Note on ordering**: this story's end-to-end run precedes Story 4, so its "single invocation" criterion is exercised over a git-anchored selector only. The intent-anchored path has no production channel until Story 4 registers one, and running it here would test the stub. Story 4's criteria carry the intent-anchored half of the same pipeline.

### Write end-to-end integration tests
**Task**: 3.1
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`, `[integration]`, or `[feature]`.
**Status**: Complete

---

## Resolve CPM intent-anchored selectors forward
**Story**: 4
**Status**: Complete
**Blocked by**: Story 1
**Satisfies**: R1 (intent-anchored half, production channel), R2 (forward direction)
**Decision**: a **story resolves from commit messages only** — it never inherits its epic's document commits. Touching `docs/epics/42-05-epic-*.md` says the *epic* moved; which story it moved is in the diff, not the path. A fallback would return the whole epic's change set under a story selector, which reads as a successful resolution and is the "plausible-looking lie" `changeset-intent.sh` already names. Finding nothing is the honest answer, and R1's empty-match error carries it — no second must-NOT site was needed.
**Decision**: **spec-level selectors are declined, not invented.** `epic 42` means the flat legacy epic 42, never "every epic in spec 42's chain" — the flat and two-part filename shapes coexist permanently, so a spec reading would make the same selector mean different things depending on which files happen to exist. Exit 2 covers it, along with issue keys like `AUTH-4`, whose adapters the spec defers.
**Decision**: `inspect_run` carries **two registries**, `INSPECT_LINK_ADAPTERS` and `INSPECT_INTENT_ADAPTERS`, and registers the intent ones *before* resolution and the link ones after. Not a style choice: registering an intent adapter must not be able to change what `--since HEAD~2` resolves to, and separating the two points in the sequence is what makes that structural rather than promised.
**Inline change**: `/cpm:inspect`'s Degradation table gained two rows beyond the one the task named — a selector no intent adapter *recognises* (declined) and a CPM selector nothing in the repository *names* (answered, empty). Both error identically at the resolver, and without the split the skill would report a missing channel for what is actually an answer (2026-07-25)
**Retro**: [Codebase discovery] Run against this repository, `epic 41-05` resolves to **one** commit — spec 41's chain was committed under subjects like "Spec 41: pivot CPM's HTML story…", which name the spec and the version and not the epic id. The document channel carries almost the whole answer here, and the message channel, which is the only channel a *story* has, is nearly empty. The adapter is behaving correctly against what the repository records; the reach of forward resolution is a property of commit-message convention, not of the tool. Worth knowing before `/cpm:inspect epic NN-MM` is offered as the primary entry point — and it is the same gap the orphan query surfaces from the other end.
**Retro**: [Testing gap] Two of the six mutations run against this story's suite produced files that were not valid bash, and both reported ~21 failures — a "caught" result that was really a syntax error. The earlier lesson was *verify the mutation applied*; a `diff -q` guard satisfies that and still passes a broken mutant. The guard that actually works is `bash -n` on the mutant before running the suite: a mutation has to be both **applied** and **loadable** before its result means anything, and a mutant that fails everything is the signature of the second condition being unmet.

**Acceptance Criteria**:

- `epic NN-MM` and `story NN-MM.K` each resolve to the commits that produced them, through an adapter registered by `/cpm:inspect` rather than a test stub [integration]
- The commits an intent-anchored selector resolves to yield the same file set as a git-anchored selector over those same commits [integration]
- must NOT silently return an empty change set when a selector matches nothing — it errors with the selector echoed back [integration]
- must NOT require the selector's intent record to exist in the repository being inspected for a *git-anchored* run to work [integration]

**Note**: this story exists because planning Story 1 found that R1's intent half has no production adapter. `changeset_resolve_intent` and the `<name>_intent_commits` contract were built in Epic 42-01 Story 3 and verified against `cpm/hooks/tests/stub-intent-adapter.sh`; the spec's In-Scope list names the git-native and CPM **link** adapters, which resolve the reverse direction (files → intent), and never schedules a forward one. Epic 42-01's coverage rows 5–7 are therefore verified against a stub, and `/cpm:inspect epic 41-03` — the spec's own worked example — cannot resolve until this story lands.

It is a separate story rather than an inline change to Story 1 so the adapter arrives with acceptance criteria and coverage rows of its own, which is what the stub-verified rows lacked.

### Write tests for forward CPM intent resolution
**Task**: 4.1
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`, `[integration]`, or `[feature]`. Placed first so the production adapter is written against the same contract the stub already exercises, rather than against itself.
**Status**: Complete

### Implement the CPM intent adapter
**Task**: 4.2
**Description**: `cpm_intent_commits` over the channels the CPM link adapter already reads in reverse — the epic doc and coverage matrix for the id, and commits whose message names it. Scope is the CPM channel only; issue-tracker adapters stay deferred per the spec.
**Status**: Complete

### Register the adapter in the run sequence
**Task**: 4.3
**Description**: The one-line change in `/cpm:inspect`'s resolve step, plus the degradation text that stops claiming no channel is registered.
**Status**: Complete

---
