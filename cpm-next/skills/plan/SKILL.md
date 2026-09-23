---
name: plan
description: Turn whatever planning material already exists into the next artefacts needed to build — product brief, spec, and epics with stories and acceptance criteria — for greenfield or brownfield projects in any starting state. Reads existing discussions, briefs, specs, ADRs, epics, PRDs, READMEs and code, fills only the gaps, and amends existing documents when direction changes. Use whenever the user wants to plan, scope, specify, break down or re-plan work, even if they only name one of brief, spec or epics. Triggers on "/cpm-next:plan".
---

# Plan

Produce the planning artefacts that let `do` build the right thing. The brief, spec and epics are outputs, not stages to walk through: work out what exists, decide what's missing, and write that, at the depth the work actually needs.

Formats, paths, numbering and status rules are in `shared/artifacts.md` at the plugin root, two levels above this skill's directory. Read it before writing anything. Other tools parse these files, so the formats are fixed even where the process is flexible.

## Done means

Unless the user names another target, this run is done when:

- every artefact from where the project stands down to epics exists, and each traces to the one above it;
- every Must Have requirement is satisfied by at least one story, and every story's `**Satisfies**` names real requirements;
- every acceptance criterion is something `do` can check, by a test or by a concrete manual step;
- nothing the user still has to decide is hidden inside a story. Decisions go in Assumptions or come back as questions.

The user can name a nearer target: "just the brief", "up to spec", "only epics for FR7–FR9". Stop there.

## 1. Take stock

Read what exists before asking anything:

- `docs/` in full: discussions, plans, briefs, architecture, specs, epics (including status), retros, library, quick.
- Planning material outside CPM's shape: `PRD.md`, `README.md`, `docs/*.md`, `CLAUDE.md`, issue text the user pastes.
- In a brownfield project, the code: stack, conventions, the modules the work touches, the test setup and test command. For a large codebase, give each area to its own subagent, running in parallel, and check what each one reports against the files it cites.
- `$ARGUMENTS`, which may be a description, a path, a target, or nothing. With nothing, the most recent unconcluded discussion or the most recent spec without epics is the likely starting point. Say which one you picked.

From this, name the starting point in one or two sentences: what exists, what's missing, and what this run will produce. Then carry on without waiting for approval.

## 2. Ask once, then work

Collect every question whose answer only the user holds and whose answer would change scope, cost, or a choice that is hard to reverse. Ask them together in one AskUserQuestion call (up to four; merge or drop the rest). Each question offers options and a recommended default.

Everything else, decide yourself and record it in the artefact's Assumptions section, so the user can overturn it at review. If the material already answers a question, don't ask it.

If there are no such questions, say so and go straight to writing.

## 3. Write what's missing

Work top-down from the first missing artefact. Skip any level that would only restate the one above it. A small, well-understood change can go from a discussion or description straight to a `00-` epic.

**Brief**: when the problem, users or value aren't yet written down anywhere. Offer two or three genuinely different approaches, pick one with reasons, and keep the rest as alternatives considered.

**Spec**: MoSCoW requirements with stable labels, measurable NFRs, architecture decisions with the alternatives rejected, explicit scope boundaries, and a testing strategy tied to the project's real test command. In a brownfield project, ground every requirement in the current code: name the existing models, routes or components it extends. Write a separate ADR only for a decision that will outlive this spec.

**Epics**: split by coherent deliverable, not by layer. Stories are units of value with testable criteria; tasks are the steps inside a story. Set `**Blocked by**` only for real ordering constraints, since `do` runs unblocked stories and may run independent ones in parallel.

When the spec is non-trivial, put it through a challenge pass before writing epics: give the draft to two or three roster personas as subagents, each told to find what would make the plan fail from their perspective. Fold in what holds up, and note in Assumptions what you chose not to act on and why.

## Existing material

- **Adopt, don't regenerate.** If a brief, spec or epics already exist, build on them. Write in CPM format when you produce something new, but don't convert documents that aren't going to change.
- **Foreign epics or task lists** that `do` needs to run are converted into the epic format, with the original's path in `**Source spec**`. Map items that are clearly finished to `Complete`.
- **Changing direction** is an amendment to an existing file: edit it in place with an `**Amended**` line and carry the change down to every affected `Pending` story in the same pass. Never rewrite a `Complete` story; add a new one. Resolve every `**Pivot deferred**` breadcrumb that points at a file you're amending, and remove it once resolved.
- **Conflicts between documents**, or between documents and code, are reported with both sources cited. Settle them in the artefact you're writing, or ask about them if they're the user's call.

## Finishing

End with three short headings:

- **Needs you**: open decisions and the assumptions most worth checking, first.
- **Written**: each path, one line on what it holds.
- **Next**: normally `/cpm-next:do {first epic}`, or `/cpm-next:do all` when the epics are ready to run unattended. Suggest `/cpm-next:review {epic}` first when an epic is large, touches unfamiliar code, or is about to run unattended.
