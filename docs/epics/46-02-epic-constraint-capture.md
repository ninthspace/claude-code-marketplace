# Constraint Capture and Transmission

**Source spec**: docs/specifications/46-spec-environmental-requirements.md
**Date**: 2026-07-27
**Status**: Complete
**Blocked by**: Epic 46-01-epic-constraint-traceability
**Retro applied**: 26 · Codebase discoveries · Applied — Tasks 1.1, 1.2, 2.1 and 2.2 all change prose an existing suite may pin verbatim. Before each edit, grep `cpm/hooks/tests/` for assertions over the wording being changed, and re-read them as candidates for correction rather than discovering them as failures.
**Retro applied**: 25 · Codebase discoveries · Applied — Story 4's inheritance check and Story 5's chain assertion both claim one skill reads what another writes. Open `discover/SKILL.md` and `brief/SKILL.md` before writing either sentence, and assert the fact with a grep rather than asserting the sentence.
**Retro applied**: 23 · Testing gaps · Applied — Story 2's must-NOT forbids `## Environment`; grep `spec/SKILL.md` for legitimate mentions first and narrow the haystack to the output template. Carried as a lens over every `assert_not_contains` this epic writes, not just Task 2.3's.
**Retro applied**: 23 · Patterns worth reusing · Applied — every automated criterion here asserts over SKILL.md prose, so each new suite header states which assertions are oracles (Story 5's chain correspondence, Story 4's glob targets) and which are regression nets over wording.

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
**Status**: Complete
**Blocked by**: —
**Satisfies**: FR8

**Inline change**: `spec/SKILL.md:17`'s enumeration of what a product brief contains gained `and constraints` — it is the sentence spec 46's problem statement cites as the reason the omission was invisible, and no story criterion covered it (2026-07-27)

Sequenced first per Jordan's note in the spec's Section 5 perspectives: one line of template, and
the hop where everything currently dies.

**Acceptance Criteria**:

- The product brief output template carries a `## Constraints` section [integration]
- must NOT — constraints are added to the skill's facilitation questions only, leaving the output template unchanged (the current defect, at `brief/SKILL.md:66` and `:75`) [integration]
- A product brief produced by `cpm:brief` from a problem brief with constraints carries them into its output [manual] — facilitation behaviour, no automatable oracle

**Retro**: [Codebase discovery] Two skills already described the product brief's constraints and
one of them was right: `architect/SKILL.md:78` has been instructing a reader to summarise "the
vision, key features, and constraints" from a product brief that had no constraints section, while
`spec/SKILL.md:17` listed the three sections it did have and thereby made the fourth's absence
invisible. This is retro 25's named-consumer finding inverted — there a producer named a consumer
that did not consume, here a consumer named a producer's section that did not exist — and the same
grep answers both. Reading every skill that describes an artefact's contents is cheap before adding
a section to it, and it found one stale sentence and one that had been waiting to become true.

### Add the `## Constraints` section to the product brief output template
**Task**: 1.1
**Description**: Placement after Key Features and before Differentiation — constraints bound what the features can be. Covers criterion 1.
**Status**: Complete

### Point the existing facilitation questions at the new section
**Task**: 1.2
**Description**: `brief/SKILL.md:66` and `:75` already ask about constraints and discard the answers. This is the wiring that stops that, and it is what the must-NOT criterion asserts.
**Status**: Complete

### Write tests for `cpm:brief` carries constraints forward
**Task**: 1.3
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]`. Both are regression nets over prose, not oracles — say so in the suite header (retro 23).
**Status**: Complete

---

## `cpm:spec` elicits environmental requirements and restrictions
**Story**: 2
**Status**: Complete
**Blocked by**: —
**Satisfies**: FR1, FR3 (partial — the document half), FR9

**Acceptance Criteria**:

- A spec authored with no upstream documents still reaches the constraints step, and produces either labelled entries or an explicit "none apply" [manual] — facilitation behaviour, no automatable oracle
- The step covers both development and production, and both what must be available and what must not be required [manual] — as above
- The step asks about development tooling explicitly — test runner, browser automation — not only production environment [manual] — as above
- The spec output template documents `ENVn` for requirements and `ENVXn` for restrictions under `## Non-Functional Requirements` [integration]
- must NOT — a new `## Environment` section is introduced, which AD1 rejected and `coverage-parse.sh` cannot read [integration]

