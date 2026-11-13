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
| several epic paths, or a spec's epic prefix (`docs/epics/53`) | those epics, or every `docs/epics/53-*.md` that is not `Withdrawn` or `Superseded` and has a `Pending` story, as one scope with one record |
| `all` | every epic with no story started that is not `Withdrawn` or `Superseded` |
| nothing | the lowest-numbered epic with no story started that is not `Withdrawn` or `Superseded`; say which one you picked |

Done when a review record exists for the scope, every Critical and Warning finding is fixed in the epic, listed under **Needs you** or decided at challenge, and each epic with Pending stories is at least as ready for `do` as before.

## 1. Gather context

Read the epics, each epic's source spec, the ADRs, `docs/library/`, recurring signals, and retro observations not marked `**Retired`. In a brownfield project, also read the code the stories touch: a story that contradicts the code is the costliest thing a review can miss.

## 2. Review independently

Load personas from `docs/agents/roster.yaml`, or the plugin's `agents/roster.yaml` when the project has none. Pick three for an epic or a scope of several, or two for a single story: at least one asking "should we build this?" (usually the PM or Scrum Master) and at least one asking "can we build it like this?" (the Developer or Architect). Add others where the content calls for them, such as the QA or Test Engineer for heavily tested work or UX for user-facing flows.

Read the latest `**Personas**:` line of each source spec's **Challenge** section (their union for the scope). Within each required role, judged by the roster entry's `role` and `personality`, pick a persona not in that union that suits the content, and reuse the best-suited one when none does; pick added personas by fit, whether the challenge used them or not. Name every persona picked from that union on the **Reviewers** line in the contract's form, and compare personas by roster `name`.

Give each persona its own subagent, all started in parallel on the `opus` model, with every epic in the scope, the context above and its roster entry, but none of this conversation or of the reasoning behind the plan: the point is a view that doesn't share the author's assumptions. For each source spec with a **Challenge** section, write a copy of the spec without that section to a temporary directory, give the persona that copy as standing for the spec at the epic's `**Source spec**` path, and tell it not to open the original. Weighing and fixing stay with you. Tell each to report every problem its role notices, tagged with a severity and a Story, criterion or task reference, without trimming its list: selection happens afterwards. Ask them to check, among whatever else they notice:

- criteria that `do` couldn't verify, or that different builders would read differently. Accept a `[user]` criterion written with its exact steps and observation in the spec's final user-checks epic, or in a `00-` epic's final story that no other story names in `**Blocked by**`. Flag a `[user]` criterion anywhere else, a user-checks epic not blocked by the epics (or a `00-` final story not blocked by the stories) whose work its criteria check, any epic that names the user-checks epic in `**Blocked by**`, and any criterion that combines two kinds of proof;
- criteria that name one instance where their requirement covers every case ("the January export streams its rows" where every export must), and a regression criterion with no criterion for its rule beside it, not counting a control's inputs, the members a set must contain, or a `[user]` check's steps;
- outcomes, error states or edge cases with no criterion;
- work that looks simple and isn't, given the actual code;
- `**Blocked by**` lines that are missing, circular or unnecessary, and stories that share files or state but could be run in parallel;
- Must Have requirements that no story's `**Satisfies**` names, and `**Satisfies**` lines naming requirements that don't exist;
- stories that contradict an ADR, the library or the code.

Give the lesson check to one persona only, adding none for it: the Test Engineer or QA when one is picked, otherwise the persona asking "can we build it like this?". It checks each `(Story {N})` entry on the epic's `**Lessons**` line against a criterion in that story, for each epic in the scope; when an epic has no `**Lessons**` line, it finds the library lessons, recurring signals and unretired retro observations that bear on the epic. An entry may be a lesson or a signal reference. A bearing lesson no criterion reflects is a Warning; a `(build)` entry needs no criterion.

## 3. Weigh and fix

- **Check.** Drop each finding the files it cites don't bear out.
- **Decided at challenge.** Settle a finding that repeats a `Rejected` decision in the **Challenge** section of the source spec of the epic the finding concerns (the latest bullet on its point) as decided at challenge: record it as the contract's `Decided at challenge:` entry says, and neither fix it nor put it in **Needs you**. A bullet the user confirmed is decided whatever the persona's severity.
- **Reopens challenge.** Otherwise weigh the finding as any finding, with the contract's `Reopens challenge:` entry, when its persona tagged it Critical (leave it unfixed and list it under **Needs you** quoting the decision), when it cites a criterion, task, code line, ADR, library document or spec amendment the recorded reason does not address, or when the bullet is superseded; a reopened finding whose fix would act against the rejection goes to **Needs you** for `/cpm-next:plan` and is not fixed in the epic. A finding that repeats a `Folded in` or `Does not hold` decision is weighed as any finding.
- **Keep.** Merge duplicates, then, besides the findings decided at challenge, keep only the findings that would change what gets built or how it is checked.

Fix Critical and Warning findings in `Pending` stories when the fix is clear and changes nothing the user decided, amending the story as the contract's **Amending an existing artefact** says, citing the review. Never change a `Complete` or `In Progress` story: add a new story instead, or list the finding under **Needs you**. A finding whose fix would change scope, or overturn a spec requirement or architecture decision, goes to **Needs you** unfixed. Suggestions are recorded, not applied.

Write the review record, with a Remediation entry for every finding you kept and every finding decided at challenge.

## Finishing

End with three headings:

- **Needs you**: findings waiting on a decision, Critical first, or "Nothing".
- **Fixed**: one line per change made to an epic.
- **Next**: `/cpm-next:do {epic}` when it's ready (`/cpm-next:do all {spec}` for all of a spec's open epics), or `/cpm-next:plan {spec}` when a finding reaches back into the spec.

After **Fixed**, one line gives the number of findings decided at challenge, when any were, and the review record's path.

Then take the **Needs you** findings one at a time, Critical first. For each, say in a few lines what it is and where, what each way of settling it leads to, and which you recommend and why. Ask it alone in one AskUserQuestion call, with your recommendation as the first option and `Leave it for now` as the last. Act on the answer before raising the next finding: fix the `Pending` story or add a new story, with an `**Amended**` line citing the review and the decision, and update the finding's Remediation entry. A finding that reaches back into the spec is settled by `/cpm-next:plan`: recommend that and leave the spec alone. After the last finding, restate **Fixed** and **Next** if the answers changed them.
