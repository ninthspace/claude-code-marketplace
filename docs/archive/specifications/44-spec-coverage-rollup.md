# Spec: Spec-Level Coverage Roll-Up

**Date**: 2026-07-26
**Discussion**: docs/discussions/28-discussion-spec-delivery-autonomy.md

## Problem Summary

Nothing answers *"is this spec fully delivered?"* Coverage lives per-epic — `cpm:epics` Step 3d writes one matrix per epic and `cpm:do` fills its `✓` marks — and no artefact spans a spec's epics. Answering the question for spec 43 meant opening four files and diffing them by eye. No test asserts anything about coverage matrices at all, so the traceability spine is convention held up by prose and human reading.

This spec builds the missing artefact: a script-backed roll-up that unions a spec's coverage matrices back against the spec's own requirements, with three consumers — `cpm:status`, a stakeholder page, and `cpm:ralph`'s completion promise. It is a prerequisite for autonomous epic generation rather than a step toward it: the thing that decides which requirements become stories cannot also be the only witness to whether it covered them all.

**The premise, stated honestly.** Spec 42 was built, shipped and withdrawn the next day because its join answered a question with a *no* that was structurally guaranteed rather than measured. This roll-up splits cleanly along that line and the spec is written to keep the two halves distinct:

- **Untraced-requirement detection discriminates.** The spec's requirement list is authored by a human in one session; the matrices are generated later by `cpm:epics` reading that spec. A requirement `epics` skipped is present in one source and absent from the other, and nothing about the mechanism guarantees the gap list is empty.
- **`✓` aggregation does not.** Those marks are placed by `cpm:do` on its own work. Unioning them reports what `do` claimed, more conveniently. It adds no independent evidence, and under autonomy it is the loop marking its own homework.

The first half is load-bearing. The second is convenience, and FR7 requires it to say so wherever it appears.

## Functional Requirements

### Must Have

- **FR1** — A script under `cpm/hooks/lib/` accepts **either** a spec path or one or more epic paths, and emits one record per requirement (spec scope) or per matrix row (epic scope). Spec scope discovers matrices by their `**Source spec**` field. Epic scope reports row states only; untraced detection is meaningless without a requirement list to compare against.
- **FR2** — **Untraced-requirement detection** (spec scope): requirements present in the spec with no matching row in any matrix. This is the load-bearing measurement and the headline output.
- **FR3** — Three requirement states — *delivered*, *in progress*, *untraced* — derived from row-level `✓`. A requirement with some rows verified and some not is *in progress*, never a proportion.
- **FR4** — Label qualifiers (`FR1 (must NOT)`, `FR6 (cross-site)`) resolve to their base requirement. `(story-originated)` rows carrying `—` spec text are reported separately as criteria with no requirement behind them.
- **FR5** — **Fail closed**: missing spec, unreadable matrix, or no matrices found exits non-zero and reports *not complete*. Never *complete by default*.
- **FR6** — `cpm:status` gains a spec-scoped phase rendering the roll-up organised by the spec's **MoSCoW structure**, quoting each requirement's verbatim text, with untraced requirements surfaced first.
- **FR7** — `✓` aggregation is labelled as **aggregation, not verification**, at every site presenting it. A wall of green must not read as independent confirmation.
- **FR8** — `cpm:ralph`'s completion promise becomes script-backed: the model runs the script and emits the promise tag **only** on a passing exit code, with the tag carrying its evidence. Epic mode's promise is aggregation; only spec mode's would carry the discriminating measurement, and spec mode is deferred.
- **FR9** — Existing `cpm:ralph` invocations behave unchanged. Empty arguments still mean "auto-discover all incomplete epics".

### Should Have

- **FR10** — Counts stable enough to compare between runs, so a **non-converging** loop — neither stalled nor finished, numbers flat across iterations — is detectable. `cpm:ralph` defaults to 50 iterations and no number currently exists that would reveal this.
- **FR11** — Stakeholder artifact published through the existing shared **Artifact Publishing** procedure. No second publishing path.

### Won't Have (this iteration)

- Autonomous `cpm:epics` — the branch that would let epics be generated unattended, including a rule for its must-NOT gate at `epics:155`, the one gate with no defensible default.
- `cpm:ralph` spec mode — a spec path as a fourth input shape.
- Any change to the coverage matrix format, or to how `cpm:epics` and `cpm:do` write it.

