# Spec: Spec-Level Delivery Autonomy

**Date**: 2026-07-26
**Brief**: docs/discussions/28-discussion-spec-delivery-autonomy.md

## Problem Summary

You write a spec; the loop should produce the epics and implement them without further input. Spec 44 removed the blocker by making *"is this spec fully delivered?"* a script-backed question, and gated `cpm:ralph`'s completion promise on it. What remains is the three pieces Ren decomposed in the discussion: `cpm:ralph` accepting a spec path, an autonomous branch for `cpm:epics`, and a two-phase prompt that runs `/cpm:epics` first and `/cpm:do` after. The hard part is that spec mode has **two** completion conditions rather than one — conflating them yields a loop that reports success on an empty spec, because zero requirements are untraced when there are no matrices to be untraced against.

## Functional Requirements

### Must Have

- **FR1** — A spec path is a **fourth input shape** on `cpm:ralph`. Mode detection comes from the path itself; no flag, no new skill.
- **FR2** — **Empty arguments keep today's meaning**: auto-discover all incomplete epics. Silently promoting that to spec-hunting breaks a working invocation.
- **FR3** — Pre-flight **tolerates zero epics** when a spec path was given. Today Step 1a stops with "No incomplete epics found. Nothing to run." — in spec mode that is the starting state, not a failure.
- **FR4** — An **autonomous branch for `cpm:epics`**, covering all six `AskUserQuestion` sites (`:81` epic grouping, `:155` must-NOT clauses, `:178` stories, `:214` tasks, `:231` integration-testing story, `:282` final confirmation). Five are approve-your-own-proposal; `:155` is governed by FR5. `cpm:epics` has no autonomous handling today, so this is built against 43-02's pattern rather than extended from an existing one.
- **FR5** — A rule for the **must-NOT gate at `epics:155`**, the one gate where auto-accepting your own defensive boundary is the self-marking problem 43-02 solved with the citable-contradiction rule.
- **FR6** — **Two completion conditions, never conflated.** Phase 1 is *every requirement traced to a matrix row*; phase 2 is *every row verified*. A spec with no epics is phase one, and phase one is never "done".
- **FR7** — The loop **distinguishes "no epics yet" from "the check could not run"**. Both are `exit 1` today; one means keep working, the other means stop.
- **FR8** — **Phase-1 completion is a recorded fact**, not inferred from the presence of epic files. A partially-generated set must be distinguishable from a complete one.
- **FR9** — A run interrupted mid-phase-1 **resumes without restarting or double-writing** epics already on disk.
- **FR10** — **One promise per mode, fixed at launch** — not a choice offered to the loop. Epic mode asks "are these matrices fully verified"; spec mode asks that *plus* "are all the spec's requirements traced".
- **FR11** — **Non-convergence is visible.** Each iteration reports traced and verified counts, and a run whose counts are unchanged across N consecutive iterations stops and reports rather than continuing. `cpm:ralph` defaults to 50 iterations and no number currently exists that would reveal a loop that is neither stalled nor finished.
- **FR12** — **Cross-session relaunch detects a leftover `cpm:epics` progress file** for the same spec, even when the Stale-Progress guard returns `SUPPRESS`, and passes it back as resume state.
- **FR13** — **`[plan]` tags are stripped from every epic doc before `/cpm:do` runs over it**, not only from the docs that existed at pre-flight. Step 1b strips them after epic discovery and before launch, which covers all three of today's input shapes because their epics are on disk when pre-flight runs. In spec mode the epics do not exist yet: `cpm:epics` writes them during phase 1 and its `[plan]` tag suggestion rule attaches tags to exactly the stories that touch data models, API contracts, or cross-system integration. Those tags reach `cpm:do` unstripped, `EnterPlanMode` fires, and the loop stalls waiting for an approval nobody is present to give — the precise failure Step 1b exists to prevent.

### Won't Have (this iteration)

- Autonomous `cpm:spec` — you write the spec. It is the input, and the fixed point NFR3 protects.
- Autonomous `cpm:pivot` — 43-02 already ruled it out for `cpm:do`, and nothing here reopens it.
- Any change to the coverage matrix format, or to `coverage-rollup.sh`'s record types. Exit codes are not record types, which is what makes AD2 admissible.
- A new skill. Mode detection on an existing input is free; a new skill would need its own discovery, state and gates.

