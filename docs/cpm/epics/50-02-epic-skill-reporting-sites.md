# Skill Reporting Sites

**Source spec**: docs/specifications/50-spec-report-disposition.md  
**Date**: 2026-08-16  
**Status**: Complete  
**Blocked by**: Epic 50-01-epic-disposition-vocabulary  
**Retro applied**: 54 · Testing gaps · Applied — every one of the eleven tasks edits a SKILL.md, so the whole `dpm` suite runs after each rather than the story's own file; `reachability.test.js` and the corpus sweeps are the ones that guard skill prose and none is an obvious choice.  
**Retro applied**: 54 · Testing gaps · Applied — Story 4's two must-NOT sweeps each plant the forbidden condition in a fixture and are confirmed failing before they are trusted; a sweep over prose that no longer mentions dispositions passes vacuously.  
**Retro applied**: 54 · Patterns worth reusing · Applied — the eight skills cite the `disposition` domain and read its terms rather than writing the labels out, and the tests derive expectations from `VOCABULARIES` rather than a transcribed list.  
**Retro applied**: 55 · Patterns worth reusing · Applied — FR8's naming check is paired with its complement: containment proves only that the three edited skills were edited, so the sweep also asks whether any disposition-like wording survives anywhere in the corpus outside the domain.

## Derive `do`'s reports from its rows

**Story**: 1  
**Status**: Complete  
**Blocked by**: —  
**Satisfies**: FR6, FR7, FR10  
**Retro**: [Pattern worth reusing] Expressing each disposition by the reader's obligation rather than by its label let `do` satisfy both FR6 and FR10's must-NOT in one paragraph — the derivation reads naturally without the labels, so the vocabulary stays in the domain where a project can extend it.

Its own story because it carries three edit sites and one removal, which is a different shape of work
from adding a sentence: FR6 and FR7 both land in Step 8.

**Acceptance Criteria**:

- `do` Step 8's epic summary is derived from the coverage rows, story observations and change-moment resolutions rather than narrated beside them [unit]
- `do`'s change-moment resolutions are reported with their disposition [unit]
- `do`'s autonomous section references the shared vocabulary and its standalone "surface the two sets separately" phrasing is gone — both halves asserted [unit]
- `do` names the `disposition` domain rather than listing the four labels [unit]

### Rewrite Step 8's report as a derivation from rows

**Task**: 1.1  
**Description**: Covers the epic-summary and change-moment criteria. Step 8 already distinguishes a claim from a computation; this extends that distinction to the report itself rather than replacing it.  
**Status**: Complete

### Reconcile the autonomous section with the shared vocabulary

**Task**: 1.2  
**Description**: Covers FR7. The removal half matters as much as the addition — the standalone "surface the two sets separately" instruction goes, so the run has one vocabulary.  
**Status**: Complete

### Write tests for Derive `do`'s reports from its rows

**Task**: 1.3  
**Description**: Write automated tests covering the story's [unit] criteria. FR7's test asserts both halves: presence alone passes with the old phrasing still in place.  
**Status**: Complete

---

## Derive the four remaining row-backed reports

**Story**: 2  
**Status**: Complete  
**Blocked by**: —  
**Satisfies**: FR6  
**Retro**: [Pattern worth reusing] Each of the four sites already held the states its disposition derives from — `quick`'s tri-state, `review`'s three finding states, `pivot`'s changed-criteria split, `audit`'s `recommendation` — so the rule named an existing distinction at every site rather than introducing one, which is why four edits took one pass and broke nothing.

**Acceptance Criteria**:

- `quick` Step 4 reports each criterion's disposition derived from its tri-state `met` [unit]
- `review` reports each finding's disposition derived from whether it carries a `remediation_task_id` [unit]
- `pivot` Phase 4 reports affected tasks with their disposition [unit]
- `audit` reports each finding with its disposition [unit]

### Add the derivation rule to `quick` Step 4 and `review`'s findings step

**Task**: 2.1  
**Description**: `quick` derives from the tri-state `met`; `review` from whether a finding carries a `remediation_task_id`. Grouped because both derive from a single column per item.  
**Status**: Complete

### Add the derivation rule to `pivot` Phase 4 and `audit`'s findings step

**Task**: 2.2  
**Description**: Both report a set produced by the step that precedes them, so the derivation names that set rather than a column.  
**Status**: Complete

### Write tests for Derive the four remaining row-backed reports

**Task**: 2.3  
**Description**: Write automated tests covering the story's [unit] criteria — one per site, so a missing derivation names the skill it is missing from.  
**Status**: Complete

---

## Adopt the labels at the report-only sites

