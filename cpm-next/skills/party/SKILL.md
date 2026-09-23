---
name: party
description: Multi-perspective discussion with named specialist personas (PM, Architect, Developer, UX, QA, DevOps and others) who build on and disagree with each other, or a focused one-to-one with a single expert. Use for brainstorming, weighing trade-offs, or testing an idea before committing to a plan, whether or not any planning documents exist yet. Saves a discussion record that /cpm-next:plan can read. Triggers on "/cpm-next:party", "party mode", "get the team's view", or a request to hear several perspectives on a decision.
---

# Party

Bring a team of personas into one conversation so the user hears real disagreement before deciding. This is the divergent part of the method: its job is to widen the options and sharpen the trade-offs. Converging into requirements is `plan`'s job.

Artefact formats and paths are in `shared/artifacts.md` at the plugin root, two levels above this skill's directory.

## Starting

- Load personas from `docs/agents/roster.yaml` if it exists, otherwise from `agents/roster.yaml` at the plugin root. Draw each voice only from the traits its roster entry defines.
- `$ARGUMENTS` may be a topic, a file path, a URL, or a persona's name. Read files and fetch URLs. A lone persona name (or "consult {name}") starts a one-to-one: that persona leads every turn, and others join only when the user invites them.
- Before the first round, look at what the project already has: `docs/` artefacts and, when the topic touches code, the code itself. The team should argue from the actual state of the project, not a generic one.
- Create the discussion record at once (numbering per the contract) and introduce the roster in one compact line. If there's a topic, go straight into the first round.

## Each round

Pick the two or three personas whose expertise the current point needs most, favouring anyone who hasn't spoken for a while. A persona the user names always speaks.

Format each contribution as `{icon} **{displayName}**: {response}`. What makes a round worth reading:

- Every persona recommends something. Observations without a recommendation are half an answer.
- Personas respond to each other by name, and genuine disagreement is left standing rather than smoothed into consensus.
- Anything discoverable in the code or docs is looked up before anyone speaks. Questions to the user are only for intent, priorities and preferences.
- A few sentences each. Two sharp, distinct views beat three similar ones.

When the discussion has visibly landed, say so in one line after the round: `💡 **The team recommends**: …`, or `💡 **Two paths**: …` naming who backs each. Don't signal convergence before it has happened.

End each round with: *Type **wrap up** to finish, or keep going.* ("exit" and "quit" close Claude Code itself.)

## The record is the state

Update the discussion record every few substantive exchanges, not just at the end. It is what survives context compaction and what `plan` reads later, so write it for a reader who wasn't there:

```markdown
# Discussion: {Topic}

**Date**: {YYYY-MM-DD}
**Participants**: {display names}
**Status**: In progress | Concluded

## Context
## Decisions
- {decision} — {who argued for it and why}
## Open Questions
## Positions Not Taken
- {option} — {why it lost, and who still favours it}
## Recommended Next Step
```

If a session resumes and finds a record with `**Status**: In progress`, carry on from it.

## Finishing

On "wrap up", "done" or similar: finalise the record, set its status to `Concluded`, and give the path. Then name the natural next move in one line, usually `/cpm-next:plan {record path}`, or say nothing further if the discussion was exploratory.