## Non-Functional Requirements

- **NFR1 — Fail closed on every phase decision.** Uncomputable means *not complete*, and never advances a phase. Spec 44's NFR2 made the script fail closed; this extends it to the loop's own branching, where the failure mode is worse — an unattended loop that reads "I couldn't tell" as "done" ends the run.
- **NFR2 — Single source of the phase judgement.** `cpm:ralph` relays the script's records; it never derives traced / untraced / verified state itself. Reading a named field out of a `SUMMARY` record is relaying; counting rows is deriving. Extends spec 44's NFR5.
- **NFR3 — Bounded write surface for the autonomous `epics` phase.** It writes epic docs, coverage matrices, and its progress file. **It never edits the source spec.** The spec is the only artefact a human authored and the only fixed point the loop is measured against, so a loop that can rewrite it can move its own goalposts. `cpm:do`'s autonomous branch already carries this rule (`do/SKILL.md:64`); an autonomous `epics` needs it more, because `epics` reads the spec as its primary input and is one edit away from it.
- **NFR4 — Auditable without re-running.** Every autonomous gate decision leaves a breadcrumb naming *which* gate and *what* was chosen. Without this, "the loop cut the spec into five epics" is unreviewable.
- **NFR5 — Prompt budget.** The template is **2,858 characters** today and is fed back verbatim on every iteration. New clauses stay to a sentence, and the stated figure is asserted against the actual length.
- **NFR6 — Idempotent resume.** Re-entering phase 1 over a partially-generated set neither duplicates an epic nor renumbers one. `cpm:epics` already treats sub-numbers as identifiers rather than ordinals, so the constraint is that resume must not violate a property the numbering procedure already guarantees.

## Architecture Decisions

### AD1 — The roll-up is the phase predicate

**Choice**: phase 1 is complete when `coverage-rollup.sh --spec <path>` reports **0 untraced**; phase 2 is complete when every row reads verified. No new marker, no new script.

**Rationale**: a mid-phase-1 partial — three of five epics on disk — reads as *untraced > 0* automatically, because the requirements in the unwritten epics have no matrix row. Resume detection falls out of a measurement that already exists rather than from a claim the loop makes about itself, which is what NFR2 asks for and what FR8 rules out.

**Alternatives considered**: a `phase:` marker in the state-file frontmatter — it would survive, since the stop hook's `sed` only rewrites `^iteration:`, but a marker the loop writes about its own progress is exactly the self-report FR8 exists to prevent. Inferring from epic-file presence — forbidden by FR8 for the same reason.

**Consequence, recorded rather than hidden**: if `cpm:epics` legitimately leaves a Must Have uncovered, phase 1 never completes and the loop spins. That is the *correct* finding — the "requirement fell through the breakdown" case the discussion called the product — but it needs FR11 to turn it into stop-and-report rather than fifty wasted iterations.

### AD2 — A fourth exit code, on the `--verdict` path only

**Choice**: `coverage-rollup.sh --verdict` gains a distinct exit code meaning *spec readable, zero matrices name it*. Default (non-`--verdict`) behaviour stays byte-identical.

**Rationale**: verified rather than assumed — an empty matrix directory today prints `coverage-rollup: no matrix in <dir> names <spec> as its source spec` and exits **1**, the same code as a genuine read failure. In spec mode that state is "phase one hasn't run yet", the most normal thing at iteration 1. Confining the change to `--verdict` is the containment spec 44 used for `--verdict` itself, and it keeps the judgement in the single source (NFR2).

**Alternatives considered**: the loop reads the records and treats a missing `SUMMARY` as "no matrices yet" — an inference the loop makes, sitting closer to deriving than NFR2 allows. Matching the stderr text — cheapest and worst, because it makes a diagnostic message load-bearing, so rewording an error breaks the loop silently.

### AD3 — One static conditional prompt, not a mid-loop rewrite

**Choice**: a single prompt carrying both phases, branching on the roll-up's answer.

