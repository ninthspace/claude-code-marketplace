---
name: calibrate
description: Recommend the Claude model and effort level for a piece of work — given a CPM artefact (epic, spec, brief, discussion, quick record), a skill the user is about to run, a plain description of a task, or a whole set of these at once, answered as a table — with the reasons, the commands to set them, and what would change the answer. Use whenever the user asks which model or effort to use, whether something needs Opus, whether Sonnet or a lower effort would do, or how to keep a run cheaper or faster without losing quality. Triggers on "/cpm-next:calibrate".
---

# Calibrate

Tell the user which model and effort level fit the work in front of them, and why. This skill reads and advises; it never switches the model or effort itself, because in Claude Code those are the user's settings.

## Work out the task's shape

`$ARGUMENTS` is one of three things, or several of them. Read whatever it points at before judging.

- **An artefact.** An epic's shape is its story count, how many stories are still open, whether the run will be unattended, how much of the codebase the stories touch, and whether its criteria are mechanical or call for judgment. A spec or brief means planning work next, and a discussion means `party` or `plan`. Read the artefact's source spec when its difficulty isn't clear from the artefact alone.
- **A skill.** Read its `SKILL.md`, whether it is a cpm-next skill, a v3 skill or any other, and judge what the skill makes the model do: hold a live conversation, write documents, read widely, or edit code over many steps. When the user names both a skill and an artefact (`do` on this epic), judge the pair.
- **A description.** Take it at face value, and look at the repository only if the answer depends on it (how large the affected code is, say).
- **A set.** Several paths, a glob, a directory, or a phrase such as "all open epics" or "every cpm-next skill". Expand it to its items and judge each one separately. When there are many, split the reading across parallel subagents on `sonnet` and check what each reports against the files it cites. Leave out items that are finished (`Complete`, `Superseded`, `Withdrawn`) unless the user asked for them, and say how many were left out.

Then place the task on four axes, since those decide the answer:

1. **Difficulty and horizon**: a short, well-specified step, or long multistep work where an early mistake compounds.
2. **Attention**: whether the user is watching and replying, or it runs unattended.
3. **Latency**: whether someone is waiting on each reply, as in facilitation or chat.
4. **Cost of a wrong answer**: whether errors are caught cheaply by tests and review, or land in a plan that everything downstream builds on.

Ask one question only if an axis can't be read from the input and would change the recommendation. Otherwise state what you assumed.

## Choose

Prefer the cheapest setting that holds quality, and raise it only for a reason you can name. Effort is the first lever: a capable model at lower effort usually beats a weaker model at higher effort, and lowering effort cuts thinking more reliably than telling the model to think less.

What each model is for, as of September 2026:

| Model | Fits | Effort |
|---|---|---|
| **Opus 5.5** | Long-horizon and unattended work, planning whose mistakes compound, large brownfield changes, code review | Defaults to `medium`, which matches or beats Opus 5 at `high` on coding. `low` comes close on routine coding. Use `high` for long unattended runs and hard planning; keep `xhigh` and `max` for work where a lower level measurably fell short. |
| **Sonnet 5.5** | Well-specified agentic coding, facilitation, status and library work, and subagent workers such as review personas or per-area code readers | `medium` for well-specified coding, `high` for longer or harder work, `low` or `medium` for chat. At `low` it can report a change done without running a check. At `low` and `medium` it tends to stop and check in during long agentic runs. At `xhigh` and `max` it adds its own review rounds. |
| **Fable 5.1** | The hardest reasoning and longest-horizon work, where Opus 5.5 has already fallen short | Priced above Opus, with long turns. Recommend it only with a stated reason. |
| **Haiku 4.5** | Narrow, mechanical subagent work: lookups, extraction, formatting | Has no effort setting. |

Every cpm-next skill except this one sets its own model and effort in frontmatter, for the turn that invokes it: `plan` and `review` on Opus 5.5 at `medium` with Opus subagents; `do` on Sonnet 5.5 at `medium` with Sonnet subagents and an Opus 5.5 `auditor` for each story; `party` and `library` on Sonnet 5.5 at `medium`; `status` on Sonnet 5.5 at `low`. The `cpm-next-models` mod, when installed, holds that model and effort for the rest of the skill's run and raises `do all` to `high`. So for a cpm-next skill, recommend a setting only where these defaults don't fit, and give the command for it:

- `plan`: `/effort high` for greenfield work, a large spec, or deep brownfield grounding.
- `party`: `/model opus` for a decision whose trade-offs are subtle.
- `do`: `/effort high` for an attended epic that cuts across unfamiliar code.
- Without the mod, a turn that continues the run falls back to the session's model and effort: give the `/model` and `/effort` to match the skill's frontmatter.

If the user names a model this table doesn't cover, or the table looks out of date, check the current prompting guide for that model under `https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/` before recommending it, and say that you did.

## Answer

Keep it short:

- **Recommendation**: model and effort, and the commands to set them (`/model {name}`, `/effort {level}`). Add a second setting when part of the work warrants a different one: the subagents in a `review`, say, or the planning half of a plan-then-build request.
- **Why**: one or two sentences tied to the axes above.
- **Watch for**: what to look out for at that setting, such as Sonnet 5.5 stopping early at `medium` in a long run, and what should prompt moving up or down a level.
- **Cheaper alternative**, when there is one worth considering, with what it risks.

For a set, answer with a table instead, one row per item, in the order the work would run:

| Item | Next skill | Model | Effort | Subagents | Why |
|---|---|---|---|---|---|

`Next skill` is the skill the item needs next (`do` for an open epic, `plan` for a spec without epics). Leave `Subagents` blank when that skill doesn't start any. Keep `Why` to one clause. Below the table, name the rows that share a setting and could run in one session without switching, and give the **Watch for** notes that apply across the set rather than repeating them on each row.

When the user is running a controlled comparison, such as the one in the cpm-next README, point out any recommendation that would change a variable the comparison holds fixed.
