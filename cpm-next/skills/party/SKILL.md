---
name: party
description: Multi-perspective discussion with named specialist personas (PM, Architect, Developer, UX, QA, DevOps and others) who build on and disagree with each other, or a focused one-to-one with a single expert. Use for brainstorming, weighing trade-offs, or testing an idea before committing to a plan, whether or not any planning documents exist yet. Saves a discussion record that /cpm-next:plan can read. Triggers on "/cpm-next:party", "party mode", "get the team's view", or a request to hear several perspectives on a decision.
model: sonnet
effort: medium
---

# Party

Bring a team of personas into one conversation so the user hears real disagreement before deciding. Party widens the options and makes the trade-offs explicit; converging them into requirements is `plan`'s job.

Artefact formats, paths and numbering are in `shared/artifacts.md` at the plugin root, two levels above this skill's directory.

## Starting

- Load personas from `docs/agents/roster.yaml` if it exists, otherwise from `agents/roster.yaml` at the plugin root. Draw each voice only from the traits its roster entry defines.
- `$ARGUMENTS` may be a topic, a file path or URL to read, or a persona's name. A lone persona name (or "consult {name}") starts a one-to-one: that persona leads every turn, and others join only when the user invites them.
- The team argues from the project's actual state, not a generic one. Before the first round, look at the `docs/` artefacts and, when the topic touches code, the code. During the discussion, look up anything the code or docs can answer before a persona speaks; ask the user only about intent, priorities and preferences.
- Create the record `docs/discussions/{nn}-discussion-{slug}.md` at once, numbered per the contract, and introduce the roster in one compact line. If there's a topic, go straight into the first round.

## Each round

Pick the two or three personas whose expertise the current point needs most, favouring anyone who hasn't spoken for a while; a persona the user names always speaks. Two distinct views are worth more than three similar ones.

Each contribution is `{icon} **{displayName}**: {response}`, a few sentences long. Every persona recommends something rather than only observing. Personas respond to each other by name, and genuine disagreement is left standing rather than smoothed into consensus.

Only once the discussion has converged, or split into two clear paths, say so in one line after the round: `💡 **The team recommends**: …`, or `💡 **Two paths**: …` naming who backs each.

End each round with *Type **wrap up** to finish, or keep going.* Not "exit" or "quit", which close Claude Code itself.

## The record is the state

Update the record every few substantive exchanges, not only at the end. It is what survives context compaction and what `plan` reads later, so write it for a reader who wasn't there:

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

On "wrap up", "done" or similar: finalise the record, set its status to `Concluded`, and give the path. Then name the next move in one line, usually `/cpm-next:plan {record path}`, or nothing further if the discussion was exploratory.
