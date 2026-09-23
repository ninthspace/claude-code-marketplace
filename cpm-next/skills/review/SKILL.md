---
name: review
description: Adversarial review of CPM epics before they are built — roster personas, working independently, look for criteria that can't be checked, hidden complexity, missing or wrong dependencies, Must Have requirements no story covers, and conflicts with ADRs or the code. Fixes what it can in Pending stories, and writes a review record of the rest. Use before running a large or risky epic, after a pivot, or whenever the user wants a second opinion on a plan. Triggers on "/cpm-next:review".
---

# Review

Find what would make these epics fail when `do` runs them, while it is still cheap to fix. `plan` puts the spec through a challenge pass; this is the equivalent for the epics, carried out by reviewers who didn't write them.

Formats, the review record and the amendment rules are in `shared/artifacts.md` at the plugin root, two levels above this skill's directory.

## Scope and finish line

| Argument | Scope |
|---|---|
| epic path | that epic |
| epic path and story number | that story, in its epic's context |
| `all` | every epic with no story started |
| nothing | the lowest-numbered epic with no story started; say which one you picked |

Done when a review record exists for the scope, every Critical and Warning finding has been fixed in the epic or is listed under **Needs you**, and each epic with Pending stories is at least as ready for `do` as it was before the review.

## 1. Gather context

Read the epics, each epic's source spec, the ADRs, `docs/library/`, and retro observations not marked `**Retired`. In a brownfield project, read the code the stories touch as well: a story that contradicts the code is the most expensive thing a review can miss.

## 2. Review independently

Load personas as `party` does. Pick three for an epic, or two for a single story. At least one should ask "should we build this?" (usually the PM or Scrum Master) and at least one "can we build it like this?" (the Developer or Architect). Add others where the content calls for them, such as the QA or Test Engineer for heavily tested work or UX for user-facing flows.

Give each persona to its own subagent, running in parallel, with the epic, the context above and its roster entry. It gets none of this conversation and none of the reasoning that produced the plan, since the point is a view that doesn't share the author's assumptions. Tell each one to report every problem its role notices, tagged with a severity and a Story, criterion or task reference, and not to trim its list; selection happens afterwards. Ask them to check, among whatever else they notice:

- criteria that `do` couldn't verify, or that different builders would read differently;
- outcomes, error states or edge cases with no criterion at all;
- work that looks simple and isn't, given the actual code;
- `**Blocked by**` lines that are missing, circular or unnecessary, and stories that share files or state but could be run in parallel;
- Must Have requirements that no story's `**Satisfies**` names, and `**Satisfies**` lines that name requirements that don't exist;
- stories that contradict an ADR, the library, a retro lesson or the code.

## 3. Weigh and fix

Check each finding against the files it cites, and drop any that don't hold up. Merge duplicates, then keep the findings that would change what gets built or how it is checked, and drop the rest.

Fix Critical and Warning findings directly in `Pending` stories when the fix is clear and changes nothing the user decided. Edit in place with an `**Amended**` line citing the review. Never change a `Complete` or `In Progress` story; add a new story instead, or list the finding under **Needs you**. A finding whose fix would change scope, or overturn a spec requirement or architecture decision, goes to **Needs you** unfixed. Suggestions are recorded, not applied.

Write the review record, with a Remediation entry for every finding you kept.

## Finishing

End with three headings:

- **Needs you**: findings waiting on a decision, Critical first. Say "Nothing" if so.
- **Fixed**: one line per change made to an epic.
- **Next**: `/cpm-next:do {epic}` when it's ready, or `/cpm-next:plan {spec}` when a finding reaches back into the spec.
