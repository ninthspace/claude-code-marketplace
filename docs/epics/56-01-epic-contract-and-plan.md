# Data sources, the field and plan's rules

**Source spec**: docs/specifications/56-spec-independent-acceptance-tests.md  
**Date**: 2026-11-11  
**Status**: Pending  
**Blocked by**: —  
**Amended**: review 13 (docs/reviews/13-review-independent-tests.md) — the redaction rule's identity limited to one that is personal data; the pre-build run kept off the `**Test run**` line; the cross-file "stated once" control moved to 56-03, where every form is checked after the last edit; the marking rule's test-proven condition made to cover the high-effort branch; the red form written in step 3, after the spec's FR8 amendment; the `sample due` check as two stories, after its FR2 amendment (2026-11-11)  
**Lessons**: docs/library/01-library-lessons-learned.md → "A rule is stated once; every other place refers to it and carries none of its terms" (Story 1), docs/library/01-library-lessons-learned.md → "A rule is stated once; every other place refers to it and carries none of its terms" (Story 2), docs/library/01-library-lessons-learned.md → "A must-NOT stated as an equality is a change detector, and a set comparison needs a floor" (Story 1), docs/library/01-library-lessons-learned.md → "A must-NOT stated as an equality is a change detector, and a set comparison needs a floor" (Story 2), docs/library/01-library-lessons-learned.md → "A rule is checked over every case its requirement covers, not the one in front of you" (Story 2), docs/library/01-library-lessons-learned.md → "A check that passes may be passing for a reason other than the one you want" (Story 1), docs/library/01-library-lessons-learned.md → "A criterion's factual claim is checked against the code and its sibling criteria before the epic runs" (build)

**Base.** `{base}` is `0a4e609`, the cpm-next 0.17.0 release commit; every diff is `git diff {base}`. The history check reads the added lines of the story's diff and runs `grep -w -i` over them for `now`, `no longer`, `used to`, `replaced`, `previously`, `instead`, `in place of`, `rather than`, `formerly`, `earlier`, `anymore`, `0.17`, `0.18`, `spec 56`, each hit read and accounted for in the `Evidence` line.

## The contract's forms
**Story**: 1  
**Status**: Pending  
**Blocked by**: —  
**Satisfies**: FR1, FR4, FR8, FR12, NFR1, NFR3

**Acceptance Criteria**:

