# Why the plan-column narration rule still leaks on a current install

**Number**: 02  
**Status**: complete — Consultation closed with the diagnosis settled and the fix shape still open. Two candidate changes are recorded; choosing between them is scope work for the increment that implements it.  

## What was asked

Chris had seen `plan: 0` and `plan: 1` appear in a run's conversational output to him over the weekend of 5–6 September 2026, and believed the problem had already been fixed. The question was whether the installed DPM covers it.

Two facts narrowed the question during the conversation. The project was new, so DPM was installed fresh at 0.7.4 — the current release — and it is not on this machine. And the strings appeared in live correspondence with the user rather than inside a tool-call specification, which rules out the argument exemption the rule deliberately carves out.

So the answer is that the rule exists, is current, and failed anyway. Everything below is about why.

## What was already in place

The fix Chris remembered is real and landed twice.

DPM 0.7.2 (`0c1d501`, 30 August 2026) changed the three skills that read the story `plan` column and handed the agent its value as the sentence to say. `do` now branches on whether the story requires a plan and names the two sentences to say. `ralph` reports each cleared story as no longer requiring one. `epics` keeps `plan: 1` as the `create_story` argument, because a specification of a call is not commentary, and describes the story in words when it puts it to the user. The same increment added the general rule to `dpm/shared/skill-conventions.md` as the sub-section `Saying what a row holds` under Conversational Output, and had it point at Naming a Document — which had forbidden reading an id aloud since 0.6.0 and went on being broken because only one skill of 23 cited it.

DPM 0.7.3 (`79f49f5`, 2 September 2026) added four tests in `dpm/tests/corpus.test.js` over that section, each verified red on its own planted defect, and added the clause the fix had been missing: a column sitting at its default is not narrated at all.

DPM 0.7.4 (`052d56b`) is test infrastructure and a citation reflow in `ralph`. Nothing in it could regress the rule.

Reach in source is complete. All 23 skills cite `**Conversational Output**` and all 23 instruct reading the shared conventions file at startup. The file is 288 lines and 17.6 KB, so a full read is cheap, and unlike CPM there is no `hooks/lib` in DPM — the conventions are not SessionStart-injected, so that startup read is the only way the rule arrives.

## Why it leaks anyway

Two findings, and they compound.

**Nothing checks the rule at runtime.** The four tests 0.7.3 added read `dpm/shared/skill-conventions.md` as text and assert that the paragraph is present, correctly placed, and says what it says. That is a corpus check. It confirms the instruction exists; it cannot confirm any run obeyed it. Between the instruction and the behaviour sits one startup read that the run performs or does not, with nothing observing which.

**The value is put in front of the run on every read.** `plan` is declared in `dpm/src/tools/index.js:218` as an `extra` column on the delivery tools, `enum: [0, 1]` with `default: 0` — declared as 0/1 rather than a boolean on purpose, so the argument and the `CHECK (plan IN (0, 1))` constraint are the same set, which is what AD10's conformance seam compares. `dpm/src/tools/spine/delivery.js:81` treats only `description` as a body column, so `plan` is withheld from nothing: it comes back on `read_story`, and on every row of `list_story`. A nine-story epic hands the agent `plan: 0` eight times and `plan: 1` once.

Worth noting where that string does *not* exist: the markdown projection never renders `plan` at all. The tool result is the only place it appears. So the prose is asking a run to suppress a token that the tool boundary supplies each time it looks, with no mechanical support, on a fresh project where nothing else has conditioned the habit. Repeating what the tool just said is the path of least resistance, and that is what happened.

## The two candidate fixes

Both act at the tool boundary rather than by adding more prose, on the reasoning that a third restatement of a rule two releases have already stated is unlikely to be what was missing.

**Gloss the column description.** `dpm/src/tools/index.js:218` currently reads *"whether this story is planned in full before any of its tasks are executed"* — a description of what the column is. Rewriting it to say what each value means makes the meaning arrive attached to the data, in the same tool result, without depending on the startup read having happened. Small, contained, and it reaches every skill and every project at once because it ships in the server rather than in a skill file.

**Withhold `plan` from `list_story`.** Declaring it a body column the way `description` is declared one would stop a nine-story list shipping eight defaults, which is exactly the case the 0.7.3 default clause was written for. Stronger, because the value would not be present to repeat. It costs a second change: `ralph` step 1b scans `list_story` scoped by `epic_id` to find the stories that require a plan and clear their gates, and the skill file says outright that the column is how the run finds them. Withholding it from the list breaks that scan unless step 1b changes with it.

Bella's reading is that the first is the cheapest change that bites, and that the second is the more complete one if the `ralph` cost is acceptable. They are not exclusive.

A third option was raised and not pursued: adding a runtime check. Nothing in the current design observes a run's prose, so this would be new machinery rather than an adjustment, and it was not scoped here.

## Open when the consultation ended

Which of the two fixes to take, or both. Chris said "let's fix this" without choosing between them, and the choice is his: the second buys more and costs a change to `ralph` step 1b, and whether that is worth it is a judgement about how much the list case actually contributes to the leak.

Which skill was talking when the strings appeared is still unknown. It was not on this machine, so the transcript was not available to the consultation. It does not block either fix — both are unconditional at the boundary — but it would say whether the leak is concentrated in the `list_story` path, which is the evidence that decides the second fix on its merits rather than on argument.

The general question behind this one was also left open: `plan` is the instance that was noticed, and the rule names `met`, `polarity` and `status` as sitting on the same trap. Whichever fix is taken here, nothing yet says whether the same treatment is owed to those columns.
