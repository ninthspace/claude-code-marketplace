# Shared Convention Restructure

**Source spec**: docs/specifications/41-spec-artifact-pivot.md
**Date**: 2026-07-25
**Status**: Complete
**Blocked by**: —
**Retro applied**: 11 · Patterns worth reusing · Applied — Task 2.3 authors the canonical reference line and stops there; propagation to the ten skills is 41-03's work, verified by `grep | sort | uniq -c` for count and identity together.
**Retro applied**: 12 · Codebase discoveries · Applied — Story 1's `Tier 1|Tier 2` grep is a phrase-shaped sweep; each hit is judged by what its rule does before deletion, which is what protects the export-affordance pattern Story 41-02.4 depends on.
**Retro applied**: 14 · Patterns worth reusing · Applied — the convention rewrite collapses restated rules to a single plain statement; the reduction comes from removing repetition, not from removing rules.
**Retro applied**: 14 · Testing gaps · Applied — pre-work baseline captured (all suites passing, 2026-07-25); `check_valid_fragment` tests assert structural properties rather than pinned strings.

## Reduce HTML Output to companion assets
**Story**: 1
**Status**: Complete
**Blocked by**: —
**Satisfies**: R3
**Inline change**: Task 1.2 extended beyond `skill-conventions.md` to `status/SKILL.md:151` and `epics/SKILL.md:371` — both referenced the retired *Tier 2 export affordances* section, and leaving them dangling for the whole 41-01→41-02 window would ship a broken reference. Criterion text unchanged; 41-02 inherits those sections already clean. (2026-07-25)

**Acceptance Criteria**:

- `## HTML Output`'s opening paragraph names one role (companion assets), not three [integration]
- The storage-path table retains the companion-asset row and no other [integration]
- `grep -rn "Tier 1\|Tier 2" cpm/ --include="*.md"` returns zero hits [integration]
- The canonical export-affordance pattern (copy-as-prompt / copy-as-JSON) is **relocated** into the Artifact Publishing section, not deleted [integration]
- must NOT delete the *Companion-asset content: shared chrome vs. system-specific mockups* subsection [integration]
- must NOT delete the self-contained rule or the generate-from-source rule [integration]

### Rewrite the HTML Output opening and storage table
**Task**: 1.1
**Description**: Covers the first two criteria — reduce the three-role framing to companion assets alone and strip the faithful-render and `present`-communication rows from the storage table. Leaves the shared-chrome subsection and the self-contained rule in place; those are protected by the must-NOTs.
**Status**: Complete

### Relocate the export-affordance pattern and retire the Tier vocabulary
**Task**: 1.2
**Description**: Covers the Tier-hit and relocation criteria. The Tier 1/Tier 2 distinction exists only to permit inline JS in the two local tracking documents; once those are artifacts it has nothing left to distinguish. Move the canonical copy-button pattern into Artifact Publishing rather than deleting it — Story 41-02.4 depends on it surviving.
**Status**: Complete

### Write tests for reducing HTML Output to companion assets
**Task**: 1.3
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`, `[integration]`, or `[feature]`.
**Status**: Complete

**Retro**: [Criteria gap] A criterion phrased as a repo-wide grep (`grep -rn … cpm/`) implicitly claims repo-wide *edit* scope — two of this one's seven hits sat in files owned by epic 41-02, so the criterion could not be satisfied within the epic's own boundary; 41-03 and 41-04 each carry grep-shaped criteria with the same latent conflict, and scoping the grep to the files the epic owns would have surfaced it at planning time.

---

## Promote Artifact Publishing and define the canonical reference line [plan]
**Story**: 2
**Status**: Complete
**Blocked by**: —
**Satisfies**: R3, R5, AD2, AD4
**Inline change**: Final must-NOT narrowed from "at any site" to `cpm/shared/skill-conventions.md`. All six remaining sites are owned by later epics — `spec`/`architect`/`review` inside faithful-render sections 41-04 deletes, `present`/`status`/`epics` inside sections 41-02 rewrites — and 41-03 Story 1 removes them as a necessary side effect, since its own must-NOT forbids variant phrasings and the old line is a variant of the new one. Deleting them here would leave six skills with no publishing instruction until 41-03 runs. (2026-07-25)

**Acceptance Criteria**:

- `Artifact Publishing` is an `##` top-level section, not nested under HTML Output [integration]
- Mechanics step 2 instructs composing the page per the `artifact-design` skill, not re-emitting `cpm/assets/html/template.html` as a fragment [integration]
- One canonical reference line is recorded in the convention, worded so it holds for skills that produce no local HTML [integration]
- The register row and the `**Artifacts**:` backlink are stated as part of publishing, not as a follow-up step [integration]
- must NOT allow any publishing path that omits the register row or the `**Artifacts**:` backlink [integration]
- must NOT retain the phrase "Any HTML output here can additionally be published" in `cpm/shared/skill-conventions.md` [integration]

### Promote and rewrite the Artifact Publishing section
**Task**: 2.1
**Description**: Covers the section-level and register criteria. After the pivot most publishing has no local HTML at all, so the current nesting under HTML Output makes every reference site inherit a false premise.
**Status**: Complete

### Switch the publishing mechanics to artifact-design
**Task**: 2.2
**Description**: Covers the mechanics-step-2 criterion (AD2). Replaces "re-emit template.html as a body fragment" with composition per `artifact-design`. The template keeps governing local companion assets; this only changes what governs a published page.
**Status**: Complete

### Author the canonical reference line
**Task**: 2.3
**Description**: Produces the single string that Epic 41-03 propagates to ten skills. Scope boundary: author and record it here only — propagation is 41-03's work, and this task must not edit any SKILL.md.
**Status**: Complete

### Write tests for Artifact Publishing promotion
**Task**: 2.4
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`, `[integration]`, or `[feature]`.
**Status**: Complete

**Retro**: [Criteria gap] Second instance of the pattern Story 1's retro predicted — a criterion phrased as a repo-wide constraint ("at any site") implicitly claims repo-wide edit scope, which conflicts with per-epic file ownership; both instances were resolvable, but two in one epic makes it a criteria-design rule rather than an incident, and 41-03/41-04 each carry more of the same shape.

---

## Add check_valid_fragment to the validator library
**Story**: 3
**Status**: Complete
**Blocked by**: Story 2
**Satisfies**: R7

**Acceptance Criteria**:

- `check_valid_fragment` rejects `<!doctype>`, `<html>`, `<head>` and `<body>` [integration]
- `check_valid_fragment` accepts a leading `<style>` block [integration]
- `check_valid_fragment` asserts self-containment on the artifact scratch path `docs/plans/{skill}-artifact-{nn}-{slug}.html` [integration]

### Implement the fragment validator
**Task**: 3.1
**Description**: Adds one validator to the existing `html-test-helpers.sh` — no new infrastructure. Blocked by Story 2 because the fragment shape it asserts is defined by that story's mechanics rewrite.
**Status**: Complete

### Write tests for check_valid_fragment
**Task**: 3.2
**Description**: Write automated tests covering the story's acceptance criteria tagged `[unit]`, `[integration]`, or `[feature]`.
**Status**: Complete

**Retro**: [Codebase discovery] `test-helpers.sh` counts `test_start` once but `test_pass`/`test_fail` per assertion, so any test carrying two asserts reports more passes than tests run — several existing suites do this (`test-html-template.sh` reports 22/10) and the inflated ratio reads as a broken harness rather than a style choice; extracting `assert_fragment_valid`/`assert_fragment_rejects` here made rc-and-output one assertion and brought the count honest at 11/11, which is the shape to reach for when a validator returns both a code and a reason.

---
