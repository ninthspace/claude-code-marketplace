# Discussion: Amend the progress tracker (cpm-next-progress)

**Date**: 2026-11-11  
**Participants**: Jordan, Margot, Bella  
**Status**: Concluded

## Context
`/progress-tracker` is a command registered by the `cpm-next-progress` mod (`cpm-next-progress/hooks/register.ts`), not a SKILL.md. It checks trackers against epic docs, prepares a spec's tracker (`NN`), reports `times`, and shows `all` / `all publish`. The tracker page is `cpm-next-progress/page/tracker.html`: a decisions box above a table with columns #, Item, Title, Status, Blocked by, Risk / notes, Updated.

Prompt for the change: a post by Vox (x.com/Voxyz_ai, 2026-11-10) recommending an HTML dashboard built before a long autonomous run, showing progress, blockers, pending questions and default actions. Replies to the post could not be retrieved.

Today `effort` is parsed per story (`progress.ts:169`); model is not recorded. Timing (`timing.ts`) gives a started time and, once 10 stories are timed and the spread is steady, a typical range per effort level. Decision entries carry a `[epic story, kind]` prefix, for example `[01-05 S4, review]`, which can be matched to stories.

## Decisions

- Show pending questions and blockers on the tracker — Jordan: the new value is seeing what is waiting before and during a run.
- Do not show default actions — Margot: they contradict the global rule that a timeout is not approval.
- Extend the existing tracker page; no separate dashboard subagent — Bella: a second page is a second source of truth.
- Add a Model column and keep Effort — requested by the user; model must be captured by the mod, effort already is.
- Layout D (split view): a table on the left, the selected story's detail on the right. The user chose it over A (inline sub-row), B (attention column) and C (cards).
- The list stays a table with columns #, Title, Status, Model, Effort, Time, Needs you.
- Time column: "took N min" for complete stories, "N min in" plus "typically X–Y min" for the running one, "typically X–Y min" for pending ones. Typical ranges follow the existing rule (10 timed stories, steady spread); before that, elapsed time only.
- Detail panel for the selected story: model and effort, started time, running time, typical range, expected-by window (start plus typical range), Needs you items, acceptance criteria progress.
- Needs you is a count badge and is blank when 0.
- Decisions with no matching story show in a strip above the table.
- Each question or blocker appears with its story, matched by the decision's `[epic story, kind]` prefix.

## Open Questions

- Where the model is read from: the cpm-next-models `set_story_effort` tool and model-switch detection already exist; whether the tracker reads the model from the epic doc or from the mod's stored state is for the plan.
- Whether "expected by" is shown for a story that has run past its typical range.
- Format of the user-facing sample artifact: https://claude.ai/artifact/39M6y3ST9AzL3PFt8VDJQg (board D, version 8) is the reference mockup.

## Positions Not Taken

- Default actions per pending item — rejected on the "timeout is not approval" rule; Vox's post favours them.
- A dedicated `dashboard-builder` subagent — Bella; it duplicates the tracker page.
- Layout A (inline sub-row) — Jordan's and the assistant's first pick for keeping the table scan; D was chosen for room per story.
- Layout B (attention column) and C (cards) — B hides items behind a click; C needs several screens for ten stories.

## Recommended Next Step
`/cpm-next:plan docs/discussions/24-discussion-amend-progress-tracker-command.md`. This changes the mod's data capture (model), the page template and its writes, and the decision-to-story matching, so it needs a spec and epic rather than a quick change.
