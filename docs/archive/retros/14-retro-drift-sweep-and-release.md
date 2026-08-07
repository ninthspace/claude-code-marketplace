# Retro: Drift Sweep and Release

**Date**: 2026-07-25
**Source**: docs/epics/40-04-epic-drift-sweep-and-release.md
**Stories**: 4/4 complete

## Summary

Spec 40's closing epic: the R10 emphatic-language sweep, the R7 identity bump to 3.0.0, the R11 progress-machinery review, and the end-of-pass token measurement. All four stories delivered, and all four found the *premise* wrong rather than the work hard. Retro 12 landed on "the plan is a hypothesis about the surface, not a description of it." This epic extends that from surface to reasoning: a requirement argued from the wrong mechanism, an NFR set a target its own scope forbade, a test had been asserting a stale literal for months, and — for the third epic running — the named edit site was not the only one. In every case a single command settled it.

## Observations

### Patterns Worth Reusing

The sweep cut emphatic tokens 82% (115 → 20) across the two densest files without weakening a single rule, and the reason is worth generalising: almost none of the emphasis was *emphasis*. It was **repetition** — the same rule stated two, three, or four times in a row, each restatement reaching for a stronger word than the last. `do`'s no-unauthorised-checkpoints rule was stated at four separate sites; the retro number/slug inheritance warning three times in one paragraph; the note-tail preservation rule three ways at one site and again at another.

Collapsing those stacks is what makes an emphatic-language target achievable, and it is why the count could fall that far while both files kept their exact line and heading counts and lost only 1% of their words. The corollary is a drafting rule: a rule stated once in plain prose is not weaker than the same rule stated three times emphatically — it is the three-times version that signals the author did not trust the first statement.

The classifier that made this safe was retro 12's: judge each token by what its rule *does* before rewording it. That is what kept the TDD red-green-refactor phase assertions untouched — `do:247` already carried its own "Intentionally preserved" notice explaining that the three-phase structure is a behavioural lock, and a token-driven sweep would have flattened it.

### Testing Gaps

Story 2's criterion said "hook suite green, including `test-audit-skill.sh`'s manifest-field assertions." The suite was **already red** and had been since v2.0.0 — two assertions pinned the literal string `2.0.0` and every release since had invalidated them, including the `2.9.1` in place when this story started. A third expected `name: cpm:audit`, stale since the previous commit dropped the prefix.

Two things are worth carrying forward. First, a criterion phrased as "the suite passes" is not satisfiable by the story's own work when the suite is already failing for unrelated reasons — the criterion silently annexes whatever maintenance the repo owes. Second, and more useful: an assertion that pins a version literal is guaranteed to go stale, and it fails *silently* in the sense that nobody runs the suite between releases. The fix Chris chose replaced both literals with structural checks — semver shape, and cross-manifest agreement — so the assertions now test the invariant rather than a snapshot.

### Codebase Discoveries

R11 asked whether the Stale-Progress Check still needs to run as an early startup step in every skill, reasoning from Opus 5's 1M context and rarer compaction. The premise does not reach its own subject. The check's stated driver is that a slash-command invocation steamrolls the SessionStart hook's advisory output, and what it surfaces is *other* sessions' orphaned files — neither of which depends on how long this session's context lasts. Meanwhile `cleancheck-guard.sh` already implemented the "lighter trigger" the requirement asked us to consider: first skill of a session gets `RUN`, every later one gets `SKIP`. The answer was in the code before the question was asked.

Separately, and for the third consecutive epic: the plugin version lived at **three** sites, not the two the epic named — and the third, the README's own section heading, was already stale by a patch against the manifest. The retro-13 disposition applied at this epic's gate is what caught it.

### Criteria Gaps

The Token Efficiency NFR asked the pass to reduce net token count. It rose 1.9%. The measurement is honest and the criteria anticipated the possibility — "a net increase is reported rather than hidden" is a story-originated criterion that earned its place — but the target was unmeetable at planning time. Five of spec 40's eleven requirements *add* text (R1, R3, R4, R5, R9 add shared conventions; R8 adds a review step), and retro 11's "section + per-skill pointer" propagation shape multiplies every shared addition across eleven consuming skills. R10's sweep was the pass's only reducing operation, and it did its job: `do/SKILL.md` is the one file that shrank.

An NFR that constrains a *global* quantity cannot be attached to a pass whose requirements move that quantity in both directions without someone doing the arithmetic while the scope is still editable.

## Recommendations

- When an NFR names a global quantity (tokens, bytes, latency), sum the expected direction of each requirement during `cpm:spec` or `cpm:epics`, not at the end. Here the answer — five adders against one reducer — was available from the requirement list alone, and would have turned an unmeetable "should reduce" into a truthful "should reduce the drift-sweep files, and report the net."
- Prefer structural test assertions to pinned literals for anything that changes on a release cadence: semver shape, cross-file agreement, presence. A literal is a snapshot that silently rots between the releases nobody re-runs the suite for.
- Treat "the suite is green" criteria as depending on repo state the story does not own. Either run the suite at planning time so the criterion starts from a known baseline, or phrase it as "no *new* failures."
- Before acting on a could-have requirement, check that its stated premise is actually the mechanism driving the thing it targets. R11's reasoning about compaction was sound and simply aimed at the wrong subject; ten minutes reading `cleancheck-guard.sh` answered it.
- Carry retro 13's version-site grep into every release: `grep -rn` the current version string before bumping. Three epics running, the named site has not been the only site.
- **Spec 40 is complete** (epics 40-01 through 40-04). Its cross-cutting lesson across four retros is a single one: the planning artefact reliably under-counts the edit surface and occasionally mis-states the premise, and a grep costs one command. Consider making a surface survey an explicit first task in any epic that edits prose across skills.