## Non-Functional Requirements

- **NFR1 — Read-only.** The script never writes, moves or modifies any document. A measurement that mutates its subject cannot be trusted about it.
- **NFR2 — Fail closed, and loudly.** Every failure path names what could not be read. A predicate that fails silently is indistinguishable from one that passed.
- **NFR3 — No new dependencies.** POSIX shell and the tools already used in `cpm/hooks/lib/` — bash 3.2 (macOS default), `grep`, `awk`, `sed`. No `jq`, no Python.
- **NFR4 — Legible to both readers.** One output format a model can parse into a promise decision and a human can read in a terminal without a renderer.
- **NFR5 — Single source of the computation.** `cpm:status` and `cpm:ralph` call the script; neither reimplements the union, the matching, or the state derivation.

## Architecture Decisions

### AD1: The computation is a shell script, not model-emitted JSON

**Choice**: A script in `cpm/hooks/lib/`, following `progress-classify.sh`.
**Rationale**: A `--json` mode on a skill is a model reconstructing an inventory each run. `cpm:clean` enumerated files itself and reported an empty inventory on every run for months; the fix was a script plus a skill that "never globs or `stat`s files itself".
**Alternatives considered**: Model-emitted JSON from `cpm:status` — rejected on the above evidence.

### AD2: Discover matrices by their `**Source spec**` field

**Choice**: Spec scope finds matrices by reading the field, not by filename prefix.
**Rationale**: All 17 present matrices carry it. The filename route re-derives a relationship the document already states, and a signal derived from what a document asserts agrees with itself by construction — spec 42's failure mode.
**Alternatives considered**: Glob `{parent}-*-coverage-*.md` — cheaper, but couples discovery to a naming convention that already has two shapes.

### AD3: Tab-separated records via `printf`

**Choice**: The record format `progress-classify.sh` already uses.
**Rationale**: Satisfies NFR3 and NFR4 in one choice with nothing to invent.
**Alternatives considered**: JSON (requires `jq`, breaks NFR3); prose (unparseable).

### AD4: Exit code is the verdict; the promise names its evidence

**Choice**: The script's exit code decides; the model emits `<promise>` only on zero, and the tag carries the untraced count and requirement total.
**Rationale**: The ralph-wiggum stop hook matches **text**, so the loop can never call the script itself. This narrows model discretion from *making the judgement* to *relaying a verdict*. The gap that remains — a model emitting the tag without running the check — is made visible rather than closed: a bare tag is unfalsifiable in the log, an evidence-bearing one is not.
**Alternatives considered**: A bare tag; encoding the verdict in the state file (the hook does not read it).

### AD5: Source the shared root resolver, and test the documented invocation

**Choice**: The script sources `resolve-project-root.sh`; tests extract the invocation from `status/SKILL.md` and run it with `CLAUDE_PROJECT_DIR` unset.
**Rationale**: `CLAUDE_PROJECT_DIR` is set for hooks but not for the Bash calls a skill issues — spec 43's defect exactly, which survived months of a green suite because a re-typed copy of the command was tested instead of the documented one.
**Alternatives considered**: Re-typed test copy — the defect itself.

## Scope

### In Scope

- The roll-up script: dual scope, union, matching, three states, untraced detection, fail-closed (FR1–FR5)
- `cpm:status` spec-scoped phase, MoSCoW-organised, aggregation labelled as such (FR6, FR7)
- `cpm:ralph` epic-mode promise upgrade, script-backed with evidence in the tag (FR8, FR9)
- Assertions for the two input invariants the script depends on: `**Source spec**` accuracy and `✓` semantics
- Convergence-comparable counts (FR10) and the stakeholder artifact (FR11), as should-haves

### Out of Scope

- Any change to the coverage matrix format, or to how `cpm:epics` and `cpm:do` write it
- A project-wide roll-up — this is spec-scoped, and `cpm:status` keeps its existing project view

### Deferred

- Autonomous `cpm:epics`, including a rule for its must-NOT gate at `epics:155`
- `cpm:ralph` spec mode as a fourth input shape
- The remaining untested coverage-matrix invariants: the `-epic-` → `-coverage-` filename derivation, and the rule that a criterion change resets its row to unverified

