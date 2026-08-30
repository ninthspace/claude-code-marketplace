# The do loop names where it goes after a gate, and carries that contract past a compaction

**Number**: 08  
**Status**: complete — All six criteria met. Both skill files edited and left uncommitted in the working tree; dpm suite 964/964.  

**Closed**: 2026-08-30T13:30:00.000Z  

## The symptom, and why the rule that forbids it was not enough

A `/dpm:do` run sometimes ends its turn at a story boundary, and from then on delivers one story per user prompt until the epic is done. The same was seen under `/cpm:do`.

Both skills already forbid it in prose. `dpm/skills/do/SKILL.md` Step 7 says the transition is silent, with no announcement, no summary and no asking whether to carry on, and a Guidelines entry names any such prompt an unauthorised checkpoint however it is worded. `cpm/skills/do/SKILL.md` says the same at greater length, and adds a Forbidden phrasings entry listing seven illustrative wordings. The behaviour appeared under both. A rule stated twice as emphatically in the file that already failed is not the fix.

What the two files lack is not the prohibition but its reinforcement at the three moments a turn actually ends.

**An answered gate has no return path.** Both skills route real decisions to `AskUserQuestion` — unmet criteria, a retired story, a change moment, the retro gate, a failed matrix write. Each names the question and stops there. Only dpm's per-task Termination line says what happens afterwards: the task is skipped and the loop continues. Everywhere else the user's answer arrives as the newest instruction in the transcript, two hundred lines downstream of the rule that governs what to do next, and the run acts on the answer and stops — which is what a turn does by default when nothing says otherwise.

**A compaction drops the contract.** A SKILL.md is read once, at invocation. An epic of any size outlives that context. dpm carries a session `state` blob across the boundary and cpm carries a progress file, and neither is told to hold the fact that this is a continuous loop. cpm's progress file has a `Next Action` field for exactly this seam, and it restores the position without restoring the obligation: a resumed run knows which story is next and no longer knows that it is not supposed to ask.

**The one structural signal reads done at every story boundary.** dpm mirrors the selected story's tasks into the harness task list. cpm goes further and makes the emptiness of that list its hydration trigger — Step 7 calls `TaskList`, and an empty result is what causes the next story to be hydrated. Either way the visible list empties as each story finishes, and the state of the world at a story boundary is indistinguishable from the state at the end of the epic.

The first two explain why it happens on some runs and not others. The third explains why it happens at story boundaries rather than anywhere else. None of them explains the persistence on its own: once the run has ended a turn once, the transcript holds a worked example of one story per turn, and the next boundary has a precedent to follow as well as an absence of instruction.

## What changes, and in which files

Three changes, mirrored across `dpm/skills/do/SKILL.md` and `cpm/skills/do/SKILL.md`. Chris asked for both at the scope gate; cpm is superseded as a pipeline but is still installed and still runs.

**Each gate names its return path.** Every `AskUserQuestion` inside the work loop gains the sentence saying where the run goes once the answer arrives — that the answer is acted on and the loop resumes in the same turn. A Guidelines entry states it generally, so a gate added later inherits it rather than needing its own copy.

**The contract is written where a compaction cannot lose it.** dpm's session `state` gains it at Startup and carries it on every `update_session`; cpm's progress file gains a line beside `Next Action` saying the run is a continuous loop and naming what would legitimately end it. The position and the rule then survive together.

**The task mirror spans the epic rather than one story.** After the current story's tasks, both skills mirror one blocked entry per remaining ready story. The visible list is then non-empty until the epic closes, and the boundary stops looking like the end. The entries are blocked by construction, so they are never pending-and-unblocked and cpm's Step 7 hydration check is untouched — that check was the reason to make them blocked rather than pending.

No test in `dpm/tests/` asserts against either skill's prose, so nothing pins the wording being changed.

## What changed, and how it was verified

Fifty-six added lines across `dpm/skills/do/SKILL.md` and `cpm/skills/do/SKILL.md`, and nothing removed but the two sentences that were extended in place.

**Gates.** Eleven gates across the two files now say where the run goes once the answer arrives, and both Guidelines sections carry the general rule — *answering a gate is not a stopping point* — so a gate added later inherits it without needing its own sentence. cpm's blocker, ambiguity, stalled-verification and graceful-degradation gates already said it and were left alone; those were the model for the wording.

**State.** dpm's `state` and cpm's progress file each carry the loop contract now: that the run executes every story of the epic in one continuous loop, which gates end it, and that a finished task, story, verification or commit is not one of them.

