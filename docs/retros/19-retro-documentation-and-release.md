# Retro: Documentation and Release

**Date**: 2026-07-25
**Source**: docs/epics/41-05-epic-documentation-and-release.md
**Stories**: 2/2 complete

## Summary

The last epic of spec 41. `cpm/README.md` and `cpm-training-guide.html` now describe what the skills produce after the pivot, the two presentation decks lost their stale HTML-dashboard promise, and cpm ships as 3.1.0 at all six sites carrying a version. Five coverage rows verified; the runner is green at 24 suites.

Both stories' criteria pointed slightly to the side of the real defect, and in both cases the premise check found it before work started rather than the gate finding it after. That is the epic's through-line, and it is the fourth epic in this chain where the same check paid for itself.

The chain is complete: five epics, seven retros' lessons consumed across them, and the shared convention now carries one **Artifact Publishing** procedure referenced byte-identically from ten skills, with per-skill guidance on what an artifact would carry that the Markdown cannot.

## Observations

### Criteria Gaps

- **"Describes no X" is blind to the defect that follows a feature being added.** Story 1's criterion — *"`cpm/README.md` describes no faithful-render capability and no local HTML output for `status`, `epics` or `present`"* — was satisfied on arrival for most of its subjects, because the README had never documented faithful renders at all. The actual drift was the inverse shape: `status` still asserted "no files created or modified", which a confirmed publish had made false, and `epics` never mentioned the dependency view. A negative criterion can only find text that is present and wrong. Text that is absent and needed is invisible to it, and that is the more common residue after a feature lands. Every "describes no X" wants a paired "describes Y" for whatever replaced it — the shape every assertion in the new suite ended up taking anyway.

- **An enumeration in documentation is a snapshot with no natural detector.** The README's file tree listed 18 of 21 skills and omitted `assets/` and `shared/`, having rotted through three releases without a single thing failing. It sat outside the criterion's letter and squarely inside the must-NOT's subject. The suite now derives the expected tree from `ls cpm/skills/` rather than a pinned list, which is the only version of that assertion worth writing.

### Testing Gaps

- **"Assert the invariant, not the snapshot" is not satisfied by asserting an invariant against a pinned expected value.** The obvious reading of retro 14's lesson produces `assert_equals "3.1.0" "$found"` — structurally an agreement check, still a pin, still stale the day after the release. The version has to be *read from the manifest at run time* and used as the expected value, so the same assertion passes at 3.2.0 untouched. Two useful things fall out of building it that way. The must-NOT sweep becomes "no test contains **the current version**" rather than "no test contains **a semver**", which stops it false-positiving on spec and task numbers shaped like versions — the naive sweep matched `Task 41-01.2.3`. And the sweep found a real hit that a reader never would: a header comment spelling out the release number as an example of the anti-pattern it warned against. A literal in prose is invisible to review and fully visible to a grep.

- **A per-file "only one version appears" rule is only true of a file about one thing.** It held for the three CPM documents and failed immediately on the root README, which lists five plugins and legitimately carries five versions. The equivalent structural claim there is set equality against `marketplace.json`, and generalising it — walk each plugin's `source` field to its own manifest — covers plugins added later without editing the test. The first draft of that assertion would have failed for a correct repo, which is the more expensive kind of wrong test.

### Scope Surprises

- **Six version sites, not the three the last release found.** The two presentation decks and the training guide each carry a version badge nobody had counted, and the epic doc named three. Unlike last release nothing was already stale — all six agreed at 3.0.0 — so the survey's value here was purely in finding the sites, not in finding drift. This is now four consecutive releases where the pre-edit grep returned more than the plan named. The grep costs one command; the survey table is recorded under Task 2.1 so the next release starts from six.

### Patterns Worth Reusing

- **Checking a criterion's premise before starting is now four-for-four.** Retro 18 recommended it for deletion stories; this epic applied it to documentation stories and it found a mis-aimed criterion in each of the two. The check is cheap and mechanical — *does this file actually say the thing the criterion says it says?* — and it converts a gate failure into a five-minute correction at hydration. It has earned promotion from a per-epic disposition to a standing step.

- **A test suite that has to except itself from its own rule is worth one more minute of thought.** `test-version-agreement.sh` legitimately excludes itself from the pinned-literal sweep, because it must hold the version in a variable to test for it. `test-docs-artifact-pivot.sh` did not have that excuse — it had a literal in a comment. Distinguishing the necessary exception from the accidental one is what made the second file worth fixing rather than adding to the exclusion list. Exclusion lists grow; the reason for each entry does not survive in them.

## Recommendations

- **Pair every "describes no X" documentation criterion with a "describes Y".** The negative half catches text that is present and wrong; the positive half catches text that is absent and needed. Only together do they distinguish a section that was updated from one that was deleted.
- **Derive expected values at run time, always — an agreement assertion with a pinned expectation is still a pin.** Read the version from the manifest, the file list from the filesystem, the tree from `ls`. If a test would need editing on the day of a release that changes nothing about its subject, it is asserting a snapshot.
- **Start the next release from the recorded six-site survey, and re-run the grep anyway.** Four consecutive releases have found more sites than the plan named. The table under Task 2.1 is a starting point, not a substitute for the command.
- **Promote the premise check to a standing hydration step.** Two epics running, four criteria found mis-aimed, every one catchable by a single grep before any work started.
- **Spec 41 is complete.** Nothing outstanding blocks a further epic. The one item worth carrying forward is unrelated to the pivot: `docs/quick/27-quick-shared-conventions-relevance-check-spec.md` records the deferred relocation of roughly 36% of `skill-conventions.md` into the skills that actually reference it — a file every session in this repo pays for in full.