**Retro**: [Testing gap] The story's one real oracle — feed the labels the template advertises to
`coverage_environmental_class`, so the advertised grammar and the implemented grammar are checked
to be the same grammar — was **circular as first written**, because the extractor pulling labels
out of the template matched only `ENV`/`ENVX` prefixes. It therefore could not surface the single
thing it existed to catch: a template telling authors to write a label the predicate rejects. Under
the mutation written for it (`ENV1` → `ENVIRONMENT1`) the oracle passed vacuously on the surviving
label while only its non-vacuity control fired, and the gap was visible solely because the mutation
was run and its failures read line by line rather than counted. Fixed by extracting with AD1's
whole `[A-Z]+[0-9]+` grammar and adding `NFR1`, which must classify as empty, as an in-line
discrimination control. The general form: when an assertion checks that a document agrees with a
predicate, the extractor must not share the predicate's definition, or it can only ever find
agreement.

Separately, the must-NOT is an inventory of the output template's `## ` headings rather than an
`assert_not_contains` over the file. The naive form passes today only because nothing in
`spec/SKILL.md` mentions the rejected section, and it would fail the moment someone documents *why*
AD1 rejected it — a legitimate edit, and retro 23's trap exactly. Step 3a was therefore written to
state the rule positively and never name the forbidden section.

### Add the constraint elicitation sub-step to Section 3
**Task**: 2.1
**Description**: Both classes, both environments, development tooling named explicitly. Covers criteria 1–3. Lands inside Section 3 per the design decision recorded in the epic header.
**Status**: Complete

### Add the `ENVn`/`ENVXn` label conventions to the spec output template
**Task**: 2.2
**Description**: Under the existing `## Non-Functional Requirements` heading. Covers criterion 4; the must-NOT is the assertion that this task did not reach for a new section instead.
**Status**: Complete

### Write tests for `cpm:spec` elicits environmental requirements and restrictions
**Task**: 2.3
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]`. Before writing the must-NOT as an `assert_not_contains`, check whether the skill legitimately mentions `## Environment` elsewhere — retro 23 found this exact assertion failing because the forbidden phrasing appeared in the sentence forbidding it.
**Status**: Complete

---

## Constraints are falsifiable or refused
**Story**: 3
**Status**: Complete
**Blocked by**: Story 2
**Satisfies**: FR4, NFR3

**Inline change**: `spec/SKILL.md`'s Ambiguity termination gained an "Except Step 3a" carve-out — it directed a TBD-and-proceed that contradicts NFR3's block, and a TBD sits in prose `coverage-parse.sh` never reads (2026-07-27)

**Acceptance Criteria**:

- The step refuses an entry with no checkable condition, naming which entry [manual] — judging falsifiability is the judgement itself
- An entry that is unparseable, unfalsifiable, or of an unrecognised class is reported and blocks, never silently dropped [manual] — as above

Fully manual, deliberately. FR4 asks whether a constraint states a checkable condition, and that
judgement is the thing being specified; an assertion that the rule is *present* in the prose is a
regression net that would read as coverage it does not provide.

**Retro**: [Codebase discovery] A new rule can be correct, well-placed, and still contradict the
document it was written into. Step 3a's fail-closed clause — an entry that cannot be made
falsifiable is reported and blocks — landed in a skill whose Termination section already directed
the opposite for exactly that situation: *"note both options in the spec with a 'TBD' marker and
proceed"*. Both are defensible policies and the collision is invisible from either end, because
neither mentions the other and they sit two hundred lines apart. What makes it more than a style
clash is that a "TBD" lives in prose `coverage-parse.sh` never reads, so the general policy's
outcome is precisely the silent drop NFR3 was written to forbid. Found by reading the skill's own
termination rules before assessing the criterion, rather than by reading the criterion against the
paragraph that satisfies it. Worth doing whenever a story adds a rule about what happens when the
work cannot proceed: the document almost certainly has one already.