**Rationale**: the rewrite is genuinely available — `stop-hook.sh` re-reads the state file every iteration and rewrites only the `iteration:` line — but it deletes the state file the moment the prompt body reads empty, ending the run with no way back. That trades a prompt-budget problem for an unrecoverable one, against NFR1 and NFR6. A static prompt is also the one you can read afterwards to know what the loop was told; a prompt that mutated mid-run leaves you reconstructing which version produced which iteration.

**Cost**: NFR5. The template goes from 2,736 characters to roughly 3,400.

**Alternatives considered**: rewriting the prompt body after phase 1 (cheaper prompt, unrecoverable failure mode); two state files (the hook reads one path).

### AD4 — A distinct promise tag, fixed by mode at launch

**Choice**: spec mode writes its own `completion_promise` into the state file's frontmatter; epic mode keeps `ALL_EPICS_COMPLETE`.

**Rationale**: the stop hook compares `<promise>` contents to `completion_promise` with literal string equality, and `completion_promise` is per-run frontmatter — so the tag can differ by mode without anyone being offered a choice. The discussion's one-tag argument was that two tags means the weaker path survives because everyone keeps using the convenient one; that argument is about a *choice* being available, not about the string. `ALL_EPICS_COMPLETE` at the end of a spec-mode run names the wrong achievement in a log read by someone who was not there.

**Alternatives considered**: keeping `ALL_EPICS_COMPLETE` for both (literally one tag, but a misnomer in half its uses).

### AD5 — Propagate spec-originated must-NOTs only

**Choice**: at `epics:155`, an autonomous run propagates must-NOT clauses the source spec already carries, never invents new ones, and records what it would have proposed for post-run review.

**Rationale**: propagating a must-NOT the spec's own Section 6b probed for is transcription; inventing one for a domain the spec never mentioned is a judgement made in the moment with nobody to check it. That is 43-02's citable-contradiction shape — act only on evidence a reader can verify afterwards.

**Alternatives considered**: auto-accepting every proposal — maximally defensive, but self-marking, and retro 21 showed an invented must-NOT can be *unsatisfiable as written*, which would then block `cpm:do` autonomously with nobody watching. Skipping the gate entirely — fastest, but it drops the defensive-boundary probe for security and data-integrity criteria and leaves no trace that it was skipped.

### AD6 — Strip `[plan]` at the point of use, not at generation

**Choice**: `cpm:epics` keeps writing `[plan]` tags under an autonomous run exactly as it does interactively; the phase-1-to-phase-2 transition strips them from the epics just generated, before any `/cpm:do` runs. Step 1b's rule generalises from "strip after epic discovery" to "strip before `/cpm:do` runs over the doc" — one rule with two trigger points, pre-flight in epic mode and the phase transition in spec mode.

**Rationale**: `[plan]` is not noise to be suppressed — it marks the stories touching data models, API contracts, and cross-system integration, and that is the first thing a human reviewing an unattended run's output wants to know. Suppressing it at generation would make an autonomously-produced epic doc quietly different from a human-facilitated one for the same work, and the difference would be invisible in the artefact. Stripping at the point of use keeps the signal in the document a reviewer reads and removes it only where it would stall the loop, which is what Step 1b already does — a moment later, for the same reason.

**Cost**: NFR5. A clause in the prompt template, kept to a sentence by referencing Step 1b rather than restating the procedure.

**Consequence**: an epic doc that has been through a spec-mode loop has had its `[plan]` tags removed, so the tags are visible in the generated artefact only between phase 1 and phase 2. The execution log records what was stripped, per Step 1b step 3, which is where the durable record lives.

**Alternatives considered**: `cpm:epics` declining to emit the tag autonomously — cheapest, no prompt cost, and it sits naturally beside the Autonomous Mode branch since `[plan]` is itself an approval gate; rejected because it discards reviewer signal and would reopen epic 45-01, complete at 9/9 verified rows. Doing both — defensive against a future path that generates epics some other way, but two rules where one suffices, and the redundancy reads as uncertainty about which one works.

## Scope

### In Scope

