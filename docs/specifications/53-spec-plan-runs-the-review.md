# Spec: Plan runs the review it would suggest

**Date**: 2026-11-10  
**Amended**: review 10 (docs/reviews/10-review-plan-runs-the-review.md) and the user's decision — the contract's Review record brought into scope (FR6), the maintenance record for `status` reading it (FR8) (2026-11-10)  
**Source**: conversation (2026-11-10): "Can we also make another change where when an epic or epics are created we automatically send relevant ones to review?"; "I pretty much always follow the suggested reviews"

## Problem Summary

`/cpm-next:plan` ends by suggesting `/cpm-next:review {epic}` "first when an epic is large, touches unfamiliar code, or is about to run unattended" (`cpm-next/skills/plan/SKILL.md:66`, **Finishing**, **Next**). The user runs that review nearly every time, so the suggestion costs a round trip and a re-read of the same epics in a new turn, and an epic the user forgets to review goes to `do` unreviewed.

`/cpm-next:review` takes one epic, one story, `all` (every epic with no story started) or nothing (`cpm-next/skills/review/SKILL.md:14-19`); a plan run that writes two or more epics of one spec has no scope that names just them.

## Functional Requirements

### Must Have

- **FR1 — Plan runs the review.** When a `plan` run has written or amended epics with `Pending` stories, and one or more of them qualifies by the rule `plan` already holds (large, touches unfamiliar code, or about to run unattended), `plan` runs `/cpm-next:review` on the qualifying epics through the Skill tool before it finishes, in place of suggesting it. The rule is stated once, in `plan`'s **Finishing**. — AC: `plan/SKILL.md` states it; control: it no longer tells the user to run `/cpm-next:review` first for a qualifying epic `[manual]`
- **FR2 — What it says.** Before the review starts, `plan` names in one line each epic it sends to review and which part of the rule it meets, and each epic it does not send and why. — AC: `plan/SKILL.md` states it `[manual]`
- **FR3 — Order.** The review runs after `plan` has settled its own **Needs you** items, so it reads the epics as the user's answers left them, and before `plan` restates **Next**. — AC: `plan/SKILL.md` **Finishing** states the order; control: it says the review runs after the last **Needs you** item is settled `[manual]`
- **FR4 — Findings that reach the spec.** A review finding that reaches back into the spec, which `review` hands to `/cpm-next:plan`, is settled within the same `plan` run: `plan` asks it as one of its own **Needs you** items and amends the spec and the `Pending` stories by its own amendment rules, then updates the finding's Remediation entry in the review record. — AC: `plan/SKILL.md` states it; control: it says such a finding is not left for a later `/cpm-next:plan` run `[manual]`
- **FR5 — When it does not run.** No review runs when the run stops short of epics (a nearer target such as "just the brief" or "up to spec"), when no written or amended epic qualifies, or when the user's request says not to review. — AC: `plan/SKILL.md` states each; control: it says a run whose request says not to review sends nothing to review though an epic qualifies `[manual]`
- **FR6 — A review of several epics.** `review` accepts several epic paths, or a spec's epic prefix (`docs/epics/53`, every epic whose file name starts with it), as one scope: one review, one record and one set of personas across them. The contract's Review record (`cpm-next/shared/artifacts.md`, the review block) gives its **Source** as every epic path in the scope, in full and comma-separated (a prefix expanded, never a range), and a title naming the spec for a several-epic review. — AC: `review/SKILL.md`'s scope table has the row and the contract the field form; control: the existing rows (one epic, one story, `all`, nothing) are kept `[manual]`
- **FR7 — Status.** `status`'s **Next** (`cpm-next/skills/status/SKILL.md:35`) suggests `/cpm-next:review {epic}` before a large epic's first run only when no review record in `docs/reviews/` names that epic in its **Source**. — AC: `status/SKILL.md` states it; control: it still suggests the review for a large epic no record names `[manual]`

### Should Have

- **FR8 — Docs.** The cpm-next README (a log entry, an upgrade note; earlier entries stay), the root README's CPM Next section (`README.md:92`, "review before a large or risky epic (optional)"), `cpm-next-training-guide.html` (the plan section's finishing passage, the review section's scope, the quick-start and "after a pivot" lines), `cpm-next-onboarding.html` and `cpm-next-presentation.html` (the "optional" review card) say that `plan` runs the review for a qualifying epic and that `review` takes several epics or a spec's prefix; `docs/maintenance/README.md` records that `status` reads the review record's **Source** and date, which `review` writes in the contract's form. Versions: cpm-next 0.15.0, marketplace 4.0.11. — AC: each names it `[manual]`

### Won't Have (this iteration)

- Reviewing every epic a run writes, or a per-project setting.
- A review inside `do`.
- Changes to how `review` weighs or fixes findings.

## Non-Functional Requirements

- **NFR1**: No added sentence in a SKILL.md records history, per `CLAUDE.md` "A SKILL.md is not a change log".
- **NFR2**: `claude plugin validate cpm-next` passes, and `claude plugin test` passes for cpm-next, cpm-next-models, cpm-next-progress and whats-next.
- **NFR3**: The selection rule lives in `plan`'s **Finishing** only; `review`, `status` and the docs refer to it rather than restating it (library lesson "A rule is stated once; every other place refers to it and carries none of its terms").

## Architecture Decisions

### AD1: Plan invokes review as a skill
`plan` runs `review` through the Skill tool, so the review's own instructions, personas and record format apply unchanged and stay in one file. Rejected: copying review's steps into `plan` (two definitions of the review); a subagent running review (it would lose the user for review's **Needs you** walk).

### AD2: Plan's Needs you first, then the review
The user's answers can amend the epics, so the review reads the settled epics. Rejected: reviewing first (the answers could reopen what the review fixed).

## Scope

### In Scope
`cpm-next/skills/plan/SKILL.md` (**Finishing**, **Done means** if it names the review); `cpm-next/skills/review/SKILL.md` (**Scope and finish line**); `cpm-next/skills/status/SKILL.md` (**Next**); `cpm-next/shared/artifacts.md` (the Review record's **Source** and title); the docs in FR8; versions cpm-next 0.15.0, marketplace 4.0.11.

### Out of Scope
`do`, the auditor, the contract beyond the Review record, the mods.

## Testing Strategy

Prose changes are checked by reading each changed passage against its requirement, with `grep` for the required strings and for every remaining "suggest `/cpm-next:review`" or "optional" review phrase, each hit accounted for (`[manual]`); `claude plugin validate cpm-next` and `claude plugin test` on the four plugins for NFR2. No `[user]` checks: the next `plan` run in real use shows it.

## Assumptions

- The selection rule stays as it is; the user's "relevant ones" is the rule `plan` already applies, and an epic the rule leaves out is named with the reason (FR2), so the user can ask for it.
- A `00-` epic written straight from a description is covered by the same rule.
- A pivot that amends existing epics counts as amending; the training guide already recommends a review after a pivot.
- On a non-trivial spec the challenge pass still runs before the epics, and the review after them (the user's decision, 2026-11-10): a spec gap found only at review costs a re-plan of written epics.
- The spec's challenge pass is folded into the review this change runs on its own epics, as the user's request asks.
- `review`'s **Finishing** keeps "recommend `/cpm-next:plan`" for a finding that reaches the spec; inside a `plan` run, `plan` settles that finding (FR4), so `review` needs no knowledge of who invoked it.
