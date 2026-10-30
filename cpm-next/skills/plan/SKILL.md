---
name: plan
description: Turn whatever planning material already exists into the next artefacts needed to build — product brief, spec, and epics with stories and acceptance criteria — for greenfield or brownfield projects in any starting state. Reads existing discussions, briefs, specs, ADRs, epics, PRDs, READMEs and code, fills only the gaps, and amends existing documents when direction changes. Use whenever the user wants to plan, scope, specify, break down or re-plan work, even if they only name one of brief, spec or epics. Triggers on "/cpm-next:plan".
model: opus
effort: medium
---

# Plan

Write the planning artefacts `do` needs to build the right thing: only what's missing, at the depth the work needs. The brief, spec and epics are outputs, not stages to walk through.

Read `shared/artifacts.md`, at the plugin root two levels above this skill's directory, before writing anything. Other tools parse these files, so its formats, paths, numbering and status values are fixed.

## Done means

Unless the user names a nearer target ("just the brief", "up to spec", "only epics for FR7–FR9"), where the run stops, it is done when:

- every artefact from where the project stands down to epics exists, and each traces to the one above it;
- every Must Have requirement is satisfied by at least one story, and every story's `**Satisfies**` names real requirements;
- every acceptance criterion is something `do` can check, by a test or by a concrete manual step, or is a `[user]` criterion written with its exact steps and the observation that proves it;
- nothing the user still has to decide is hidden inside a story: decisions go in Assumptions or come back as questions.

## 1. Take stock

Read what exists before asking anything:

- `docs/` in full, and planning material outside CPM's shape: `PRD.md`, `README.md`, `CLAUDE.md`, issue text the user pastes.
- In a brownfield project, the code: stack, conventions, the modules the work touches, the test setup and test command. For a large codebase, give each area to its own subagent on `opus`, in parallel, and check each report against the files it cites. For a plain lookup, use the `cpm-next:scout` agent, which runs on Haiku and returns only the answer.
- `$ARGUMENTS`: a description, a path, a target, or nothing. With nothing, the likely starting point is the most recent unconcluded discussion or the most recent spec without epics; say which you picked.

Then state the starting point in one or two sentences, what exists, what's missing and what this run will produce, and carry on without waiting for approval.

## 2. Ask once, then work

Ask every question that only the user can answer and whose answer would change scope, cost or a choice that is hard to reverse, together in one AskUserQuestion call: up to four, merging or dropping the rest, each with options and a recommended default. Don't ask what the material already answers. Decide everything else yourself and record it in the artefact's Assumptions, for the user to overturn at review. If there are no such questions, say so and go straight to writing.

## 3. Write what's missing

Work top-down from the first missing artefact, skipping any level that would only restate the one above. A small, well-understood change can go from a discussion or description straight to a `00-` epic.

**Brief**: when the problem, users or value aren't yet written down anywhere. Offer two or three genuinely different approaches, pick one with reasons, and keep the rest as alternatives considered.

**Spec**: the contract's sections, with the testing strategy tied to the project's real test command. In a brownfield project, ground every requirement in the current code by naming the models, routes or components it extends. Write a separate ADR only for a decision that will outlive this spec.

When the spec is non-trivial, put it through a challenge pass before writing epics: two or three roster personas, each a subagent on `opus`, look for what would make the plan fail from their perspective. Fold in what holds up, and record in Assumptions what you chose not to act on and why.

**Epics**: split by coherent deliverable, not by layer, into stories that are each a unit of value. A criterion stating what must not happen, must not change or never occurs names its control in its own text: the same inputs, in the same fixture, with the forbidden outcome present, fail the check (remove the guard, or make the forbidden change); and, where it compares a set, a floor that names members the set must contain, since a check that the set is not empty passes with members missing. A negative assertion with no control passes when the feature does nothing. Tag each criterion by who or what proves it, and split one that needs two kinds of proof (a browser check and a test, or a test and a user step) into one criterion per proof. A spec's `[user]` criteria go in one final user-checks epic of that spec, so that no other work waits on the user: no other epic names it in `**Blocked by**`, it is blocked by the epics whose work its criteria check, and a story in it that holds `[user]` criteria is blocked by nothing that holds one. A spec with no `[user]` criteria gets no such epic. A `00-` epic puts its `[user]` criteria in a final story that no other story names in `**Blocked by**` and that is blocked by the stories whose work its criteria check.

**Story fields**: set `**Blocked by**` only for a real ordering constraint, since `do` runs unblocked stories, in parallel where they are independent. Give a story `**Effort**: high` when a mistake would be costly or hard to see: security, authorisation, migrations and other data changes, concurrency, executable scripts and hooks, or code the plan found hard to understand. Give it `**Effort**: low` when it is mechanical: a config value, a copy change, a rename, a row in a table. Otherwise leave the field off. Add `**Model**: haiku` only to a `low` story whose edit the story fully determines, leaving no choice of where or how to make it.

**Lessons**: before writing an epic's criteria, decide which library lessons and unretired retro observations bear on the epic's area. When `docs/retros/` holds more than 20 files, have `scout` list the headings and observation openings that match the files, modules or terms the epic touches, and judge which bear. Reflect a lesson about what the result must satisfy or how it is checked in a criterion of the story it applies to; name a lesson about how to build without a criterion. Name each bearing lesson in the epic header's `**Lessons**` line as a lesson reference followed by `(Story {N})` or `(build)`: once for each story whose criteria reflect it, and again as `(build)` if it also bears on how to build. Omit the line when none bears, and list no lesson that doesn't. When two lessons conflict, or a library document has been superseded, follow the newer one and record the choice in the spec's Assumptions.

## Existing material

- **Adopt, don't regenerate.** Build on an existing brief, spec or epics. Write anything new in CPM format, but don't convert documents that aren't going to change.
- **Foreign epics or task lists** that `do` needs to run are converted into the epic format, with the original's path in `**Source spec**`; items clearly finished become `Complete`.
- **Changing direction** is an amendment: edit the file in place with an `**Amended**` line and carry the change down to every affected `Pending` story in the same pass. Never rewrite a `Complete` story; add a new one. Resolve every `**Pivot deferred**` breadcrumb that points at a file you're amending, and remove it once resolved.
- **Conflicts between documents**, or between documents and code, are reported with both sources cited. Settle them in the artefact you're writing, or ask if they're the user's call.

## Finishing

End with three short headings:

- **Needs you**: open decisions and the assumptions most worth checking, first.
- **Written**: each path, with one line on what it holds.
- **Next**: normally `/cpm-next:do {first epic}`, or `/cpm-next:do all {spec}` when the spec's epics are ready to run unattended. Suggest `/cpm-next:review {epic}` first when an epic is large, touches unfamiliar code, or is about to run unattended.

Then take the **Needs you** items one at a time, in order. For each, say in a few lines what it is, which document and section it touches, what each answer would change, and which you recommend and why. Ask it alone in one AskUserQuestion call, with your recommendation as the first option and `Leave it for now` as the last, and act on the answer before raising the next item: amend the document it concerns and the `Pending` stories it reaches, with an `**Amended**` line where the document existed before this run. A confirmed assumption needs no edit. After the last item, restate **Next** if the answers changed it.