- `cpm:ralph` spec mode: a fourth input shape, with pre-flight tolerating zero epics (FR1–FR3).
- An autonomous branch for `cpm:epics` across all six gates, including the `:155` rule (FR4, FR5).
- The two-phase conditional prompt, one static template (FR6, AD3).
- A fourth `--verdict` exit code on `coverage-rollup.sh` (FR7, AD2).
- A distinct spec-mode promise tag (FR10, AD4).
- Phase-1 resumability within and across sessions, and non-convergence detection (FR8, FR9, FR11, FR12).
- Stripping `[plan]` from epics generated during phase 1, at the phase transition (FR13, AD6).

### Out of Scope

- Autonomous `cpm:spec`.
- Autonomous `cpm:pivot`.
- Changes to the coverage matrix format or the roll-up's record types.
- A new skill.

### Deferred

- Nothing. FR12 was the one candidate for deferral — a cross-session relaunch failing to see a leftover `cpm:epics` progress file, because the Stale-Progress guard prints `SUPPRESS` while `.claude/ralph-loop.local.md` exists. It was brought in scope rather than deferred: the failure is duplicate epic docs for the same work area, and NFR6 forbids duplication without qualifying it to same-session runs. Narrowing NFR6 instead was the considered alternative.

## Testing Strategy

### Tag Vocabulary
Test approach tags used in this spec:

- `[unit]` — Unit tests targeting individual components in isolation
- `[integration]` — Integration tests exercising boundaries between components
- `[feature]` — Feature/end-to-end tests exercising complete user-facing workflows
- `[manual]` — Manual inspection, observation, or user confirmation
- `[tdd]` — Workflow mode: task follows red-green-refactor loop. Composable with any level tag (e.g. `[tdd] [unit]`). Orthogonal — describes how to work, not what kind of test.

No criterion in this spec is `[manual]`. Everything here is prose a model follows or a shell script, and both are automatable.

### Acceptance Criteria Coverage

| Requirement | Acceptance Criterion | Test Approach |
|---|---|---|
| FR1 | A path under `docs/specifications/` resolves spec mode; epic paths or a range resolve epic mode; nothing resolves auto-discovery | `[integration]` |
| FR1 (must NOT) | must NOT require a flag to select the mode | `[integration]` |
| FR2 | Empty arguments still auto-discover all incomplete epics | `[integration]` |
| FR2 (must NOT) | must NOT change the behaviour of any existing documented invocation | `[integration]` |
| FR3 | With a spec path and zero epics on disk, pre-flight proceeds to phase 1 | `[integration]` |
| FR3 (must NOT) | must NOT emit "No incomplete epics found. Nothing to run." when a spec path was given | `[integration]` |
| FR4 | Every one of the six gate sites has a stated autonomous disposition | `[integration]` |
| FR4 (must NOT) | must NOT leave any gate site without a stated autonomous disposition | `[integration]` |
| FR4 | The branch is defined in `cpm:epics`; `cpm:ralph`'s prompt references it rather than restating it | `[integration]` |
| FR5 | Spec-originated must-NOT clauses are propagated; others are recorded as proposed-unreviewed rather than attached | `[integration]` |
| FR5 (must NOT) | must NOT attach a must-NOT clause that cannot be traced to a line in the source spec | `[integration]` |
| FR6 | The prompt states phase 1's predicate (0 untraced) and phase 2's (all rows verified) separately | `[integration]` |
| FR6 (must NOT) | must NOT emit the completion tag while any requirement is untraced | `[integration]` |
| FR7 | `--verdict` returns a distinct exit code when the spec is readable and zero matrices name it | `[tdd] [unit]` |
| FR7 | The prompt branches on that code as "phase 1 not started" and on the read-failure code as "stop" | `[integration]` |
| FR7 (must NOT) | must NOT treat a read failure as phase 1 not started | `[integration]` |
| FR8 | The phase judgement comes from the roll-up's records | `[integration]` |
| FR8 (must NOT) | must NOT infer phase from the presence or count of epic files | `[integration]` |
| FR9 | Re-entering phase 1 with epics already on disk continues rather than restarting, and writes no duplicate epic doc | `[integration]` |
| FR10 | Spec mode's `completion_promise` differs from epic mode's, is fixed at launch, and the emitted tag matches it exactly | `[integration]` |
| FR10 (must NOT) | must NOT put evidence inside the promise tag | `[integration]` |
| FR11 | Each iteration reports traced and verified counts; a run whose counts are unchanged across N consecutive iterations stops and reports | `[integration]` |
| FR11 (must NOT) | must NOT continue past the non-convergence threshold without reporting | `[integration]` |
| FR12 | Spec-mode pre-flight detects a leftover `cpm:epics` progress file for the same spec even when the guard returns `SUPPRESS` | `[integration]` |
| FR12 (must NOT) | must NOT delete or overwrite that progress file without surfacing it | `[integration]` |
| FR13 | Epics generated during phase 1 are stripped before phase 2 begins, by the same rule Step 1b applies at pre-flight | `[integration]` |
| FR13 (must NOT) | must NOT begin phase 2 while an epic the run generated still carries the tag | `[integration]` |
| FR13 (must NOT) | must NOT strip tags from epic docs the run did not generate | `[integration]` |
| NFR1 | Every phase decision defaults to *not complete* when the roll-up cannot compute | `[integration]` |
| NFR2 | The loop relays named record fields; it counts no rows itself | `[integration]` |
| NFR2 (must NOT) | must NOT derive traced or verified state from the records | `[integration]` |
| NFR3 | An autonomous run writes nothing under `docs/specifications/` | `[integration]` |
| NFR3 (must NOT) | must NOT write to `docs/specifications/` during an autonomous run | `[integration]` |
| NFR4 | Each autonomous gate decision leaves a breadcrumb naming the gate and the choice | `[integration]` |
| NFR5 | The template's stated `**Length: N characters**` figure matches its actual length | `[integration]` |
| NFR6 | Resume duplicates no epic doc and renumbers none | `[integration]` |

