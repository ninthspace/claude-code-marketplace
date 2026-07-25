# Spec: Change-Set Review and Provenance

**Date**: 2026-07-25
**Brief**: —  (facilitated from a conversation following spec 41's completion)

## Problem Summary

No skill reviews the code an epic produced. `/cpm:review` critiques epic docs and stories *before* execution and never reads the implementation. `/cpm:do` verifies acceptance criteria, which is conformance to the plan rather than a judgement about the code — a criterion passes over duplicated or badly-factored work. `/cpm:audit` is the only skill that reads code and cites `file:line (symbol)`, but it scopes by path and orients on whole-codebase signals, so it cannot answer *"review what this change produced"*; run per-epic it re-audits untouched code and drowns the real findings.

The second half of the problem is that a review of a change set is much more useful when it knows **why** each file changed. Every codebase records intent somehow — commit trailers, issue references, branch names, design docs, CPM epic docs — but nothing joins that record to the diff. The join is what makes two questions answerable that neither a diff nor a planning document can answer alone: which changed files trace back to no intent at all, and which intent records claim to be done with nothing testing them.

## Functional Requirements

### Must Have

Scope was cut hard at the boundary (issue-tracker adapters deferred, `audit` untouched, `review`'s schema frozen), so what remains is the minimum coherent tool and all of it is required. There are deliberately no Should-have entries.

- **R1 — Dual scope resolution.** Accept an **intent-anchored** selector (a ticket, an issue, a CPM spec/epic/story — e.g. `epic 41-03`, `story 41-03.2`) *or* a **git-anchored** selector (`--since <ref>`, a commit range, a branch, the working tree). Both resolve to one change-set structure: a set of commits and a set of files.
- **R2 — Bidirectional provenance resolution.** Intent-anchored selectors resolve **forward** (intent → files). Git-anchored selectors resolve **reverse** (files → intent). One join, two entry points.
- **R3 — Orphan changes.** Report files in the change set that no adapter can link to any intent record. This is where unreviewed scope creep hides.
- **R4 — Unbacked claims.** Report intent records marked done or verified with no test naming them. This is the inverse gap, and the one `/cpm:do` structurally cannot catch because it self-assesses.
- **R5 — Code review of the change set.** Produce findings with `file:line` citations. Without this the tool is a provenance report rather than a review, and its artifact would be a window onto a process that does not exist.
- **R6 — JSON record in the repository.** The join emits a deterministic JSON document, committed alongside the work, which is the record. Diffable and greppable.
- **R7 — Pluggable intent adapters with confidence labelling.** The join reads every intent channel present and **owns none of them**. Each resolved link is labelled:
  - **declared** — an explicit marker names the intent record
  - **derived** — inferred, principally from co-commit
  - **absent** — no adapter resolves it; the file is an orphan

  The join must produce a usable result with **zero** cooperating channels.

- **R8 — Artifact projection.** Publish a page projected from the JSON, registered in `docs/artifacts/index.md` with a backlink per `cpm:artifact`. The page is disposable; the JSON is the record.
- **R9 — Graceful degradation.** In a repository with no recognised intent source, the review still runs and every file is reported as an orphan. Absence of provenance is never a failure.

### Could Have

- Delta between two runs of the same selector — which dimensions worsened while shipping.

### Won't Have (this iteration)

- Issue and PR reference resolution (`#42`, `AUTH-123` lookups). Resolving what a reference *means* generally requires network access, which the Offline Integrity requirement forbids.
- Any change to `/cpm:audit`.
- Any change to `/cpm:review`'s **document schema**. Its one-line `description` is amended; the schema is not.
- Any change to `cpm:do`'s version-control stance.
- Back-filling provenance into completed work.

## Non-Functional Requirements

### Determinism

The join is deterministic: the same repository state and the same selector produce byte-identical JSON. This is what makes the record auditable and the run-to-run delta meaningful, and it is why the join must be a script rather than a model — a generated join cannot be trusted as a record of what was traced.

### Behaviour at Scale

A change set may be one file or an entire branch. The review half (R5) is model-driven and therefore bounded. When the change set exceeds what can be reviewed in one pass, the tool reviews what fits — prioritised by provenance signal, orphans first — and **prints an explicit list of the files it did not examine**. A review that silently samples reads as "clean" when it means "unexamined", which is worse than refusing.

### Offline Integrity

The join, the review and the JSON emission use only local git and local files. Only R8's publish step touches the network, and its absence must not fail the run.

### Confidence Integrity

A **derived** link is never presented as **declared**. The value of the confidence model is that a reviewer can distinguish *definitely unplanned* from *we could not tell*; overstating a single link poisons the orphan list, which is the output people act on.

### Publishing Hygiene

A published artifact carries paths, counts and metadata — **never source content**. The join sees the whole diff; the hosted page is a different trust boundary.

## Architecture Decisions

### AD1 — A new skill; `audit` unchanged

**Choice**: Change-set review ships as a new skill (`/cpm:inspect`), sitting between `do` and `retro`. `/cpm:audit` is not modified. The new skill ships in the CPM plugin but **must not require CPM artifacts in the target repository**.

**Rationale**: `audit`'s Step 1 Orient runs five whole-codebase signals — `git log --oneline -200`, `git log --stat --since="6 months ago"`, top-20-largest, top-20-most-modified, and their intersection — plus `git rev-parse HEAD`. A change-set scope does not filter these; it replaces them. Bolting change-set mode onto `audit` means one skill with two incompatible orient phases, and a nine-dimension health sweep is the wrong shape for a five-file change set. The two also run at different cadences: `audit` per release, `inspect` per change.

**Consequence**: the plugin will carry `review` (plans, before execution) and `inspect` (code, after execution). This is a naming collision users can fall into permanently, so **both skills' `description` fields must lead with their subject, not their verb**.

**Alternatives considered**: extending `audit` with a mode flag (fewer skills to learn, but orient must branch and the sweep shape is wrong); splitting into a deterministic join tool plus a thin review skill (cleanest separation, most moving parts — the join becomes a candidate for extraction later if `status` or `present` want it).

### AD2 — Pluggable intent adapters with a git-native baseline

**Choice**: The join resolves intent through adapters against a common contract. The **baseline adapter is git-native** — commit trailers, conventional-commit subjects, and branch names — and works in any repository with no configuration. **CPM is one adapter among several**, not the substrate.

This iteration ships:

| Adapter | Signals |
|---|---|
| git-native | commit trailers (`Refs:`, `Closes:`), conventional-commit subjects (`fix(scope):`), branch names (`feature/AUTH-123`) |
| CPM | epic docs, `**Satisfies**` fields, coverage matrices, co-commit |

**Rationale**: "planning artifact" is a *role*, not a file type. CPM epic docs are one implementation of it; Jira tickets, GitHub issues, ADRs and in-repo design docs are others. Designing against CPM's shapes would over-fit the tool to the repository it happens to be specified in. Both gap queries generalise without modification — an orphan is a file with no traceable intent whatever the source, and an unbacked claim is a record marked done with no test, as true of a ticket as of a CPM criterion.

**Derivation**: **co-commit is the strongest derived signal** — a commit carrying both a change and a reference to intent links them. For the CPM adapter this works precisely because CPM updates planning documents in the same working tree as the code, so they land in the same commit. Path mentions in intent-record prose are a weaker second signal.

**Time-window derivation is explicitly rejected.** Inferring a link from a commit falling inside an intent record's active window does not survive contact with reality: every epic, every verification block and every commit in spec 41's five-epic chain carries the same date, because `cpm:do` executes a whole chain in one sitting. That is the normal case, not an anomaly.

**Consequence**: derived resolution is **bounded by commit granularity**. Spec 41 landed as one commit containing all five epics and all 55 files, so co-commit yields chain-level provenance there, not epic-level; committing per story yields story-level. This is stated as a consequence, not imposed as a cadence rule.

**Alternatives considered**: `cpm:do` stamping provenance into the epic doc as it works (rejected — it only ever covers code `do` wrote, missing `/cpm:quick`, `ralph`, hand-written code, anything predating CPM, and the common case of a human taking over mid-epic); commit trailers written by CPM (rejected — `cpm/skills/do/SKILL.md:471` states "Version control stays with the user. Do not commit, stage, branch, or push on your own initiative", so `do` cannot write a commit it never makes); in-file markers stamped on write (rejected — pollutes source, and cannot mark deletions or non-text files).

### AD3 — A hard split between the deterministic join and the model-driven review

**Choice**: The join is a deterministic script. The review is model-driven. The review consumes the join's **data**, never its **labels**.

**Rationale**: determinism is the join's entire value — it is what makes the JSON a record rather than an opinion, and what makes run-to-run deltas meaningful. If the review reads confidence labels rather than the underlying links, it inherits confidence claims it cannot verify and the labelling model leaks across the boundary that gives it meaning.

**Alternatives considered**: a single model-driven pass producing both join and findings (simpler to build, but the join stops being auditable and the delta stops being trustworthy).

### AD4 — The JSON is the record; the artifact is a disposable projection

**Choice**: The join emits JSON into the repository. The published page is regenerated from that JSON and treated as disposable.

**Rationale**: JSON is diffable and greppable; a hosted page is neither. Putting the only copy of provenance data inside a published page places a record somewhere `grep` cannot reach. Regenerating the page from the same JSON at each release is what makes the delta the signal.

**Alternatives considered**: artifact-only (loses the record and the delta); Markdown as the record (human-readable but a poor join target, and the review already produces prose).

### AD5 — Resolution order is selector-shaped

**Choice**: Intent-anchored selectors resolve forward (intent → commits → files). Git-anchored selectors resolve reverse (files → commits → intent). Both converge on one change-set structure before the join runs.

**Rationale**: the two selector shapes are how people actually ask the question — sometimes *"review what epic 41-03 produced"*, sometimes *"review this branch"* — and they are genuinely opposite traversals of the same graph. Converging early means the join, the queries and the review are written once.

**Alternatives considered**: git-anchored only, requiring the user to translate an epic into a range by hand (loses the forward direction, which is the one that makes R4 answerable).

## Scope

### In Scope

- R1–R9 and AD1–AD5.
- New skill `/cpm:inspect`.
- Git-native adapter: commit trailers, conventional commits, branch names.
- CPM adapter: epic docs, `**Satisfies**` fields, coverage matrices, co-commit.
- Deterministic join emitting the JSON record; model-driven review producing `file:line` findings.
- Orphan changes across all adapters; unbacked claims via the CPM adapter.
- A one-line `description` amendment to `/cpm:review` so the pair reads by subject.
- Synthetic git-repository test fixtures.

### Out of Scope

- Issue and PR reference resolution.
- Any change to `/cpm:audit`.
- Any change to `/cpm:review`'s document schema.
- Any change to `cpm:do`'s version-control stance.
- Back-filling provenance into completed work.

### Deferred

- Issue-tracker adapters (Jira, GitHub, Linear). The adapter contract must not preclude them.
- Delta between two runs.
- Commit-cadence guidance.

## Testing Strategy

### Tag Vocabulary

- `[unit]` — Unit tests targeting individual components in isolation
- `[integration]` — Integration tests exercising boundaries between components
- `[feature]` — Feature/end-to-end tests exercising complete user-facing workflows
- `[manual]` — Manual inspection, observation, or user confirmation
- `[tdd]` — Workflow mode: red-green-refactor. Composable with any level tag.

### Acceptance Criteria Coverage

| Requirement | Acceptance Criterion | Test Approach |
|---|---|---|
| R1 | `epic 41-03`, `--since <ref>` and a branch name each resolve to the same change-set structure | `[integration]` |
| R1 | must NOT silently return an empty change set when a selector matches nothing — it errors with the selector echoed back | `[integration]` |
| R2 | An intent-anchored run and a git-anchored run over the same commits yield the same file set | `[integration]` |
| R3 | A file with no adapter link appears in orphans; a file with a declared link does not | `[integration]` |
| R3 | must NOT list a file as an orphan when any active adapter resolves it | `[integration]` |
| R4 | An intent record marked verified with no test naming it is listed as an unbacked claim | `[integration]` |
| R4 | must NOT report an empty unbacked list as "none found" when the active adapters cannot answer the query — "none found" and "not answerable" must render differently | `[integration]` |
| R5 | Findings carry `file:line` citations | `[integration]` |
| R5 | When the change set overflows one pass, the files not examined are listed explicitly | `[integration]` |
| R5 | must NOT present a partial review as complete | `[integration]` |
| R6 | Two runs against the same repository state produce byte-identical JSON | `[integration]` |
| R6 | The emitted document is valid JSON | `[unit]` |
| R7 | Every resolved link carries exactly one of declared / derived / absent | `[unit]` |
| R7 | A declared marker always wins over a derived one for the same (file, intent) pair | `[unit]` |
| R7 | must NOT label a derived link as declared under any adapter combination | `[unit]` |
| R8 | The published artifact registers a row in `docs/artifacts/index.md` and records an `**Artifacts**:` backlink | `[integration]` |
| R8 | must NOT embed source content in the published page | `[integration]` |
| R9 | A repository with no CPM artifacts and no trailers still produces a review, with every file reported as an orphan | `[integration]` |
| R9 | must NOT hard-fail when no adapter resolves anything | `[integration]` |

**Why R7's precedence row carries the weight.** There is no oracle for whether a derived link is *true* — "epic 41-03 owns this file" cannot be verified by a test. What *can* be tested is that labels are applied consistently and that a declared marker always beats a derived one. Confidence integrity is therefore a **precedence property**, not a correctness property, and the criteria say so rather than implying a guarantee the design cannot make.

**Why R4's asymmetry needs its own must-NOT.** Commit trailers and branch names record *why* a change happened; they never record *and here is the criterion it satisfies, marked verified*. R4 is answerable only through an adapter that carries verification claims — in this iteration, the CPM adapter alone. An empty unbacked list and an unanswerable query must never render identically, or the asymmetry becomes a silent lie.

### Integration Boundaries

- **selector → change set** — where both resolution directions converge; the seam R1 and R2 share.
- **adapter → link set** — the pluggable seam. Each adapter is tested against the same contract, which is what makes the deferred issue-tracker adapters cheap to add later.
- **join → review** — AD3's hard split. The review consumes data, never labels.

### Test Infrastructure

**Synthetic git repositories are a new requirement.** The existing 24 hook suites operate on flat files in `TEST_TMPDIR`; this spec needs fixtures that are real repositories with known commits, trailers, branch names and co-committed planning documents, built and torn down per test. This becomes its own story in breakdown.

`check_valid_json` already exists in `cpm/hooks/tests/html-test-helpers.sh:364` and covers R6's validity criterion. `test-helpers.sh` provides the assertion vocabulary.

### Unit Testing

Unit testing of individual components is handled at the `cpm:do` task level — each story's acceptance criteria drive test coverage during implementation.
