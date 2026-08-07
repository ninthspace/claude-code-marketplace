# Spec: Environmental Requirements and Restrictions

**Date**: 2026-07-27
**Brief**: none — authored from a field-test finding during `cpm:ralph` spec mode on a greenfield Laravel project

## Problem Summary

Nothing in the CPM pipeline records what environment the work must run in, or what it must not require. A missing requirement yields less software and you notice; a missing restriction yields software that passes every acceptance criterion and does not deploy — coverage reads 132 of 132 verified while the app needs a queue worker the host has no supervisor for. The pipeline captures constraints and then discards them: `cpm:discover` has a `## Constraints` section, `cpm:brief`'s output template has nowhere to put them, and `cpm:spec` preferentially reads the product brief — the document where they were lost. Autonomously it is worse, since `cpm:ralph` instructs the agent to "choose the most reasonable option for every AskUserQuestion", and reasonable in the abstract is wrong for a host pinned to PHP 8.2 with no outbound network.

Two design hazards were found by checking each component's source rather than its description, before any requirement was written. **Hazard A**: `coverage-rollup.sh:396` excludes a label named in a Scope deferral when `!is_must(heading)`, and `is_must("Non-Functional")` is false — so an NFR named in `### Deferred` is silently excluded, meaning the mechanism proposed to protect environmental constraints would expose them to exactly the erasure this spec exists to prevent. **Hazard B**: `cpm:epics`' cross-epic gap check compares only against the Must Have list; NFRs are never gap-checked, so an uncovered environmental constraint produces no GAP, no warning, nothing at generation time.

## Functional Requirements

### Must Have

- **FR1 — `cpm:spec` elicits environmental requirements and restrictions.** A dedicated step covering both development and production: what must be available, and what must not be required. Runs whether or not any upstream document exists.
- **FR2 — Environmental constraints are traceable.** They land somewhere `coverage-rollup.sh` reads, so an uncovered one holds `untraced > 0` and blocks `SPEC_DELIVERED`. This states the property, not the mechanism — AD1 decides where they live.
- **FR3 — Restrictions are a distinct class from requirements.** "Pest available" and "must not require a queue worker" are not interchangeable: the first is satisfied by adding something, the second invalidates a design and cannot be retrofitted. The distinction survives into the document, not just the conversation.
- **FR4 — Every constraint is falsifiable.** It states a condition something can check — `PHP >= 8.2`, not "should be efficient". Unfalsifiable entries are refused or refined at authoring time.
- **FR5 — The step inherits rather than re-asks.** It reads the problem brief's `## Constraints` and any ADRs, presents what is already known, and facilitates only the gaps. It must reach **past** the product brief, which is where the information is currently lost.
- **FR6 — A Scope deferral cannot silently exclude an environmental constraint.** *(Hazard A.)*
- **FR7 — `cpm:epics` gap-checks environmental constraints.** *(Hazard B.)*
- **FR8 — `cpm:brief` carries constraints forward.** Its output template gains the section, so the preferred spec input stops discarding them.
- **FR10 — Verification approach is stated for target-only constraints.** Most environmental constraints can be checked only against the real target, not the dev sandbox. The tag vocabulary says what that means.

*FR10 was drafted as a Should Have and promoted during Section 7 review. AD3 makes an uncovered environmental constraint a blocker; a blocker nobody can verify is one people learn to override. AD6's tag is what makes the blocker honest, so the requirement mandating it cannot be optional.*

### Should Have

- **FR9 — Greenfield is covered.** When no dependency manifest exists, the constraints are what drive installation, rather than `cpm:do`'s Test Runner Discovery finding nothing and an autonomous run proceeding with `Test command: none`.

### Could Have

- **FR11 — `cpm:discover` structures `## Constraints` so entries are liftable** — labelled, so FR5's inheritance reads structure rather than prose.
- **FR12 — `cpm:status` reports environmental constraints distinctly** from functional coverage.

### Won't Have (this iteration)

