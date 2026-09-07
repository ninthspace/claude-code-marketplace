# A withdrawn binding and an overtaken criterion say so in the file

**Number**: 14  
**Status**: complete — Shipped in 0.7.7; the markers reach generated files at the next publish through a reinstalled plugin.  

**Closed**: 2026-09-07T00:00:00.000Z  

## What is changing, and where the source report was wrong

The defect came in as a written report against 0.7.4, and it is real. `collection()` in `dpm/src/projection/load.js` takes an optional `live` column and excludes rows where it is set; exactly one descriptor uses it, `sections`. So `coverage` and `storyCriteria` render withdrawn rows identically to live ones. A retired binding appears in an epic's coverage matrix with no marker, which makes the committed file say a requirement is covered after the binding covering it was withdrawn.

**It is worse than an absent marker, because retirement does not clear verification.** The four `requirement_unclaim_*` triggers fire on a coverage insert, a delete, a fragment edit and a requirement text edit — none of them on an update of `retired_at`, as `025-coverage-retirement.sql` says in as many words. So a withdrawn binding can carry a stale ✓, and the ✓ column is the one a reader consults to decide whether the row counts.

**The report's suggested fix was wrong on half its own table.** It proposed setting `live` on four descriptors, `observations` and `storyObservations` among them. `dpm/src/projection/templates/retro.js` opens with the opposite rule — *"Retirement is rendered, not filtered"* — and gives its reasons: the row stays readable and referenced, and dropping the bullet would make the retirement invisible in the diff that performed it. `artifacts.js` does the same thing, rendering a retired artifact struck through with its reason in an existing cell. Filtering those two would have deleted documented behaviour, and the report would have read as authoritative while doing it.

**Which settles the shape for the two that are broken.** `025-coverage-retirement.sql` states that coverage carries `retired_at` / `retired_reason` *"exactly as `artifact` and `observation` carry it"* — and both of those mark. `sections` is the exception rather than the pattern, and its own comment says why: a superseded section's text was folded into the body it would otherwise render beside, so rendering it is duplication. Nothing was folded anywhere when a binding is withdrawn.

So the fix marks and does not filter. Two further things fall out of that. The matrix's row numbering is untouched, so `coverageFor`'s docblock claim that it is stable under everything but a requirement reordering stays true — the report had flagged renumbering as a consequence to accept, and it simply does not arise. And no descriptor changes at all: `collection()` already returns the columns, because it selects every one.

**`load.js` gains a comment.** The report was written by someone who read the `sections` comment, saw a general mechanism, and concluded it had been left unwired for the others. That is a reasonable reading of what is there, and it will be had again. The comment answers it at the descriptors rather than leaving the answer distributed across two templates and a migration.

## Files affected

- `dpm/src/projection/templates/coverage-matrix.js` — a retired row strikes its Spec Text and Story Criterion cells, and its Verified cell carries the withdrawal in place of a ✓.
- `dpm/src/projection/templates/epic.js` — a superseded criterion strikes its text and appends its reason, in the shape `retro.js` already uses.
- `dpm/src/projection/load.js` — the comment at the descriptors saying why three of them carry no `live`.
- `dpm/tests/` — two tests, one per template, each asserting the marker and the row's continued presence.
- `dpm/.claude-plugin/plugin.json`, `dpm/package.json`, `README.md`, `.claude-plugin/marketplace.json` — the version to 0.7.7, and the marketplace's own version with it.

No schema file and no descriptor changes. Neither `retro.js` nor `artifacts.js` is touched, and the `sections` filter stays as it is.

**One thing found and deliberately not fixed here.** `retro.js`'s docblock says the shared Retro Awareness procedure skips a retired observation *"by reading the marker"*, while `skill-conventions.md` says the list omits a retired observation outright, so there is nothing to skip and no marker to read for. One of the two is out of date. The template's operative claim — that retirement renders, so the diff shows it — does not depend on which, so this increment leaves it alone rather than deciding a question it did not open.

## What changed, and how it was verified

`coverage-matrix.js` strikes a retired row's Spec Text and Story Criterion cells and puts `**Withdrawn {retired_at}** — {retired_reason}` in the Verified cell in place of the ✓. `epic.js` renders a superseded criterion as `~~{body}~~ **Superseded {superseded_at}**: {superseded_reason}`. `load.js` gains the comment at the descriptors. No descriptor, schema file or other template changed.

