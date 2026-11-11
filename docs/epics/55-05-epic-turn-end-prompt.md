# The turn-end prompt points to the pending file

**Source spec**: docs/specifications/55-spec-tracker-split-view.md  
**Date**: 2026-11-11  
**Status**: Complete  
**Blocked by**: Epic 55-03-epic-release  
**Lessons**: docs/library/01-library-lessons-learned.md → "A fix lands at one place; the same fault stays at its neighbours" (Story 1), docs/library/01-library-lessons-learned.md → "A fix lands at one place; the same fault stays at its neighbours" (Story 2), docs/library/01-library-lessons-learned.md → "A control is only a control once you have watched it fail, and read why" (Story 1), docs/library/01-library-lessons-learned.md → "A rule is stated once; every other place refers to it and carries none of its terms" (Story 2)

The prompt text is built in one place, `turnEndNote` in `cpm-next-progress/hooks/progress.ts`, and submitted from two: `nudge` (`register.ts`, a turn's end) and the bare `/progress-tracker` (`register.ts`, `command.run`). The tool-result note (`modelNote`) already says how to apply up to eight writes and how to hand more to a Haiku subagent; the prompt reuses those instructions with the file in place of the inline writes. Test command: `claude plugin test cpm-next-progress`.

## The prompt names the file and how to apply it
**Story**: 1  
**Status**: Complete  
**Blocked by**: —  
**Satisfies**: FR13  
**Test run**: 1 (0 full, 1 targeted) — targeted — `claude plugin test cpm-next-progress`: 108 passed, 0 failed — tree 9f01cb57c24e5bee2b70efaa1680bba0d80dd9c5 — cpm-next-progress/hooks/progress.ts → hooks/progress.test.ts, hooks/timing.test.ts, hooks/waiting.test.ts, hooks/testrun.test.ts, hooks/register.test.ts; cpm-next-progress/hooks/progress.test.ts, register.test.ts → themselves  
**Inline change**: the second criterion proves the bare command's prompt through `turnEndNote` with its lead, since under `claude plugin test` the command's `clock.after` timer never fires once its dispatch has ended (a logged callback did not run even after `mock.clock` advanced); the third criterion's grep leaves out the test files, whose assertions name the phrase as absent (2026-11-11)  
**Signal**: unprovable-in-session — project — the second criterion asked for the bare command's prompt through the hooks, which `claude plugin test` cannot reach because the command's timer is dropped with its dispatch (cpm-next-progress/hooks/register.ts `command.run`, 55-05 S1 build) — recurs: docs/library/01-library-lessons-learned.md → "A criterion that needs an observation the session cannot make is a `[user]` check" (a criterion needing an observation the test kit cannot make)  
**Audit**: pass (2026-11-11)

**Acceptance Criteria**:

- `turnEndNote`'s text, for a drift of up to eight writes, names its pending file and its artifact link and says to apply the file's batches with the `ArtifactData` tool, `action` `batch`; for a drift of more than eight, it names the file and the link and says to hand the file to a Haiku subagent; for two drifts, both files and links; in every case it holds no "given with this message"; the writes are still returned as `context`. Control: the text as it stands at the start of this epic fails each of these assertions `[unit]`
  - Evidence: "the prompt at a turn's end says where the writes are and how to apply them, by size", cpm-next-progress/hooks/progress.test.ts:227; "the prompt at a turn's end names the rows, and carries the writes as context", :216 — red: expected the text to contain `Read /repo/.claude/cpm-next-progress/01-build-order.pending.json and, for each array in its "batches", call the ArtifactData tool …`, received `… Apply the writes given with this message now, …` with mutation of cpm-next-progress/hooks/progress.ts:861: the text back to its form at the start of this epic (the control); expected `Start a subagent with the Agent tool, model "haiku", and tell it: read …02-build-order.pending.json`, received the up-to-eight form with mutation of cpm-next-progress/hooks/progress.ts:849: `<= 8` → `<= 800`
- Through the hooks in `register.test.ts`: after `turn.complete`, the prompt `nudge` submits names the pending file and the artifact link; and the text the bare `/progress-tracker` submits after a check that finds writes, `turnEndNote` with that command's lead, names them too `[unit]`
  - Evidence: "a change to a row's criteria alone puts no note on the tool result; the writes are asked for at the turn's end", cpm-next-progress/hooks/register.test.ts:395 (the prompt `nudge` submits holds the pending file and `url https://claude.ai/artifact/abc`); "the prompt the bare /progress-tracker submits after a check says where the writes are and how to apply them", cpm-next-progress/hooks/progress.test.ts:243 — red: expected `url https://claude.ai/artifact/abc`, received `… Apply the writes given with this message now, …`, and expected the `Read …pending.json and, for each array …` instruction, received the old text, with mutation of cpm-next-progress/hooks/progress.ts:861: the text back to its form at the start of this epic
- `grep -rn "given with this message" cpm-next-progress/ --exclude='*.test.ts'` gives no hit `[manual]`
  - Evidence: `grep -rn "given with this message" cpm-next-progress/ --exclude='*.test.ts'` exits 1 with no output — red: n/a — static

### Prompt text
**Task**: 1.1  
**Description**: Rewrite `turnEndNote`'s text from the drifts' files, links and sizes; tests in `progress.test.ts` and `register.test.ts`.  
**Status**: Complete

---

## Release cpm-next-progress 0.9.1
**Story**: 2  
**Status**: Complete  
**Blocked by**: Story 1  
**Satisfies**: NFR2  
**Effort**: low  
**Test run**: 1 (1 full, 0 targeted) — full — `claude plugin test` (cpm-next, cpm-next-models, cpm-next-progress, whats-next): 177 passed, 0 failed — tree 207a9cabad61d8bed7a3d7c2e1869706bfc3990b — closes epic; wide reach: cpm-next-progress/.claude-plugin/plugin.json, .claude-plugin/marketplace.json (config); untested: the three guides — each → deferred full run  
**Audit**: pass (2026-11-11)

**Acceptance Criteria**:

- `README.md`'s CPM Next Progress "How it works" step 4 says the turn-end prompt names the pending file and how to apply it, and no longer says the writes go to Claude as context you do not see; the training guide's "How rows sync" turn-end item says the same; every other passage on the turn-end prompt is read and kept or changed: `grep -n -i "turn ends\|turn's end\|turn-end" README.md cpm-next-training-guide.html cpm-next-onboarding.html cpm-next-presentation.html` `[manual]`
  - Evidence: README.md:177 step 4 now says the prompt names the rows, the pending file and how to apply it (Claude for up to eight writes, a Haiku subagent for more), and that the writes also go as context; cpm-next-training-guide.html:1319 says the prompt names the pending file and how to apply it; the grep's other hits, README.md:176 (step 3) and cpm-next-training-guide.html:1317 (criteria-only writes wait for the turn's end), read and kept; onboarding and presentation have none — red: n/a — manual
