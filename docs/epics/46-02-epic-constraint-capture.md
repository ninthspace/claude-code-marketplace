# Constraint Capture and Transmission

**Source spec**: docs/specifications/46-spec-environmental-requirements.md
**Date**: 2026-07-27
**Status**: Pending
**Blocked by**: Epic 46-01-epic-constraint-traceability

The authoring half: `cpm:brief` stops discarding constraints, and `cpm:spec` gains the elicitation
step, the two classes, the falsifiability refusal, and the inheritance startup check.

Blocked by 46-01 because the labels this epic teaches authors to write are only safe once the guard
protecting them from a Scope deferral exists. Writing `ENV1` into a spec before that guard lands
reproduces Hazard A on live documents.

**Design decision made at breakdown**: the elicitation step becomes a **sub-step of Section 3
(Non-Functional Requirements)**, not an eighth section. AD1 already decided environmental
constraints *are* non-functional requirements; giving them their own section would contradict the
decision that made them traceable, and it is the cheaper option against NFR6's bounded-facilitation
requirement.

## `cpm:brief` carries constraints forward
**Story**: 1
**Status**: Pending
**Blocked by**: —
**Satisfies**: FR8

Sequenced first per Jordan's note in the spec's Section 5 perspectives: one line of template, and
the hop where everything currently dies.

**Acceptance Criteria**:

- The product brief output template carries a `## Constraints` section [integration]
- must NOT — constraints are added to the skill's facilitation questions only, leaving the output template unchanged (the current defect, at `brief/SKILL.md:66` and `:75`) [integration]
- A product brief produced by `cpm:brief` from a problem brief with constraints carries them into its output [manual] — facilitation behaviour, no automatable oracle

### Add the `## Constraints` section to the product brief output template
**Task**: 1.1
**Description**: Placement after Key Features and before Differentiation — constraints bound what the features can be. Covers criterion 1.
**Status**: Pending

### Point the existing facilitation questions at the new section
**Task**: 1.2
**Description**: `brief/SKILL.md:66` and `:75` already ask about constraints and discard the answers. This is the wiring that stops that, and it is what the must-NOT criterion asserts.
**Status**: Pending

### Write tests for `cpm:brief` carries constraints forward
**Task**: 1.3
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]`. Both are regression nets over prose, not oracles — say so in the suite header (retro 23).
**Status**: Pending

---

## `cpm:spec` elicits environmental requirements and restrictions
**Story**: 2
**Status**: Pending
**Blocked by**: —
**Satisfies**: FR1, FR3 (partial — the document half), FR9

**Acceptance Criteria**:

- A spec authored with no upstream documents still reaches the constraints step, and produces either labelled entries or an explicit "none apply" [manual] — facilitation behaviour, no automatable oracle
- The step covers both development and production, and both what must be available and what must not be required [manual] — as above
- The step asks about development tooling explicitly — test runner, browser automation — not only production environment [manual] — as above
- The spec output template documents `ENVn` for requirements and `ENVXn` for restrictions under `## Non-Functional Requirements` [integration]
- must NOT — a new `## Environment` section is introduced, which AD1 rejected and `coverage-parse.sh` cannot read [integration]

### Add the constraint elicitation sub-step to Section 3
**Task**: 2.1
**Description**: Both classes, both environments, development tooling named explicitly. Covers criteria 1–3. Lands inside Section 3 per the design decision recorded in the epic header.
**Status**: Pending

### Add the `ENVn`/`ENVXn` label conventions to the spec output template
**Task**: 2.2
**Description**: Under the existing `## Non-Functional Requirements` heading. Covers criterion 4; the must-NOT is the assertion that this task did not reach for a new section instead.
**Status**: Pending

### Write tests for `cpm:spec` elicits environmental requirements and restrictions
**Task**: 2.3
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]`. Before writing the must-NOT as an `assert_not_contains`, check whether the skill legitimately mentions `## Environment` elsewhere — retro 23 found this exact assertion failing because the forbidden phrasing appeared in the sentence forbidding it.
**Status**: Pending

---

## Constraints are falsifiable or refused
**Story**: 3
**Status**: Pending
**Blocked by**: Story 2
**Satisfies**: FR4, NFR3

**Acceptance Criteria**:

- The step refuses an entry with no checkable condition, naming which entry [manual] — judging falsifiability is the judgement itself
- An entry that is unparseable, unfalsifiable, or of an unrecognised class is reported and blocks, never silently dropped [manual] — as above

Fully manual, deliberately. FR4 asks whether a constraint states a checkable condition, and that
judgement is the thing being specified; an assertion that the rule is *present* in the prose is a
regression net that would read as coverage it does not provide.

### Add the falsifiability refusal and fail-closed handling to the elicitation sub-step
**Task**: 3.1
**Description**: No testing task accompanies this story — every criterion is `[manual]`, so there is nothing to automate and a generated test task would imply otherwise.
**Status**: Pending

---

## The step inherits rather than re-asks [plan]
**Story**: 4
**Status**: Pending
**Blocked by**: Story 1, Story 2
**Satisfies**: FR5, NFR2, AD5

**Acceptance Criteria**:

- The inheritance glob targets `docs/plans/[0-9]*-plan-*.md` and `docs/architecture/[0-9]*-adr-*.md` [integration]
- The problem brief is located by following the product brief's `**Source**` field, not by "most recent" [integration]
- must NOT — reads the product brief as the constraint source [integration]
- With a problem brief carrying `## Constraints`, the step presents those entries rather than re-asking [manual] — facilitation behaviour
- With no problem brief, no ADRs, or a brief with no `## Constraints`, the step still runs and facilitates from scratch, silently — absence is never an error and never a prompt [manual] — as above

`[plan]` because the resolution path spans three skills' documents and their write conventions;
getting it wrong reproduces the defect one hop further along.

The first three criteria are stronger than spec 46 tagged them (`[manual]`). Following the product
brief's `**Source**` field makes the resolution path structural fact rather than facilitation
behaviour, so it has an oracle the spec did not anticipate.

### Add the constraint inheritance startup check
**Task**: 4.1
**Description**: Mirrors ADR Discovery's shape (`spec/SKILL.md:21-29`) per AD5 — glob, present what is known, facilitate only gaps, degrade silently when absent. Resolves the problem brief by following the product brief's `**Source**` field rather than taking the most recent, which is what `cpm:spec`'s input resolution does at step 3b and is not the same question.
**Status**: Pending

### Write tests for The step inherits rather than re-asks
**Task**: 4.2
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]`.
**Status**: Pending

---

## Verify cross-story integration for Constraint Capture and Transmission
**Story**: 5
**Status**: Pending
**Blocked by**: Story 1, Story 2, Story 3, Story 4
**Satisfies**: NFR2 (the end-to-end degradation path)

**Acceptance Criteria**:

- The documented chain resolves: `cpm:spec`'s inheritance glob targets the directory `cpm:discover` writes problem briefs to, and the field it follows is the field `cpm:brief` writes [integration]
- Both extractions in the assertion above are non-empty before they are compared [integration]
- A problem brief carrying `## Constraints` reaches a spec's `## Non-Functional Requirements` as `ENV`/`ENVX` labels, verified hop by hop [manual]

### Write integration tests for the constraint chain
**Task**: 5.1
**Description**: The first criterion is retro 25's pattern — derive the write path from `discover/SKILL.md` and the read glob from `spec/SKILL.md` and assert they agree, rather than pinning both to a literal. The second criterion exists because retro 23 found three assertions in exactly this shape gone vacuous: two empty extractions compare equal, and the suite reports green.
**Status**: Pending

---
