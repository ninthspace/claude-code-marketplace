# Accommodations Belong to the Model They Were Measured On

**Number**: 04  
**Status**: complete — In force, and it records an omission rather than a decision taken. Spec 05's FR24 proposed a model-specific advice channel and ruled it out of scope; the two findings FR24 said would be kept without it were never written anywhere a run reads. This is where they now live. The channel itself stays unbuilt until a second model drives the skills.  

**Type**: domain  
**Scope**: all  

## What was proposed, and why it was ruled out

Spec 05's FR24 proposed a **model-specific advice channel**: a section appended to `dpm/shared/skill-conventions.md` at read time, one directory per model release, and a lint forbidding model names in skill bodies. It is recorded `wont` with `exclusion: out_of_scope` — not deferred, which is what FR25, FR26 and FR27 carry.

The reason is on the requirement and is worth repeating here, because the next person to want this will want it for the same reason it was refused: **the seam only pays once a second model drives the skills.** Today one does. FR24's own measurements put the extractable, model-specific part of the conventions at around three per cent of their length, so the machinery would cost more to maintain than the content it carried.

**The lint would pass today.** No skill body and neither shared document names a model — checked 2026-09-22 across all twenty-three skills, `skill-conventions.md` and `status-model.md`. That is worth knowing: the corpus is already in the state the lint would enforce, so the omission is the *channel*, not a backlog of violations to clean up first.

**What would change the answer.** A second model driving these skills, or a single accommodation large enough that carrying it for every model is worse than routing it. Until then the two rules below are the whole of what FR24 was protecting, and they hold without any of its machinery.

## Provenance travels with a rule that moves

**An accommodation belongs to the model it was measured on.** A rule written because one model over-ran, under-narrated, reached for the wrong tool or needed a step spelled out is a rule with a subject — and the subject is not "a run", it is *that model's* runs.

So when such a rule moves — into a shared section, into another skill's body, into this library — **it carries what it was measured against**. One clause is enough: *"measured on X, which …"*. Without it the rule arrives at its new home reading as a general truth, and the next person to weigh it has no way to tell an accommodation from a principle. That matters most at exactly the moment FR24 would have paid off: a second model arrives, and nobody can say which rules were ever about the first one.

**The cost of getting this wrong is asymmetric.** A rule wrongly kept as general is one extra paragraph every run reads. A rule wrongly dropped as model-specific is a behaviour nothing prevents any more, found the way such things are always found.

This is a rule about *writing* rules, so it binds wherever one is written or relocated — a spec's requirement, an epic's criterion, a skill body, a shared section, a promoted retro lesson.

## A delegated finding is spot-checked in the file before it is acted on

**A delegated sweep over-reported by roughly a third.** That is FR24's own measurement, and it is the reason this rule survived the requirement being ruled out: the failure it describes has nothing to do with model channels and everything to do with what a run does with a finding it did not produce itself.

So **open the file and look at the line** before acting on a finding from a sweep, a subagent, or any reading a run did not perform itself. Not all of them — the first one, and then as many as it takes to believe the rest. A sweep whose first three findings are real is a different thing from one whose first is already a false positive.

**What over-reporting looks like** is worth naming, because it does not look like an error. The finding is well-formed, cites a real file and a plausible line, and describes something that is not there — a pattern matched in a comment, a name that also means something else, a rule already satisfied one line up. Nothing about the report distinguishes it from a true one; only the file does.

**The corollary is the useful half.** A finding that survives the spot-check can be acted on without checking the rest one by one. The rule is a sampling rule, not a re-do-the-work rule, and a run that re-derived every delegated finding has not delegated anything.

This session bore it out repeatedly, and not only for subagents: three of spec 05's own prose sweeps reported clean corpora while being unable to see the thing they were written for, and two more reported real files for reasons that were the sweep's rather than the corpus's. **A sweep's own output is a delegated finding too.**