- **Solving the project-stable duplication tension.** How a fact like "PHP 8.2, no root" becomes a per-spec traced requirement without hand-copying — the library/ADR layer. FR5 inherits from documents that exist; it does not deduplicate across specs.
- **Automated verification against a real production target.** Constraints are recorded and checkable; nothing in CPM connects to a deploy target.
- **A new requirement grammar in `coverage-parse.sh`.** If FR2 needed a new section type, that would be an architecture decision to justify, not a licence to redesign the parser. AD1 makes it unnecessary.

## Non-Functional Requirements

- **NFR1 — Existing specs parse identically.** A spec written before this change produces the same `REQ` set and the same untraced count afterwards. Checkable by running `coverage-rollup.sh --spec` across every spec under `docs/specifications/` **and** `docs/archive/specifications/` — 46 files, 7 live and 39 archived — before and after, and diffing the records and exit codes. The location matters: a baseline taken over `docs/specifications/` alone covers 7 of the 46 and would pass while the rest regressed silently.

- **NFR2 — Graceful degradation when upstream documents are absent.** No problem brief, no ADRs, or a brief with no `## Constraints` — the new step still runs and facilitates from scratch, silently, exactly as ADR Discovery does today (`spec/SKILL.md:29`). Absence is never an error and never a prompt.

- **NFR3 — Fail closed on a constraint that cannot be handled.** An entry that is unparseable, unfalsifiable, or of an unrecognised class is reported and blocks, never silently dropped. This is the spec's own subject applied to itself: the failure being designed against is one that looks like success.

- **NFR4 — `REQ = STATE ∪ EXCLUDED` remains an exact partition** with the new requirement class in play, asserted from the records themselves rather than from the parser's intent. Spec 44's property, which FR6 modifies the exclusion rules underneath.

- **NFR5 — No new runtime dependencies.** Bash and awk only, no `jq` or `python3` on any hook path. Spec 44's NFR3; checkable by running the suites with stubs for both first on `PATH`.

- **NFR6 — Bounded facilitation and bounded prose.** The new step converges in 1–2 `AskUserQuestion` rounds like every other section, and the bytes added to each skill file are stated and asserted. `cpm:spec` is already the longest skill in the plugin; a step that doubles the interview has failed even if every requirement passes.

## Architecture Decisions

No ADRs exist for this project, so these were facilitated from scratch.

### AD1 — Environmental constraints live in `## Non-Functional Requirements` under distinct label prefixes

**Choice**: `ENVn` for requirements ("PHP 8.2 or later available"), `ENVXn` for restrictions ("must not require a queue worker"). Both under the existing NFR heading.

**Rationale**: verified against the parser, not inferred — both prefixes emit `REQ` records with `moscow = Non-Functional` today, **with no parser change**. The prefix is what makes them distinguishable, which is precisely what FR3 and FR7 need and what a plain `NFRn` cannot provide. Constraint discovered while testing: the label must match `[A-Z]+[0-9]+` (`coverage-parse.sh:84` and `:380`), so no underscores or hyphens in the prefix.

**Alternatives considered**: plain `NFRn` — traced but indistinguishable, which silently kills FR3 and FR7. A new `## Environmental Constraints` section with a parser change — distinguishable, but redesigns the requirement grammar that the Won't Have list explicitly rules out. The prefix scheme buys the second option's benefit at the first option's cost.

**Open**: Sable's objection that `ENVX` reads as a variant of `ENV` when it is meant to be its opposite, and the opposite is the point. The grammar permits alternatives, so this is revisable at epic time without a parser change.

### AD2 — FR6 is fixed by class, not by MoSCoW heading

**Choice**: the Scope-deferral exclusion refuses to exclude a label whose prefix marks it environmental, independent of its heading.

**Rationale**: today's guard is `!is_must(heading)`, and environmental constraints carry `Non-Functional`, so it does not reach them.

**Alternatives considered**: widening `is_must` to include `Non-Functional` — over-broad, since deferring an ordinary NFR via Scope is legitimate and this would forbid it.

**Implementation constraint (Margot)**: the class check must have **one** definition shared by `coverage-rollup.sh` and `cpm:epics`. Two places that decide "is this environmental" will drift.

### AD3 — `cpm:epics` gap-checks against Must Have ∪ environmental constraints

**Choice**: an uncovered environmental constraint is a blocker like a must-have, not a warning like a should-have.