**The task list.** dpm mirrors one blocked entry per remaining story; cpm gains hydration step 5b creating the same and blocking each on the current story's verification gate.

Two things the verification caught that reading the plan did not.

**cpm's idempotency scan would have mistaken a placeholder for hydrated work.** Hydration step 3 matched on epic doc path and story number alone, so the placeholder for story N+1 would have satisfied it, and story N+1 would have been "resumed" into a list holding one blocked task and none of its work. The scan now also requires a `Task:` or `Type: verification` line, which the `Type: remaining` placeholder does not carry. The criterion that named the hydration check as untouched is what surfaced it; a criterion saying only that the placeholders exist would have passed over it.

**`tests/body-reads.test.js` classifies every mention of a body-carrying tool in the 23 dpm skill files, and an unclassified one fails.** A sentence naming `mcp__plugin_dpm_dpm__list_task` created a third site in Story selection, and the suite failed on both the unclassified key and the corpus-size count. The sentence was restating where the loop's next unit comes from, so it now says "the task rows" and names no tool — a registry entry would have been the wrong fix for prose that did not need the tool's name.

`npm test` in `dpm/`: 964 tests, 964 pass, 0 fail. The working tree is left edited and uncommitted.

**What this fix cannot do.** All three causes were read out of the skill text rather than reproduced live, and the third — the transcript's own precedent for one story per turn — is not addressed by any of them, because nothing in a skill file can reach a turn boundary that has already happened. If the symptom recurs after this, that is where to look, and the evidence to keep is the turn the run first stopped on.

## Acceptance Criteria

| Met | Criterion | Note |
| --- | --- | --- |
| ✓ | Every AskUserQuestion gate inside the work loop of dpm:do and cpm:do states where the run goes once the answer arrives, and a Guidelines line states the general rule that answering a gate is not a stopping point. | dpm:do — the epic-selection gate, the retro-disposition gate, the TDD unexpected-pass stop, the unmet-criteria gate, the change-moments gate and Step 8's retired-story gate each now say where the run goes. cpm:do — the same at epic selection, the retro gate, the unmet-criteria gate, the matrix-write gate and the Change Type gate; its blocker, ambiguity, stalled-verification and graceful-degradation gates already said so. Both Guidelines sections carry "Answering a gate is not a stopping point", which the gates that do not spell it out inherit. |
| ✓ | Both skills carry the loop contract in the artefact that survives a compaction — dpm:do in the session state, cpm:do in the progress file — stated as a standing rule rather than only as a position to resume from. | dpm:do's Startup section now states that `state` holds the loop contract, written at Startup and carried on every update. cpm:do's progress-file format gains a `## Loop Contract` section beside `## Next Action`, and the prose under it says what each of the two restores — the rule and the position. |
| ✓ | The mirrored harness task list in both skills carries one blocked entry per remaining ready story, so the list is non-empty at every story boundary and empties only when the epic closes. | dpm:do's Story selection mirrors one blocked entry per remaining story below the current story's tasks. cpm:do gains hydration step 5b doing the same, with the placeholder's shape given as a TaskCreate call and a TaskUpdate blocking it on the story's verification gate; each is deleted when its story is hydrated. |
| ✓ | cpm:do's Step 7 Story Hydration check still keys on pending unblocked tasks, and the new story-level entries cannot satisfy it because they are blocked. | Step 7's check reads pending unblocked tasks and is unchanged; a placeholder is blocked by the current story's verification gate, so it cannot enter that set. The idempotency scan at hydration step 3 needed the fix that this criterion existed to catch — it matched on epic path and story number alone, so a placeholder for story N+1 would have read as story N+1's work already hydrated. It now also requires a `Task:` or `Type: verification` line, which a `Type: remaining` placeholder does not carry. |
| ✓ | Neither skill file gains prose about the history of this change — no sentence about what used to be there or why it was wrong — per the repository's rule that a SKILL.md is not a change log. | Read the whole diff — 56 added lines across the two files. Every added sentence is about the rule it states or the mechanism the rule turns on; none is about what the file used to say. The control was a grep of the added lines for the vocabulary a change-log sentence needs — "used to", "previously", "formerly", "no longer", "earlier version" — which returns nothing. |
| ✓ | The dpm test suite passes. | `npm test` in dpm/: 964 tests, 964 pass, 0 fail. The first run failed two assertions in tests/body-reads.test.js — a sentence of mine named `mcp__plugin_dpm_dpm__list_task` and so created an unclassified body-read site, "do · list_task · Story selection #3". The sentence was restating where the loop's next unit comes from, so it now says "the task rows" and names no tool. |
