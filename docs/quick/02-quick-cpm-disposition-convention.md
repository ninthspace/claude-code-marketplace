# The disposition convention, retrofitted into CPM as a section no session pays for unasked

**Number**: 02  
**Status**: complete — Delivered. Criterion 5 recorded not met: the new suite is green, but `run-all-tests.sh` carries five pre-existing failures from a stale coverage baseline, accepted at the Step 4 gate.  

**Closed**: 2026-08-26T11:50:00.000Z  

## The change

DPM 0.4.0 gave every report a disposition: each item a run mentions carries one of Fixed, Left alone, Unverified or Needs you, named for what the *reader* must do rather than for what the run did. CPM had no equivalent, so a CPM skill's closing summary was prose whose actionable item had to be found by reading all of it. This ports the convention.

One thing does not port unchanged, and it decides the placement. In DPM the convention is a `###` under `## Conversational Output`, which costs nothing because a DPM skill reads the whole shared file once per run. CPM's `Conversational Output` is a `CORE_SECTIONS` entry, and `conventions-core.sh` emits a core section *in full, subsections included*, into every session in this repository from both SessionStart hooks. Nesting it there would charge every session — including every session that invokes no skill at all — for a rule only reporting skills use. So in CPM it is a sibling `## Disposition` placed immediately after `## Conversational Output`: one line of index in the hook's extract, read in full by the skills that name it. `CORE_SECTIONS` is not touched, which is CLAUDE.md's own test applied — the rule is reached from a skill, and a skill that names it can read it.

The second difference is smaller. DPM reads the four terms from `list_taxonomy` in the `disposition` domain so a skill never transcribes the labels or their order; CPM has no taxonomy table, so the four are written literally in the shared section and the skills reference the section by name.

## Files affected

- `cpm/shared/skill-conventions.md` — new `## Disposition` section after `## Conversational Output`.
- `cpm/skills/do/SKILL.md` — Step 8, the batch summary.
- `cpm/skills/quick/SKILL.md` — Step 4, the completion record's verification report.
- `cpm/skills/review/SKILL.md` — Steps 4 and 5, findings by what remediation did with them.
- `cpm/skills/audit/SKILL.md` — Step 3, findings; an audit changes nothing, so Fixed never appears.
- `cpm/skills/inspect/SKILL.md` — Step 6; Step 5's unread files are Needs you rather than Unverified.
- `cpm/skills/pivot/SKILL.md` — Step 4, tasks by which criteria moved under them.
- `cpm/skills/archive/SKILL.md` — Step 4, documents stamped, skipped, or never reached.
- `cpm/skills/clean/SKILL.md` — Step 3, files deleted, kept, or refused.
- `cpm/hooks/tests/test-disposition-convention.sh` — new suite; `run-all-tests.sh` discovers it by glob.

## What changed

The shared file gained the four dispositions and the four rules that make them mean anything, plus a fifth that is CPM's own: a skill names its own items and does not restate the definitions, which is the job DPM's `list_taxonomy` call does there.

Eight skills gained a paragraph mapping their own artefacts onto the four. `do` — coverage rows marked, gates passed, refactoring passes, amendments and auto-applied lessons as Fixed; skipped or reverted passes and an auto-skipped retro as Left alone; `[target]` criteria as Unverified; criteria unmet-but-continued, failing tests, deferred-unreviewed observations and artefacts left out of step as Needs you. `quick` — the verdict on each criterion. `review` — what remediation did with each finding. `audit` — the Recommendation cell. `inspect` — plus the unread-files rule. `pivot` — tasks by which criteria moved. `archive` — moves, guard-kept specs, failures and a batch stopped midway. `clean` — deletions, files left, and failed removals.

Two skills needed the rules reconciled rather than repeated, and both say so where the tension is. `do`'s retro outcome and criterion-amendments block must speak when empty — an amendment that leaves nothing upstream out of step writes no field, so its absence cannot be read from an absent heading. `audit`'s section 6 is non-negotiable in the deliverable; the convention governs the conversational report and not the file.

## How it was verified

`bash cpm/hooks/tests/test-disposition-convention.sh` — 23 assertions in 23 tests, all passing. Five are controls, and they are the ones worth naming. A slice-width control fails if the awk range swallows the rest of the file. A non-empty control on the label extractor fails if the bullet format changes, which would otherwise compare empty against empty and report green. An emission control asserts the extract carries a core section's body, without which "the Disposition body is absent" is satisfied by an emitter that produced nothing. And two negative controls: `brief` must not reference the convention, and no skill may reproduce three or more of the four definitions in place of naming its own items.

`bash cpm/hooks/tests/run-all-tests.sh` — every suite green except `test-environmental-integration.sh`, which fails five assertions on a coverage baseline predating the CPM-to-DPM migration. Diagnosed, shown, and accepted as pre-existing; see criterion 5's note.

## Acceptance Criteria

| Met | Criterion | Note |
| --- | --- | --- |
| ✓ | `cpm/shared/skill-conventions.md` carries a top-level `## Disposition` section naming Fixed, Left alone, Unverified and Needs you in that order. | `## Disposition` sits between `## Conversational Output` and `## Written Deliverable Length`. The suite reads the four labels out of the section’s own bullets and compares the sequence, with a non-empty control so a changed bullet format cannot pass as an empty match. |
| ✓ | `CORE_SECTIONS` in `cpm/hooks/lib/conventions-core.sh` is unchanged, and the hook’s extract names Disposition in its index line without emitting the section’s body. | Running the hook against the real shared file emits "Disposition" in the index line and not the body; a control assertion proves the extract emits a core section’s body, so the absence is meaningful. A fourth assertion checks no `### Disposition` exists, since a nested one would be emitted in full by a hook whose CORE_SECTIONS never names it. |
| ✓ | Each of `do`, `quick`, `review`, `audit`, `inspect`, `pivot`, `archive` and `clean` instructs its closing report to use the convention, naming that skill’s own items rather than restating the four definitions. | All eight reference it by name and each maps its own artefacts. A negative control confirms `brief` does not, and a further assertion confirms no skill reproduces the four definitions in place of naming its own items. |
| ✓ | The section states the four rules that give it teeth: the label follows the reader’s obligation rather than the run’s action; a disposition with no items renders no heading at all; an item fitting none of the four is not reported; and Unverified means the check was structurally impossible here, so a failure about how the run went is Needs you. | All four are present and each is asserted by its own literal. Two skills needed the rules reconciled rather than repeated: `do`’s retro outcome and criterion-amendments block must speak when empty, and `audit`’s required section 6 is a rule about the file rather than the report. |
| ✗ | `cpm/hooks/tests/test-disposition-convention.sh` asserts criteria 1 to 3 with a negative control proving the assertions discriminate, and `bash cpm/hooks/tests/run-all-tests.sh` stays green. | Half met, and recorded as not met rather than rounded up. The new suite passes 23 of 23. `run-all-tests.sh` is not green: `test-environmental-integration.sh` fails five assertions because `fixtures/coverage-baseline-46.tsv` was captured when CPM’s 46 specs lived in `docs/specifications/`, and the corpus has since moved to `docs/cpm/specifications/` while DPM publishes two of its own there — 48 on disk against a baseline of 46. That suite reads none of the ten files this change touches. Accepted as pre-existing at the Step 4 gate. |