**Rationale**: a design that cannot deploy is not a partial delivery.

**Alternatives considered**: treating them as warnings, consistent with should-haves — rejected because the warning is exactly what gets skipped in an autonomous run.

### AD4 — The rule is stated per-skill, not in `cpm/shared/skill-conventions.md`

**Choice**: state the labelling convention in each of `spec`, `brief` and `epics` rather than in the shared conventions file.

**Rationale**: three consumers sits exactly on the boundary CLAUDE.md draws, and that file's own baseline note treats "three skills or fewer" as a candidate for relocation *out* of shared. Stating it three times costs less than growing the file every session loads unconditionally.

**Alternatives considered**: a shared section — rejected on the add-path/remove-path asymmetry CLAUDE.md documents.

### AD5 — Inheritance mirrors ADR Discovery

**Choice**: a startup check that globs the problem brief, presents what is known, facilitates only gaps, and degrades silently when absent.

**Rationale**: the shape `spec/SKILL.md:21-29` already uses — a known-good pattern rather than a new one.

**Alternatives considered**: reading the product brief — rejected, that is the hop where the information dies.

### AD6 — A `[target]` test approach tag, distinct from `[manual]`

**Choice**: add a sixth tag for criteria that are mechanically checkable but only against the real deployment target.

**Rationale**: `[manual]` means *a human judges it* — no automation is possible in principle. Target-only constraints are the opposite: the check is mechanical, only the environment is missing. Collapsing them into `[manual]` means an autonomous run treats them as self-assessment, and self-assessing "runs on PHP 8.2" from a sandbox where it does is exactly the false pass this spec exists to stop.

**Alternatives considered**: `[manual]` with the required justification line — smaller blast radius, but leaves the self-assessment hole open, which makes AD3's blocker unverifiable and therefore overridable.

**Consequence**: `cpm:epics` propagation and `cpm:do` verification-approach selection both learn a sixth tag.

## Scope

### In Scope

- `cpm/skills/spec/SKILL.md` — the elicitation step, the inheritance startup check, the template's label conventions, and the `[target]` tag in the vocabulary
- `cpm/skills/brief/SKILL.md` — a Constraints section in the output template, so the preferred spec input stops discarding them
- `cpm/skills/epics/SKILL.md` — the cross-epic gap check extended to environmental constraints, and `[target]` tag propagation
- `cpm/skills/do/SKILL.md` — verification-approach selection for `[target]` criteria only
- `cpm/skills/ralph/SKILL.md` — the autonomous prompt's statement of what completes a task
- `cpm/hooks/lib/coverage-rollup.sh` — the class-based deferral guard (AD2)
- `cpm/hooks/tests/` — suites for all of the above

### Out of Scope

- Automated verification against a real deployment target. Constraints are recorded and falsifiable; nothing in CPM connects to a host.
- Redesigning the requirement grammar in `coverage-parse.sh`. AD1 exists precisely so this is not needed.
- How a project-stable fact becomes a per-spec traced requirement without hand-copying — the library/ADR deduplication tension.
- `cpm:do`'s Test Runner Discovery itself. FR9 makes constraints drive installation; it does not rewrite discovery. This is a different part of `cpm:do` from the `[target]` handling listed In Scope.

### Deferred

- FR11, FR12 — the `cpm:discover` restructuring and `cpm:status` reporting. Both are could-haves that depend on the core mechanism existing first.

*This bullet leads with its labels deliberately: `coverage-rollup.sh` defers only the labels a `### Deferred` bullet leads with. This is the first spec to rely on the Scope-exclusion rule shipped on 2026-07-26 — a reader watching the untraced count drop when this spec is created is seeing that rule work, not a bug (Ren).*

**Sequencing note (Jordan)**: FR8 is one line of template in `cpm:brief`, but it is the hop where everything currently dies. It wants sequencing early rather than picked up last.

## Testing Strategy

### Tag Vocabulary

Test approach tags used in this spec:

- `[unit]` — Unit tests targeting individual components in isolation
- `[integration]` — Integration tests exercising boundaries between components
- `[feature]` — Feature/end-to-end tests exercising complete user-facing workflows
- `[manual]` — Manual inspection, observation, or user confirmation. *A human judges it; no automation is possible in principle.*
- `[target]` — Mechanically checkable, but only against the real deployment target. *Automatable, but not here.* Introduced by AD6; not self-assessable in an autonomous run.
- `[tdd]` — Workflow mode: task follows red-green-refactor loop. Composable with any level tag (e.g. `[tdd] [unit]`). Orthogonal — describes how to work, not what kind of test.

### Acceptance Criteria Coverage

| Requirement | Acceptance Criterion | Test Approach |
|---|---|---|
| FR1 | A spec authored with no upstream documents still reaches the constraints step, and produces either labelled entries or an explicit "none apply" | `[manual]` |
| FR2 | A fixture spec carrying `ENV1` under `## Non-Functional Requirements` emits a `REQ` record and appears in `SUMMARY`'s untraced count | `[integration]` |
| FR2 | must NOT — an `ENV` label is dropped silently when no matrix covers it | `[integration]` |
| FR3 | `ENV` and `ENVX` labels are reported as distinguishable classes, not merged into one count | `[integration]` |
| FR4 | The step refuses an entry with no checkable condition, naming which entry | `[manual]` |
| FR5 | With a problem brief carrying `## Constraints`, the step presents those entries rather than re-asking; with none, it facilitates from scratch and emits no error | `[manual]` |
| FR5 | must NOT — reads the product brief as the constraint source | `[manual]` |
| FR6 | A fixture spec naming `ENV1` in a `### Deferred` bullet leaves `ENV1` untraced, not `EXCLUDED` | `[integration]` |
| FR6 | control — an ordinary `NFR1` named the same way **is** still excluded | `[integration]` |
| FR7 | The requirement classes `cpm:epics`' gap check treats as blocking are the same set `coverage-rollup.sh` treats as blocking | `[integration]` |
| FR8 | A product brief produced by `cpm:brief` from a problem brief with constraints carries them into its output | `[manual]` |
| FR10 | A criterion tagged `[target]` is not self-assessed as passing in an autonomous run; it is reported as unverifiable in this environment | `[integration]` |
| FR10 | must NOT — `[target]` is treated as a synonym for `[manual]` by the propagation or selection logic | `[integration]` |
| NFR1 | Records for all 45 existing specs are byte-identical before and after | `[integration]` |
| NFR4 | `REQ = STATE ∪ EXCLUDED` is an exact partition with `ENV`/`ENVX` in play, asserted against the repo's real specs and not only fixtures | `[integration]` |
| NFR5 | Suites pass with failing `jq` and `python3` stubs first on `PATH` | `[integration]` |
| NFR6 | Each skill's stated byte delta matches its actual | `[integration]` |

FR7's criterion is deliberately a **correspondence** assertion between the two components rather than a grep of either side — the lesson of retro 24, where a template's `on 3` was changed to a code the script never returned and every assertion stayed green.

Four of the nine must-haves — FR1, FR4, FR5, FR8 — are `[manual]`, because they specify facilitation behaviour in prose and have no automatable oracle. That is honest rather than satisfactory, and it is the same structural weakness that produced this spec's subject.

### Integration Boundaries

Three seams:

1. **Spec template → `coverage-parse.sh`** — the label grammar `[A-Z]+[0-9]+`. AD1 depends on it; it is verified, not assumed.
2. **`coverage-rollup.sh` exclusion rules → the environmental class definition** (AD2).
3. **`cpm:epics` gap check → the same class definition** (AD3).

Margot's constraint applies at the second and third: one definition, not two.

### Test Infrastructure

None required, and no builder change either. `cpm/hooks/tests/coverage-fixture-helpers.sh` already accepts an arbitrary label via `--nfr`, and `--deferred` already lifts an `ENV` label from a Scope bullet — both verified empirically during work breakdown. An earlier draft of this section called for new `--env`/`--envx` options; they are not needed.

Bella's constraint on NFR4: the partition assertion runs against the repo's real specs, not only fixtures — that is what caught the spec 45 regression.

### Unit Testing

Unit testing of individual components is handled at the `cpm:do` task level — each story's acceptance criteria drive test coverage during implementation.
