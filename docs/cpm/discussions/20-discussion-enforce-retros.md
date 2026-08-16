# Discussion: Enforcing the generation and application of retros in the cpm2 skill set

**Date**: 2026-06-07
**Agents**: Jordan (PM), Margot (Architect), Bella (Dev), Tomas (QA), Casey (Test), Sable (DevOps), Elli (Writer), Ren (Scrum Master)

## Discussion Highlights

### Key points so far

- **Current-state facts established**: retro GENERATION is opt-in — `do` Step 8 (Batch Summary) already reads `**Retro**:` fields, runs epic-level spec verification, and synthesises a `## Lessons` block into the epic doc, but `do`'s exit gate (Step 8 item 5) offers only "Continue to next epic / Stop" — no retro option, so lessons get synthesised then dropped. Retro APPLICATION is advisory — shared "Retro Awareness" procedure wired into 10 skills as a non-blocking AskUserQuestion Yes/No (shared-conventions line 58 explicitly says "advisory input, not a gate").
- **Chris's decisions** (all confirmed): (1) Both failures present — retros not written AND ignored. (2) Wants `do` to auto-evaluate epic/story experience and flow into retro generation without user intervention. (3) Wants application to GATE, not stay advisory. (4) Rejected gating `epics` ("not really a thing — it's doc-gen consumed by do"). (5) Keep it purely **do-centric** — `spec` is a one-off per distinctly separate body of work, so there is no recurring planning loop to feed.

### Final agreed design (TEAM RECOMMENDATION — locked)
**Closed do-centric loop, two enforced touchpoints, no other skill touched:**

1. **Generation (enforced at `do` Step 8)**: `do` writes the retro file itself at epic completion, reusing the `## Lessons` synthesis it already does. MANDATORY whenever any hard signal fired during the loop (verification gate resolved fail-then-continue; repeated `[tdd]` reds; test-command failures; blocked/stuck stories; epic-level spec gap; `**Inline change**` breadcrumbs). Auto-skip allowed ONLY when that flag set is empty, and the skip is logged with reason — never silent. (Casey: record flags at the moment they happen during the loop, don't re-judge at Step 8.)
2. **Consumption (enforced at `do` startup)**: upgrade Retro Awareness in `do` from advisory Yes/No to a HARD DISPOSITION GATE — show each relevant prior-retro observation verbatim + category, force Applied / Deferred-with-reason / Obsolete (Ren: gate on disposition not acknowledgement, to defeat rubber-stamping). Write trace back as consistent field `**Retro applied**: {nn} · {category} · {disposition} — {note}` (Elli's format) so it's auditable by next reader / cpm2:status / next retro (Margot: trace = auditable, not theatre). Under `ralph`/autonomous mode the gate DEGRADES to auto-logged "deferred (unreviewed)" trace surfaced in run summary — never deadlocks the loop (Sable's operational landmine).
3. **Consciously out of scope**: no gate on `epics` (doc-gen) or `spec` (one-off). Accepted cost: a criteria-gap/planning lesson can't fix an already-frozen epic doc — surfaces as the existing `pivot` offer (retro Step 4) or a recorded note, not a new gate.

### Notable design insight
Generation isn't a missing feature — it's a SEVERED PIPE. `do` Step 8 already does ~80% of what `/cpm2:retro` Step 2 does (lesson synthesis duplicated in two places). Reconnect rather than bolt on.

### The /cpm2:ralph issue (must be covered in the spec)
A hard `AskUserQuestion` consumption gate in `do` would break `/cpm2:ralph`, which wraps `/cpm2:do` for autonomous multi-epic execution — no human is present to satisfy a disposition gate, so the loop would either stall indefinitely or have ralph's autonomous-override logic punch straight through it, meaning "enforcement" silently fails in exactly the unattended runs where lessons matter most. **Required behaviour**: define the non-interactive path explicitly. In autonomous mode the gate must NOT block — it records `**Retro applied**: {nn} · {category} · deferred (autonomous run, unreviewed)` and surfaces every such deferral in the run summary, so the human reviews the batch of deferrals after the loop rather than mid-loop. The same applies to generation: ralph runs must still produce the retro file at epic completion (it's non-interactive and the data is in hand). Gate the human path hard; degrade to a logged, surfaced trace on the autonomous path.

### Key rationale captured

- **Ren — disposition over acknowledgement**: a gate that resolves with one reflexive "OK" click trains the exact dismissal it's meant to prevent. Force Applied/Deferred-with-reason/Obsolete so it can't be rubber-stamped, and "Deferred — no reason" becomes a visible smell.
- **Margot — execution vs planning lessons, and why do-centric works for one-off specs**: the seven retro categories split into execution lessons (codebase discoveries, complexity, testing gaps, patterns to reuse) and planning lessons (criteria gaps, scope surprises). `do` is the right home for execution lessons; planning lessons applied at do-time arrive after the epic doc is frozen. Because Chris's specs are one-off separate bodies of work, there's no recurring planning loop to protect, so routing planning lessons to spec is unnecessary — they degrade to pivot offers or recorded notes.
- **Bella — cost framing**: by do-time the epic doc is law; applying a scoping/criteria lesson mid-execution is a mid-flight pivot (expensive). Cheap to apply "watch for this codebase gotcha"; expensive to apply "size stories differently" once stories exist.
- **Casey — generation trip-wire**: the strongest signal is already in the loop. Treat any fail-then-continue verification gate, repeated `[tdd]` reds, or test-command failure as a hard mandatory-retro flag recorded at the moment it happens, not re-judged by a tired end-of-epic call. Auto-skip legal only when the flag set is empty.
- **Elli — legible gate + consistent trace**: show the verbatim observation text and category (not a summary), make the disposition the answer, and write the trace in one consistent shape so the next reader / cpm2:status parse it identically every time.
- **Jordan — friction caveat (registered, then overruled by Chris's gate decision)**: forcing the same closing ritual on a 3-story bugfix and a 30-story feature breeds rubber-stamping; weight should scale with the work.

### Active thread
Recommendation accepted by Chris. Wrapping up and handing to `/cpm2:spec` to turn the locked do-centric design into a change spec for the cpm2 skill set, with explicit coverage of the `/cpm2:ralph` non-interactive path.

### Agents who have participated recently
Margot, Casey, Elli (final round); earlier: Ren, Jordan, Bella, Tomas, Sable.
