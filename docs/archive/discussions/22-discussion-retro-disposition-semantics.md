# Discussion: Retro disposition semantics — "not relevant here" vs durable retirement

**Date**: 2026-06-24
**Agents**: Margot (Architect), Elli (Technical Writer), Tomas (QA), Ren (Scrum Master), Bella (Senior Developer)

## Discussion Highlights

### The problem

The `cpm:do` consumption gate (`cpm/skills/do/SKILL.md:40-48`) offers three dispositions for each prior-epic retro lesson: **Applied / Deferred / Obsolete**. The **Obsolete** disposition is *durable* — it writes a `**Retired**` marker back to the source retro (step 5, per the shared **Retro Retirement** convention), removing the lesson from **all** future runs.

The defect: users reach for "Obsolete" when they actually mean **"not relevant to *this* work"**. That conflates two incompatible axes:

- **Global truth** — "is this lesson still true anywhere?" (correctly answered by retirement)
- **Local relevance** — "does it bear on the epic in front of me?" (a per-run judgement that must NOT mutate the source)

A local judgement leaks into global state, silently euthanising a still-valid lesson for every future epic. Neither existing option fits "valid, just not applicable here": **Deferred** implies a temporal "later", not a scope "not in this work".

### Why it matters (Tomas)

The failure mode is silent and asymmetric. Wrongly picking "Deferred" for a truly-dead lesson is cheap and recoverable (it resurfaces, you dismiss it again). Wrongly picking "Obsolete" for a "not here" lesson destroys a valid lesson with **no error, no failing test** — the next epic that needed it never sees it. When the downside is that lopsided, the default must be safe and reversible; the destructive option must be deliberately reached for.

### Naming (Elli)

"Obsolete" is a property of the *lesson* (it has ceased to be true). "Not relevant here" is a property of the *relationship* between the lesson and this work. The fix must make the **consequence legible at the point of choosing**, not three documents away in a shared convention.

### Where retirement belongs (Ren, Margot)

- **Ren**: Killing a lesson for everyone is a cross-cycle decision; doing it inside a single epic's startup gate is strategy in a tactical moment. Retirement should be its own deliberate pass, not bolted onto every epic.
- **Margot**: We already have the shape — `/cpm:retro learn` is a deliberate, manual, out-of-cycle action that retires a lesson at source *by graduating it to the library*. Retirement-because-spent is the same affordance with a different terminus. Both write the same `**Retired**` marker via the shared convention.

### In-cycle escape hatch (Bella)

The "I just deleted the module this lesson warned about, it's dead *now*" case is real. Forcing it through a separate review ritual is friction that makes people skip it. Keep an in-cycle retire — but deliberately worded and gated (confirmed, typed reason, explicit "removes for all future runs" warning), not a peer button you can fat-finger.

## Decisions

1. **`cpm:do` gate → three per-run dispositions: Applied / Deferred / Not relevant here.** All record an epic breadcrumb; **none** mutate the source retro. "Not relevant here" is the new home for "doesn't apply to this work" and is fully reversible (next run can re-surface and re-judge it).

2. **Keep "Obsolete" as a deliberately-gated in-cycle retire.** Retained per Chris's preference for the term. Not a peer option — a confirmed action requiring a typed reason and an explicit "this removes the lesson for all future runs" warning. Covers Bella's escape hatch: mid-epic, when you can *guarantee* the lesson's usefulness has passed. This is the only in-cycle path that writes a durable `**Retired**` marker.

3. **Add a deliberate out-of-cycle retirement action: `/cpm:retro retire` (or equivalent argument).** Mirrors the existing `learn` flow: list live (non-retired) observations → select → confirmation preview → write durable `**Retired**` marker at source. Retirement's natural home is a deliberate review pass, not the hot path.

### Active thread (at wrap-up)

Chris confirmed: include Bella's in-cycle retire, keep the term "Obsolete" for it, add the per-run "Not relevant here", and add the deliberate `/cpm:retro` retirement action. Proceeding to `/cpm:quick` to implement.

### Open questions for implementation

- Exact wording/UX of the gated in-cycle "Obsolete" confirmation (typed reason + warning).
- Whether the deliberate action is `/cpm:retro retire`, an argument, or folded into a broader `review` action.
- Doc touch-points: `cpm/skills/do/SKILL.md` (gate), `cpm/shared/skill-conventions.md` (Retro Retirement — "who retires"), `cpm/skills/retro/SKILL.md` (new action), `cpm/skills/ralph/SKILL.md` (autonomous-mode mapping table currently references the Applied/Deferred/Obsolete triad).