- `cpm-next/shared/artifacts.md`'s Spec template gains `## Data Sources` after `## Testing Strategy`, with the bullet form `- {source}: identity {field(s)} ({where the source defines it}) — sample: {repository path} ({YYYY-MM-DD}{, version}) | sample due: {documentation path or URL}`, and a paragraph stating: the section is present only when the spec reads records from outside the codebase; the identity is the source's documented key, never inferred from field names; the sample's limits (smallest real extract holding every record shape the spec uses, two consecutive pages for a paged source, records sharing non-identity values where the source has them, under 100 KB, under the project's test fixtures); and the redaction rule (one stand-in per distinct personal value or secret across the sample, an identity that is personal data included, so shared values and references survive; no record and no criterion's field removed). Floor: every template section at `{base}` (`## Problem Summary` to `## Challenge`) is still there, in order `[manual]`
- The Epic template's story header gains `**Independent tests**: due {optional}`, and a paragraph defines its three states and its place: `due` (written by `plan`), `{path} {blob}, … ({YYYY-MM-DD})` over every file the test-writer wrote, `{blob}` the first 12 characters of `git hash-object`, with ` — revised {YYYY-MM-DD}: {path} ({citation})` appended per revision, whose blob the revision rewrites, and `skipped — test-writer unavailable`; one line in the header block before `**Acceptance Criteria**`, like `**Test run**`. The `**Test run**` field's sentence on who rewrites it adds that the pre-build run of the independent tests does not, as a red pass does not. Positive `grep -c -F` for `**Independent tests**`, `— revised`, `skipped — test-writer unavailable` each at least 1 `[manual]`
- The Evidence forms gain `- Evidence: {test name, file:line} — red: {message} — before the build`, with a sentence saying when it applies (the boundary answered before the build and the failing assertion is the one proving the criterion) and that it is written with the rest of the `Evidence` line in step 3, never before the build. Floor: the six existing `Evidence`, `Evidence (user,`, `Not met` and `Waiting on user` lines of the template at `{base}` are all still there. `[manual]`
- The seed slugs gain `shared-assumption` and `identity-key`. Floor: the nine slugs at `{base}` are all still there `[manual]`
- The added lines of `git diff {base} -U0 -- cpm-next/shared/artifacts.md` are read with the history check, and none records history `[manual]`

### Write the contract's forms
**Task**: 1.1  
**Description**: Edit the Spec and Epic templates, the Evidence forms and the seed list in `cpm-next/shared/artifacts.md`.  
**Status**: Pending

---

## Plan asks for samples, writes the criteria and marks the stories
**Story**: 2  
**Status**: Pending  
**Blocked by**: Story 1  
**Satisfies**: FR2, FR3, FR4, NFR1, NFR3

**Acceptance Criteria**:

- `plan/SKILL.md` step 2 says that when a spec has a data source, the question round holds one question for every source together, asking for a real sample (a path, or leave to fetch one through access the session already has) and the source's documentation, and never for credentials; section 3's Spec paragraph says `plan` writes the **Data Sources** section, redacts a supplied sample and writes it at the bullet's path as the contract says, leaving the commit to the user. Floor: step 2's "up to four" questions rule is unchanged `[manual]`
- `plan/SKILL.md` says what happens with no sample, over every source without one: the bullet reads `sample due`, the spec's Assumptions say the tests are built from the documentation's examples, and the user-checks epic holds two stories: one whose only criterion is the `[user]` step of placing a redacted sample at the named path, and one blocked by it, marked, whose test-proven criteria are the identity and conservation criteria over that sample, written by its own test-writer in new files. Floor: the user-checks rule at `{base}` (no other epic names it in `**Blocked by**`; a story holding `[user]` criteria is blocked by nothing that holds one) is unchanged `[manual]`
- `plan/SKILL.md`'s Epics paragraph states the three criteria for every story that stores, upserts or merges records, for each record type: (a) records distinct by identity sharing every other attribute the code could mistake for a key are all kept, with its control (a store keyed on any non-identity attribute fails it), in a fixture from the sample with such records added where it has none; (b) created, updated, unchanged and skipped sum to the records received, each skip's reason recorded where the spec says; (c) a repeat delivery, or one identity twice in one delivery, changes nothing beyond the first, with its control (a store that inserts on repeat fails it); and that the identity is the **Data Sources** bullet's or, for records the codebase defines, the requirement's. Each of (a), (b), (c) is found by its own grep (`non-identity`, `skipped`, `inserts on repeat`), floor: all three present `[manual]`
- `plan/SKILL.md`'s Story fields paragraph states the marking rule: `**Independent tests**: due` on a story that has a test-proven criterion and either reads a **Data Sources** source, upserts or merges records by an identity, imports or exports records, serves an API other systems call, or carries `**Effort**: high` (a story whose criteria are all `[manual]`, `[browser]` or `[user]` is never marked); a form saving what its user typed is not marked for that alone. It states that a marked story's criteria name the entry point, the outbound seam a test fakes and the stored state a test reads (tables or models, identity columns, where skips are recorded). Floor: the `**Blocked by**`, `**Effort**` and `**Model**` rules at `{base}` are unchanged `[manual]`
- `plan/SKILL.md` names the field and the **Data Sources** section by name and repeats neither form: `grep -cF "sample due: {" cpm-next/skills/plan/SKILL.md` and `grep -cF "{path} {blob}" cpm-next/skills/plan/SKILL.md` give 0, while the same greps over the contract give 1 each `[manual]`
- The added lines of `git diff {base} -U0 -- cpm-next/skills/plan/SKILL.md` are read with the history check, and none records history `[manual]`

### Edit plan's question round, Spec, Epics and Story fields
**Task**: 2.1  
**Description**: Edit step 2 and section 3 of `cpm-next/skills/plan/SKILL.md`.  
**Status**: Pending

---