**Story**: 3  
**Status**: Complete  
**Blocked by**: —  
**Satisfies**: FR8  
**Retro**: These three sites had no rows to derive from, so the disposition had to come from the run itself — and that exposed a state the private wordings had no room for. "Stamped and skipped" and "deleted and left" are both complete accounts of what a finished run did and misleading accounts of an interrupted one, because neither pair has a slot for what the run never reached. Replacing a two-outcome pair with a four-term vocabulary is not a relabelling; it adds the case the pair could not express.

**Acceptance Criteria**:

- `inspect` Step 6 names the `disposition` domain and reports its findings with their disposition [unit]
- `archive`'s "Report what was stamped and what was skipped" is expressed as Fixed and Left alone [unit]
- `clean`'s "Report what was deleted, what was left" is expressed as Fixed and Left alone [unit]

### Replace `clean`'s and `archive`'s private wordings with the shared labels

**Task**: 3.1  
**Description**: `clean:86` and `archive:136` already carry proto-dispositions. This is a replacement, not an addition — the private wording goes, which is what makes Story 4's first sweep meaningful.  
**Status**: Complete

### Add the disposition rule to `inspect` Step 6

**Task**: 3.2  
**Description**: `inspect` reports findings without acting on them, so it takes the labels without the derivation rule.  
**Status**: Complete

### Write tests for Adopt the labels at the report-only sites

**Task**: 3.3  
**Description**: Write automated tests covering the story's [unit] criteria.  
**Status**: Complete

---

## Verify cross-story integration for skill reporting sites

**Story**: 4  
**Status**: Complete  
**Blocked by**: Story 1, Story 2, Story 3  
**Satisfies**: FR1 (must NOT), FR4, FR6 (must NOT), FR10 (must NOT)  
**Retro**: Each of the three sweeps was first written so that it could not fail — a phrase-present match, a label check whose control only asserted the fixture contained a label, and a derivation check that tested `String.replace` rather than the reading. All three passed on the first run, which is what a vacuous sweep looks like. What fixed them was the same move each time: extract the reading into a function taking a `read(skill)` callback, then drive it against a corpus with the defect planted. A must-NOT that cannot be handed a broken corpus is a must-NOT nobody has checked.

Every sweep here is a claim about the eight files together, and each is unsatisfiable — or worse,
vacuously true — until Stories 1–3 have landed. That is why both must-NOT sweeps sit on this epic
rather than on 50-01.

**Acceptance Criteria**:

- must NOT define a disposition term privately in any skill file. Control: `clean:86` and `archive:136` fail this before the change [unit]
- must NOT hardcode a disposition label string in any skill file. Control: a fixture skill file carrying one fails the sweep [unit]
- must NOT retain an instruction to summarise alongside the rows without deriving from them at any of the five row-backed sites. Control: removing the derivation sentence from any one site fails that site's test [unit]
- One real report from each of `do`, `quick` and `clean`: the reader can stop after the third block having missed nothing actionable [manual] — evaluating a generated report needs a reader; no assertion reaches it

### Write the three cross-site sweeps

**Task**: 4.1  
**Description**: One corpus test per sweep: no private disposition term, no hardcoded label string, no site retaining a narrated summary. Each carries the control named in its criterion — a sweep that cannot fail is the defect this epic is most exposed to.  
**Status**: Complete

### Read one real report from `do`, `quick` and `clean`

**Task**: 4.2  
**Description**: The [manual] criterion. Run each skill and judge whether the reader can stop after the third block. This is the only check that tests the goal rather than the mechanism.  
**Status**: Complete

---

## Notes

**`do` Step 8's derivation bullets are not in render order.** The four bullets defining which row
state yields which disposition run Fixed, Unverified, Left alone, Needs you — the order the
derivation falls out in — while the sentence introducing them requires the summary to be rendered in
the domain's `position` order, which puts Left alone second. Raised at Story 4's `[manual]` gate and
left as it stands: the rule names `position` explicitly and the bullets are definitions rather than a
sequence. Recorded because it is a plausible way to get FR4 wrong, and a later reader finding the two
orders disagreeing should know it was seen.

**Empty dispositions are omitted, decided after the epic closed.** FR3 closes the set at the item
level and nothing closed it at the block level, so the first report rendered under this epic printed
"Left alone — nothing was skipped" and "Unverified — nothing" and read as the padding the whole
vocabulary exists to remove. Chris chose omission for all four, including Needs you — the
alternative offered was to keep an always-present Needs-you line so "nothing is waiting on you" was
said rather than inferred. The rule is one paragraph in `dpm/shared/skill-conventions.md`, which all
eight sites already defer to; `audit` and `inspect` each lost a sentence describing their unfillable
first block as rendered-but-empty. Covered by `corpus.test.js`, with its control.