Three criteria are phrased deliberately, against findings rather than instinct. **FR13's first must-NOT says "the tag" rather than naming it**, for the same reason NFR3's names a path: the rule's own explanation has to write the tag repeatedly, so a must-NOT phrased against that token would be unsatisfiable on arrival — retro 21's remedy applied when the criterion is written rather than when its assertion fails. **NFR3's must-NOT names the path**, not the word "spec" — retro 21 found that a must-NOT phrased against a token constrains the prose as well as the behaviour, and "spec" will appear in explanatory clauses throughout this work. **FR4's must-NOT is arithmetic rather than judgement** — enumerate the six gate sites, assert each carries a disposition — which is retro 22's *"a rule inventory taken before the first edit turns a must-NOT into arithmetic."*

### Integration Boundaries

1. **`cpm:ralph` → `coverage-rollup.sh`** — the exit-code contract, now four codes on `--verdict`. Spec 43's AD5 applies: extract the documented command from the prompt and run it verbatim, never re-type it into a test.
2. **`cpm:ralph` → the ralph-wiggum stop hook** — `completion_promise` frontmatter against literal `<promise>` equality, now with two possible tags rather than one.
3. **`cpm:ralph`'s prompt → `cpm:epics`'s autonomous branch** — the prompt references, `cpm:epics` defines. Same single-source shape the `cpm:do` overrides already use.
4. **`cpm:ralph`'s prompt → `cpm:do`'s autonomous branch** — existing, and must not regress.
5. **`cpm:epics` → coverage matrices → `coverage-rollup.sh`** — the circular seam: phase 1's output is the input to phase 1's own predicate. The one most worth an end-to-end test.

### Test Infrastructure

The existing bash suite is adequate — 39 suites and 1,093 assertions at the time of writing, with fixture builders in `cpm/hooks/tests/coverage-fixture-helpers.sh` that already produce specs and matrices on demand. One fixture shape is missing, and it is the test the source discussion flagged and nobody wrote: **an epic whose stories are all `Complete` while its matrix still has unverified rows**. `--verdict` returns 3 there today because it reads matrix rows and never reads story status — structurally immune rather than accidentally right — but no test constructs the case.

### Unit Testing
Unit testing of individual components is handled at the `cpm:do` task level — each story's acceptance criteria drive test coverage during implementation.
