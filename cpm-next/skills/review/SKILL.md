---
name: review
description: Adversarial review of CPM epics before they are built — roster personas, working independently, look for criteria that can't be checked, hidden complexity, missing or wrong dependencies, Must Have requirements no story covers, and conflicts with ADRs or the code. Fixes what it can in Pending stories, and writes a review record of the rest. Use before running a large or risky epic, after a pivot, or whenever the user wants a second opinion on a plan. Triggers on "/cpm-next:review".
model: opus
effort: medium
---

# Review

Find what would make these epics fail when `do` runs them, while it is still cheap to fix. Formats, the review record and the amendment rules are in `shared/artifacts.md`, two levels above this skill's directory.

## Scope and finish line

| Argument | Scope |
|---|---|
| epic path | that epic |
| epic path and story number | that story, in its epic's context |
| `all` | every epic with no story started |
| nothing | the lowest-numbered epic with no story started; say which one you picked |

Done when a review record exists for the scope, every Critical and Warning finding is fixed in the epic or listed under **Needs you**, and each epic with Pending stories is at least as ready for `do` as before.

## 1. Gather context

Read the epics, each epic's source spec, the ADRs, `docs/library/`, recurring signals, and retro observations not marked `**Retired`. In a brownfield project, also read the code the stories touch: a story that contradicts the code is the costliest thing a review can miss.

## 2. Review independently

Load personas from `docs/agents/roster.yaml`, or the plugin's `agents/roster.yaml` when the project has none. Pick three for an epic, or two for a single story: at least one asking "should we build this?" (usually the PM or Scrum Master) and at least one asking "can we build it like this?" (the Developer or Architect). Add others where the content calls for them, such as the QA or Test Engineer for heavily tested work or UX for user-facing flows.

Give each persona its own subagent, all started in parallel on the `opus` model, with the epic, the context above and its roster entry, but none of this conversation or of the reasoning behind the plan: the point is a view that doesn't share the author's assumptions. Weighing and fixing stay with you. Tell each to report every problem its role notices, tagged with a severity and a Story, criterion or task reference, without trimming its list: selection happens afterwards. Ask them to check, among whatever else they notice:

- criteria that `do` couldn't verify, or that different builders would read differently. Accept a `[user]` criterion written with its exact steps and observation in the spec's final user-checks epic, or in a `00-` epic's final story that no other story names in `**Blocked by**`. Flag a `[user]` criterion anywhere else, a user-checks epic not blocked by the epics (or a `00-` final story not blocked by the stories) whose work its criteria check, any epic that names the user-checks epic in `**Blocked by**`, and any criterion that combines two kinds of proof;
- criteria that name one instance where their requirement covers every case ("the January export streams its rows" where every export must), and a regression criterion with no criterion for its rule beside it, not counting a control's inputs, the members a set must contain, or a `[user]` check's steps;
- outcomes, error states or edge cases with no criterion;
- work that looks simple and isn't, given the actual code;
- `**Blocked by**` lines that are missing, circular or unnecessary, and stories that share files or state but could be run in parallel;
- Must Have requirements that no story's `**Satisfies**` names, and `**Satisfies**` lines naming requirements that don't exist;
- stories that contradict an ADR, the library or the code.

Give the lesson check to one persona only, adding none for it: the Test Engineer or QA when one is picked, otherwise the persona asking "can we build it like this?". It checks each `(Story {N})` entry on the epic's `**Lessons**` line against a criterion in that story; when the epic has no `**Lessons**` line, it finds the library lessons, recurring signals and unretired retro observations that bear on the epic. An entry may be a lesson or a signal reference. A bearing lesson no criterion reflects is a Warning; a `(build)` entry needs no criterion.

## 3. Weigh and fix

Check each finding against the files it cites and drop any that don't hold up. Merge duplicates, then keep only the findings that would change what gets built or how it is checked.

Fix Critical and Warning findings in `Pending` stories when the fix is clear and changes nothing the user decided, editing in place with an `**Amended**` line citing the review. Never change a `Complete` or `In Progress` story: add a new story instead, or list the finding under **Needs you**. A finding whose fix would change scope, or overturn a spec requirement or architecture decision, goes to **Needs you** unfixed. Suggestions are recorded, not applied.

Write the review record, with a Remediation entry for every finding you kept.

## Finishing

End with three headings:

- **Needs you**: findings waiting on a decision, Critical first, or "Nothing".
- **Fixed**: one line per change made to an epic.
- **Next**: `/cpm-next:do {epic}` when it's ready, or `/cpm-next:plan {spec}` when a finding reaches back into the spec.

Then take the **Needs you** findings one at a time, Critical first. For each, say in a few lines what it is and where, what each way of settling it leads to, and which you recommend and why. Ask it alone in one AskUserQuestion call, with your recommendation as the first option and `Leave it for now` as the last. Act on the answer before raising the next finding: fix the `Pending` story or add a new story, with an `**Amended**` line citing the review and the decision, and update the finding's Remediation entry. A finding that reaches back into the spec is settled by `/cpm-next:plan`: recommend that and leave the spec alone. After the last finding, restate **Fixed** and **Next** if the answers changed them.