### Add the falsifiability refusal and fail-closed handling to the elicitation sub-step
**Task**: 3.1
**Description**: No testing task accompanies this story — every criterion is `[manual]`, so there is nothing to automate and a generated test task would imply otherwise.
**Status**: Complete

---

## The step inherits rather than re-asks [plan]
**Story**: 4
**Status**: Complete
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

**Retro**: [Pattern worth reusing] Retro 23's `assert_not_contains`-over-prose trap turned up twice
in this one story, from opposite directions, and the two needed different repairs. Criterion 2
forbids routing by "most recent" — a phrase `spec/SKILL.md:18` already uses legitimately about a
different question, so a file-wide assertion fails on correct code. Criterion 3 forbids reading the
product brief as the constraint source — but the section has to *name* the product brief in order
to rule it out, so the forbidden token is unavoidable in the very sentence satisfying the criterion.
The first was answered by scoping to the section and counting: one mention, and that mention is the
prohibition. The second could not be answered by any absence assertion, and became a positive one —
the set of `docs/*/` directories the section routes to, asserted whole, so a quietly added
`docs/briefs/` fallback fails while every sentence still reads correctly.
 
The generalisable half is the **paired control**. Scoping a must-NOT to a slice makes it narrower;
it does not make it right. A repair that satisfied the narrowed assertion by deleting the
legitimate site elsewhere — Input step 3b's own recency rule — would have passed, so the suite also
asserts that site survives. Mutation M confirmed it: deleting Input step 3b fails the control and
nothing else. Whenever a must-NOT is scoped because its token is legitimate somewhere else, assert
that somewhere-else is still there, or the scoping has only moved the blind spot.

### Add the constraint inheritance startup check
**Task**: 4.1
**Description**: Mirrors ADR Discovery's shape (`spec/SKILL.md:21-29`) per AD5 — glob, present what is known, facilitate only gaps, degrade silently when absent. Resolves the problem brief by following the product brief's `**Source**` field rather than taking the most recent, which is what `cpm:spec`'s input resolution does at step 3b and is not the same question.
**Status**: Complete

### Write tests for The step inherits rather than re-asks
**Task**: 4.2
**Description**: Write automated tests covering the story's acceptance criteria tagged `[integration]`.
**Status**: Complete

---

## Verify cross-story integration for Constraint Capture and Transmission
**Story**: 5
**Status**: Complete
**Blocked by**: Story 1, Story 2, Story 3, Story 4
**Retro**: [Testing gap] The vacuous-completeness shape has a third form neither retro 23 nor
retro 25 names. Criterion 3's "all three documents name the same section" was first written as
a distinct-value count — `printf` the three, `sort -u | grep -c .`, expect `1`. `grep -c .`
skips the empty line, so a *one-sided* empty extraction still counts 1 and the comparison
passes; only its control fired. The assertion covering the criterion that demands non-emptiness
was itself vacuous under exactly the mutation that criterion describes. Replaced with pairwise
equality, which has no such hole. Worth generalising: a completeness claim asserted as a
*count* of distinct values silently absorbs the degenerate value, whereas the same claim
asserted as an *equality* cannot.
**Satisfies**: NFR2 (the end-to-end degradation path)

**Acceptance Criteria**:

- The documented chain resolves: `cpm:spec`'s inheritance glob targets the directory `cpm:discover` writes problem briefs to, and the field it follows is the field `cpm:brief` writes [integration]
- Both extractions in the assertion above are non-empty before they are compared [integration]
- A problem brief carrying `## Constraints` reaches a spec's `## Non-Functional Requirements` as `ENV`/`ENVX` labels, verified hop by hop [manual]

### Write integration tests for the constraint chain
**Task**: 5.1
**Description**: The first criterion is retro 25's pattern — derive the write path from `discover/SKILL.md` and the read glob from `spec/SKILL.md` and assert they agree, rather than pinning both to a literal. The second criterion exists because retro 23 found three assertions in exactly this shape gone vacuous: two empty extractions compare equal, and the suite reports green.
**Status**: Complete

---