- `docs/maintenance/README.md`'s bullet "The turn-end prompt's context" says the prompt now points to the pending file, so a missing context no longer leaves Claude without the writes `[manual]`
  - Evidence: docs/maintenance/README.md, "The turn-end prompt's context" bullet ends: "From 0.9.1 the prompt's text names each pending file and how to apply it (`applyFromFile` in `hooks/progress.ts`), so a missing context no longer leaves Claude without the writes." — red: n/a — manual
- `cpm-next-progress/.claude-plugin/plugin.json` and its marketplace entry read `0.9.1`, the marketplace `version` moves one patch from 4.0.14, and `git diff 7220f77 -- .claude-plugin/marketplace.json` changes no other plugin's version line; the guides' `cpm-next-progress 0.9.0` lines read `0.9.1` and `grep -c "cpm-next-progress 0.9.0"` over them gives 0 `[manual]`
  - Evidence: cpm-next-progress/.claude-plugin/plugin.json reads `0.9.1`; `git diff 7220f77 -- .claude-plugin/marketplace.json` changes two lines, 4.0.14 → 4.0.15 and cpm-next-progress 0.9.0 → 0.9.1; the three guides read `cpm-next-progress 0.9.1` and `grep -c "cpm-next-progress 0.9.0"` gives 0 in each — red: n/a — static
- `claude plugin validate cpm-next-progress` and `claude plugin validate .` pass; `claude plugin test` passes for cpm-next-progress, cpm-next-models and whats-next; the mod loads headless under each version in `~/.local/share/claude/versions/` by the commands in `docs/maintenance/README.md` `[manual]`
  - Evidence: `claude plugin validate cpm-next-progress` and `claude plugin validate .` print "✔ Validation passed"; `claude plugin test`: cpm-next-progress 108 passed, cpm-next-models 20, whats-next 34 (cpm-next 15), 0 failed; headless loads under 2.1.319, 2.1.321 and 2.1.322 each log `hooks module cpm-next-progress@inline loaded` — red: n/a — manual

### Docs, versions and checks
**Task**: 2.1  
**Description**: README, training guide, maintenance record, versions, validate, test, headless loads.  
**Status**: Complete

---