## Testing Strategy

### Tag Vocabulary

- `[unit]` — Unit tests targeting individual components in isolation
- `[integration]` — Integration tests exercising boundaries between components
- `[feature]` — Feature/end-to-end tests exercising complete user-facing workflows
- `[manual]` — Manual inspection, observation, or user confirmation
- `[tdd]` — Workflow mode: red-green-refactor. Composable with any level tag.

**Assert the invariant, not the snapshot — and not against a pinned value.** Retro 19's lesson applies throughout: `assert_equals "19" "$(rollup | wc -l)"` is a snapshot that rots the moment a spec is edited. Every criterion below asserts a relationship — untraced ∪ traced = the spec's requirement set — never a count.

### Acceptance Criteria Coverage

| Requirement | Acceptance Criterion | Test Approach |
|---|---|---|
| FR1 | Given a spec path, the script emits one record per requirement in that spec, sourced only from matrices whose `**Source spec**` names it | `[integration]` |
| FR1 | Given epic paths, the script emits row-state records for those epics' matrices and no untraced section | `[integration]` |
| FR1 | must NOT include rows from a matrix belonging to a different spec | `[integration]` |
| FR2 | A requirement present in the spec with no matching row in any matrix is reported as untraced | `[integration]` |
| FR2 | Traced and untraced requirements together account for every requirement in the spec — asserted as a partition, not a count | `[integration]` |
| FR3 | All rows `✓` reports *delivered*; none reports *in progress*; a mix reports *in progress*, never a proportion | `[integration]` |
| FR4 | `FR1 (must NOT)` and `FR6 (cross-site)` resolve to `FR1` and `FR6`; a `(story-originated)` row with `—` spec text is reported separately, not as a requirement | `[unit]` |
| FR5 | Missing spec, unreadable matrix, and zero matrices found each exit non-zero and name what could not be read | `[integration]` |
| FR5 | must NOT exit zero on any path where the computation did not complete | `[integration]` |
| FR6 | The invocation extracted verbatim from `status/SKILL.md` produces records when run with `CLAUDE_PROJECT_DIR` unset | `[integration]` |
| FR6 | Output is organised by the spec's MoSCoW headings, with untraced requirements before delivered ones | `[integration]` |
| FR7 | Every site presenting aggregated `✓` also states that aggregation is not verification | `[integration]` |
| FR7 | A stakeholder reading the output does not take a wall of green as independent confirmation | `[manual]` — whether a page reads as a claim is judgement, not structure |
| FR8 | `ralph`'s promise text and the script invocation land together in one assertion, so neither can ship alone | `[integration]` |
| FR8 | The emitted promise carries its evidence, so a fabricated promise is distinguishable from an earned one in the log | `[integration]` |
| FR9 | `cpm:ralph` with empty arguments still auto-discovers incomplete epics | `[integration]` |
| FR9 | must NOT change the behaviour of any existing documented invocation | `[integration]` |
| NFR1 | The repository is byte-identical before and after a run — `git status` reports no change | `[integration]` |
| Invariants | Every present matrix's `**Source spec**` resolves to a file that exists | `[integration]` |
| Invariants | A `✓` appears only on rows whose criterion text is unchanged since verification — the matrix's own stated rule | `[manual]` — text identity over time has no in-repo oracle |

### Integration Boundaries

1. **Script ↔ spec document** — requirement-label extraction from `- **FRn**` bullets
2. **Script ↔ coverage matrices** — `**Source spec**` matching and column-2 label parsing
3. **Script ↔ `cpm:status`** — the documented invocation, run with the environment a skill actually has
4. **Script ↔ `cpm:ralph`** — exit code translated into an evidence-bearing promise tag

### Test Infrastructure

The existing harness is adequate — `test-helpers.sh`, `run-all-tests.sh`, `TEST_TMPDIR`, bash 3.2. One addition: fixture specs and matrices built under `TEST_TMPDIR`, so partition and fail-closed cases can be constructed rather than found. That is a story in the epic, not new infrastructure.

### Unit Testing

Unit testing of individual components is handled at the `cpm:do` task level — each story's acceptance criteria drive test coverage during implementation.