**The existing test had already decided the shape and only half-asserted it.** `templates.test.js`'s coverage-matrix test carries a comment saying in as many words that a retired binding renders, as a retired observation and a retired artifact do, "and a row that vanished from it would take the reason it was withdrawn with it" — and it asserts the row count is two. What it never asserted is that a reader could tell which of the two was withdrawn. So the corpus fixture already produced the state, the test already rendered it, and the gap was one assertion wide. That also corrects the source report's claim that the matrix appears nowhere under `tests/`: the function names do not, and the matrix is tested.

**Verified by planting each marker separately.** Replacing the matrix's `strike` with the identity function turned the matrix test red and left the epic test green; removing the epic template's conditional turned the epic test red and left the matrix test green. Each defect reaches exactly one test, which is what separate tests are for. Both reverted.

973 of 973, the 971 standing before this increment plus its two. Version 0.7.7, marketplace 3.22.6.

**This project's own files change with it.** `.dpm/dpm.db` holds ten retired coverage rows and no superseded criteria, so ten matrix rows across the epics that carry them will render marked at the next publish — the defect showing up in this repository's own committed output, which is the most direct confirmation available that it was real.

**And they will not change until the plugin is reinstalled.** The MCP server is always the installed release, not this working tree, so a publish run now renders through the 0.7.3 templates and shows no markers. That is version skew behaving as designed rather than the fix failing, and it is the reinstall `CLAUDE.md` describes.

## Acceptance Criteria

| Met | Criterion | Note |
| --- | --- | --- |
| ✓ | A retired coverage row still appears in the matrix, marked, carrying its `retired_reason`, and with no ✓ — a withdrawn binding cannot read as verified even where `verified_at` was never cleared. | `coverage-matrix.js` strikes the Spec Text and Story Criterion cells of a retired row and puts `**Withdrawn {retired_at}** — {retired_reason}` in the Verified cell in place of the ✓. Asserted against the corpus fixture's own withdrawn binding, including `assert.doesNotMatch(withdrawn, /✓/)` — the assertion that matters, since retirement never clears `verified_at`. |
| ✓ | The matrix's row numbering is unchanged by a retirement, so `coverageFor`'s claim that it is stable under everything except a requirement being reordered stays true. | Asserted directly: the live row renders as `\| 1 \|` and the withdrawn one as `\| 2 \|`, with the comment recording that marking preserves the numbering a filter would have shifted. `coverageFor`'s docblock needed no edit, which is what the criterion was checking. |
| ✓ | A superseded story criterion still appears on its epic, marked, carrying its `superseded_reason`. | `epic.js` renders a superseded criterion as `~~{body}~~ **Superseded {superseded_at}**: {superseded_reason}`. The test supersedes the corpus's criterion through `update_story_criterion` and asserts the strike, the date, the reason, and that the text is still on the epic. |
| ✓ | Observations, artifacts and superseded document sections render exactly as they did: the two that already mark retirement are untouched, and `sections` keeps its filter. | Neither `retro.js` nor `artifacts.js` is in the diff, no descriptor changed, and `sections` keeps `live: 'superseded_at'`. The existing tests over all three — the story-scoped observation rendering on its epic, every stored section reaching its file, and the byte-identical regeneration — pass unchanged. |
| ✓ | `load.js` says why `coverage`, `storyCriteria` and `observations` carry no `live`, so the reading that produced the source report — that the mechanism was meant for all of them and was left unwired — is answered where it will next be had. | The comment sits at the `sections` descriptor in `load.js`, where the reading that produced the report was formed. It names the other three, says all four mark rather than filter, cites AD 04-01 as the reason, and gives the folding argument for why `sections` is the exception rather than the pattern. |
| ✓ | A test retires a binding, renders the matrix, and asserts both the marker and the row's continued presence — the second being the control that a filter would pass and this fix must not. | `a withdrawn coverage row is marked in the matrix, and stays in it`, in `dpm/tests/templates.test.js`. It asserts the row count is still 2 and the numbering still 1 then 2 before it asserts anything about the marker, which is the control a filtering fix would fail. |
| ✓ | A test supersedes a story criterion, renders the epic, and asserts the same pair. Both tests turn red when their marker is removed, verified by planting each removal separately. | `a superseded story criterion is marked on its epic, and stays on it`. Both plants verified: replacing the matrix's `strike` with the identity turned the matrix test red and left the epic test green; removing the epic's conditional turned the epic test red and left the matrix test green. Each defect reaches exactly its own test. Both reverted. |
| ✓ | The full suite passes, and the version reads 0.7.7 at the four pinned sites with the marketplace's own version advanced alongside. | 973 of 973 pass, 0 fail — 971 before this increment plus its two tests. Version 0.7.7 at the four pinned sites, marketplace 3.22.6. |
