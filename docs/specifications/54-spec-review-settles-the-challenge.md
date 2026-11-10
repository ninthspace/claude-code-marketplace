# Spec: Review settles what plan's challenge decided

**Date**: 2026-11-10  
**Amended**: review 11 (docs/reviews/11-review-challenge-record.md) and the user's decision — every rejection listed under **Needs you**, a confirmed mark that review treats as decided, a reopened fix against a rejection routed to the spec (FR1, FR2, FR4); the roster's `role` and `personality` (FR3); roster `name` values in the reuse form; the superseded mark's own date; how the personas are handed the specs (FR5); where a finding decided at challenge sits in the record (FR4) (2026-11-10)  
**Source**: the user's request (2026-11-10), "Stop review repeating plan's persona challenge"; the user's decisions (2026-11-10): review's personas do not see the **Challenge** section; rejected findings reach the user through `plan`'s **Needs you**, only `Rejected` decisions are settled, a Critical is never settled silently, and review reports what it settled

## Problem Summary

`plan` puts a non-trivial spec through a challenge pass: two or three roster personas, each an Opus subagent, look for what would make the plan fail; `plan` folds in what holds up and records in Assumptions what it chose not to act on (`cpm-next/skills/plan/SKILL.md:45`). It does not record which personas it used, or which findings it acted on and where. `review` then puts three personas on the epics (`cpm-next/skills/review/SKILL.md`, **2. Review independently**), usually the PM and the Developer again, and nothing in **3. Weigh and fix** treats a challenge decision as settled. So review repeats the same perspectives, and a finding plan already decided reaches **Needs you** as new. Since 0.15.0 `plan` runs that review itself, so the repeat happens inside one run, and the review's lead is the agent that made the decision.

## Functional Requirements

### Must Have

- **FR1 — The challenge record.** The contract (`cpm-next/shared/artifacts.md`, the Spec template) defines a `## Challenge` section, placed after `## Assumptions`, written by a challenge pass. Each pass opens with `**Personas**: {name}, … ({YYYY-MM-DD})`, the roster `name` values of the personas used, from the roster `review` would use (the project's `docs/agents/roster.yaml`, else the plugin's). Every other line is a bullet, one per finding after merging duplicates, `- {name}[ / {name}]: {finding} → Folded in: {where}`, `→ Rejected: {why}` or `→ Does not hold: {what the files show}`; a finding partly acted on takes one bullet per part; a pass with no finding has the bullet `- none`. A later pass adds its own `**Personas**:` line and bullets below; the latest bullet on a point governs. A change to a point a bullet decided appends ` — superseded ({YYYY-MM-DD}): {what changed}` to that bullet; the user's confirmation of a `Rejected` bullet appends ` — confirmed by the user ({YYYY-MM-DD})`. A spec with no challenge pass has no section. — AC: the contract's Spec template holds the section, its place, the `**Personas**:` line, the three bullet forms, `- none`, the superseded and confirmed marks; control: `grep -c "## Challenge" cpm-next/shared/artifacts.md` is 0 at the 0.15.0 release commit `[manual]`
- **FR2 — Plan writes it, and the user sees the rejections.** `plan`'s challenge pass writes every finding into the spec's **Challenge** section in the contract's form, using the same roster rule; `plan`'s Assumptions hold its own decisions, not the challenge's. `plan`'s **Needs you** lists every `Rejected` challenge finding, by reference to the section. When the user confirms one, `plan` marks the bullet confirmed; when the user overturns one, or a review finding that reopens one is settled in the same run, `plan` amends the spec and marks the bullet superseded. — AC: `plan/SKILL.md` states each by reference to the contract; control: section 3's challenge sentence no longer names Assumptions as where the challenge's findings go `[manual]`
- **FR3 — Review picks other personas.** `review` step 2 reads the latest `**Personas**:` line of each source spec's **Challenge** section, the union across the scope's specs. Within each required role ("should we build this?", "can we build it like this?"), judged by the roster entry's `role` and `personality`, it picks a persona not in that union that suits the content; when none does, it reuses the best-suited one. Personas added for the content (QA, Test, UX and others) are picked by fit, used before or not. A one-story scope picks the same way for its two personas. The lesson check goes to the Test Engineer or QA when one is picked, else the persona asking "can we build it like this?". The contract's **Reviewers** line gains ` — reused from the challenge: {name}, …` (roster `name` values) when any persona is reused, and the lead compares personas by `name`. — AC: `review/SKILL.md` step 2 and the contract state it; control: the two-role rule and the lesson-check sentence keep their persona names `[manual]`
- **FR4 — Review settles a repeated rejection.** In `review` step 3, after a finding is checked against the files it cites and before only the findings that would change what gets built are kept, one that repeats a `Rejected` challenge decision is **decided at challenge**: it is listed under `## Findings` with its persona's severity and counted in the **Findings** line, and its Remediation entry is `- Decided at challenge: {finding} → {spec path} **Challenge** ({date}): {names}: {recorded finding} → Rejected: {why}`, and it is neither fixed nor in **Needs you**. A bullet the user confirmed is decided at challenge whatever the persona's severity. Otherwise the finding is weighed as any finding, with the entry `- Reopens challenge: {finding} → {recorded decision}; {what was done}` in place of its `Fixed:`, `Needs you:` or `Not acted on:` entry, when its persona tagged it Critical (then left unfixed and listed under **Needs you** quoting the decision); when it cites a criterion, task, code line, ADR, library document or spec amendment that the recorded reason does not address; or when the bullet is superseded. A reopened finding whose fix would act against the recorded rejection reaches back into the spec: it goes to **Needs you** and is settled by `/cpm-next:plan`, which marks the bullet superseded, and is not fixed in the epic. A finding that repeats a `Folded in` or `Does not hold` decision is weighed as any finding, since the repeat suggests the fold-in fell short or the files changed. review's done line counts a finding decided at challenge as handled, and review's **Finishing** gives the number decided at challenge with the record path in one line after **Fixed**. — AC: `review/SKILL.md` step 3, its done line and **Finishing**, and the contract's Review record state it; control: step 3 names all three reopening conditions and the `Folded in` case `[manual]`
- **FR5 — Independence.** `review`'s personas receive the epics, the context step 1 lists, and in place of each source spec a copy without its `## Challenge` section, which the lead writes to its scratch directory and names as standing for the spec at the epic's `**Source spec**` path, telling the persona not to open the original; step 2's sentence that they get none of the conversation or the plan's reasoning stays true. The **Challenge** section is used only by `review`'s lead, in steps 2 and 3. — AC: `review/SKILL.md` step 2 says how the copy is made and handed over and that the persona does not open the original; control: `grep -c "Challenge" cpm-next/skills/review/SKILL.md` is 0 at the 0.15.0 release commit `[manual]`
- **FR6 — Older specs and other sources.** A spec with no **Challenge** section, an epic whose source is not a spec (a `00-` epic or a converted document), and a scope that holds only these, are reviewed as today: personas by the role rule alone, nothing decided at challenge. — AC: `review/SKILL.md` states it `[manual]`

### Should Have

- **FR7 — Docs and release.** The cpm-next README gains `(0.16.0)` bullets under **Additions** and an **Upgrading to 0.16.0** note; the root README, `cpm-next-training-guide.html` (the plan section's challenge pass, which says rejections are noted in Assumptions; the review section's persona choice; the spec and review record templates), `cpm-next-onboarding.html` (the challenge pass and "They get none of the conversation that produced the plan") and `cpm-next-presentation.html` say the same, and the "Independent challenge of the epics" table rows and `review`'s frontmatter description are read and kept or changed; `docs/maintenance/README.md` records that `review` reads the **Challenge** section `plan` writes and the **Reviewers** reuse form, and that `status` reads neither; `cpm-next/shared/fixed.md` gains rows for `cpm-next/skills/review/SKILL.md` **2. Review independently** and **3. Weigh and fix**, Class `decision-relitigated`, fixed in 0.16.0, the slug added to the contract's seed list. Versions: cpm-next 0.16.0, marketplace 4.0.12. — AC: each names it `[manual]`

### Won't Have (this iteration)

- Removing either pass, or changing their models (both stay on Opus).
- A new skill or agent.
- Back-filling **Challenge** sections into earlier specs.
- Settling a repeat of a `Folded in` decision.

## Non-Functional Requirements

- **NFR1**: No added sentence in a SKILL.md or the contract records history (`CLAUDE.md`, "A SKILL.md is not a change log"); the changed passages are grepped for `no longer`, `instead`, `rather than`, `used to`, `previously`, each hit accounted for.
- **NFR2**: `claude plugin validate cpm-next` and `claude plugin validate .` pass, and `claude plugin test` passes for cpm-next, cpm-next-models, cpm-next-progress and whats-next.
- **NFR3**: The **Challenge** format, the `Decided at challenge:` and `Reopens challenge:` forms and the **Reviewers** reuse form are stated once, in the contract; `plan` and `review` refer to them.

## Architecture Decisions

### AD1: The record lives in the spec
The spec is what `review` already reads, so a decision recorded there reaches the review with no new file or path. Rejected: a separate challenge record in `docs/reviews/` (a second artefact for one decision trail), and keeping the rejected findings in Assumptions (they mix with `plan`'s own decisions and carry no persona).

### AD2: Settled in the weighing, hidden from the personas
The personas see the spec without its **Challenge** section and may raise a decided point; `review`'s lead settles it in step 3 (the user's decision, 2026-11-10). That keeps each persona's view whole and independent. Rejected: showing the section to the personas (it steers what they look for and makes the plan's reasoning part of their input).

### AD3: Only an author's rejection, seen by the user, is settled
A rejection is decided by `plan` alone, and inside a `plan` run the review's lead is the same agent; so the rejections go to the user in `plan`'s **Needs you**, only `Rejected` decisions are settled, a Critical is never settled silently, and the review reports how many it settled (the user's decision, 2026-11-10). Rejected: settling repeats of any decision quietly (a real problem the author dismissed would disappear twice).

## Scope

### In Scope
`cpm-next/shared/artifacts.md` (Spec template, Review record's **Reviewers** and Remediation, the seed list); `cpm-next/skills/plan/SKILL.md` (section 3's challenge pass, **Finishing**'s **Needs you** and amendments); `cpm-next/skills/review/SKILL.md` (done line, steps 1 to 3, **Finishing**); the docs, `fixed.md` and versions in FR7.

### Out of Scope
`do`, the auditor, `status`, the mods.

## Testing Strategy

Prose changes are checked by reading each changed passage against its requirement, with `grep` for the required strings and for every place that restates a format, each hit accounted for (`[manual]`); `claude plugin validate` and `claude plugin test` for NFR2. This spec carries its own **Challenge** section in the new form, so the review of its epics, run by `plan` in this run, is the first real use: its record should show reviewers other than `architect` and `qa`, and any finding decided at challenge quoting a bullet below.

## Assumptions

- "Repeats a recorded decision" is the review lead's judgment, made by reading the finding beside the bullet after checking the finding's citations; the entry quotes the decision, and the count in review's **Finishing** points the user to it.
- The plugin roster has two personas for each required role (`pm` and `sm`; `dev` and `architect`), so a challenge that used both of one role leaves review reusing one, which FR3 allows and the **Reviewers** line shows.
- Spec parsers read header fields at the start of any line (`whats-next/hooks/plan.ts:201,204` matches `**Status**:`, `**Withdrawn**:` and `**Superseded by**:` with a line-start anchor); the section's only field line is `**Personas**:`, and every other line is a bullet.

## Challenge

**Personas**: architect, qa (2026-11-10)

- architect / qa: showing the section to the personas contradicts AD2 and the "none of the plan's reasoning" sentence, and FR5's check passed on unchanged text → Folded in: FR5 (section removed from the personas' input), AD2, FR5's control
- architect / qa: "a finding of this review about the epic" made every finding reopen a decision, since every finding cites a story → Folded in: FR4's reopening conditions name what the recorded reason does not address
- architect / qa: "evidence newer than the challenge's date" cannot fire in a same-day run and misses code the challenge never read → Folded in: FR4 (citation-based, not date-based)
- architect / qa: review's done line requires every Critical and Warning fixed or in **Needs you**, which a settled finding is neither; settled findings had no place under Findings → Folded in: FR4 (listed, counted, done line)
- architect / qa: rejected findings would never reach the user, and inside a `plan` run the settler is the author → Folded in: FR2 (**Needs you**), AD3, FR4 (no Critical settled silently, the count in **Finishing**)
- architect / qa: an amendment after the challenge, or a user's overturn, left a stale bullet; a second pass was undefined → Folded in: FR1 (superseded mark, the latest bullet governs), FR2
- qa: a repeat of a `Folded in` decision suggests the fold-in fell short → Folded in: FR4, Won't Have
- architect / qa: the persona rule traded fit for novelty, roles were undefined, the lesson check could move, scopes across specs were unclear, a one-story review defaulted to the Scrum Master → Folded in: FR3
- architect / qa: the **Reviewers** reuse note and both Remediation forms had no contract form; `Settled` already means a user's decision in review 10; the entry quoted the finding, not the decision → Folded in: FR3, FR4, NFR3 (`Decided at challenge:`, `Reopens challenge:`)
- qa: persona identity was ambiguous (display name or `name`) and the roster unnamed → Folded in: FR1
- architect / qa: an empty pass, partial fold-ins, merged findings and unfounded findings had no form, and every finding could bloat the spec → Folded in: FR1 (`- none`, one bullet per part, merged names, `Does not hold`)
- architect / qa: a fixed.md row with Class `any` at step 3 covers unrelated step-3 failures and misses step 2 → Folded in: FR7 (Class `decision-relitigated` at steps 2 and 3)
- qa: several criteria were met by today's text or had no control → Folded in: FR1, FR2, FR3, FR4, FR5 controls
- architect / qa: the Testing Strategy never observes the behaviour → Folded in: this section, and the Testing Strategy's reading of this spec's review
- qa: the docs list missed the training guide's Assumptions sentence, onboarding's "none of the conversation" line, the table rows and review's description → Folded in: FR7
- architect: the parser assumption was loose → Folded in: Assumptions
- architect: placement of the section was unstated → Folded in: FR1
- architect: the title and file name differed → Folded in: the title
- architect: `Rejected` here and `Not acted on` in review's Remediation are two words for one outcome → Rejected: they belong to different records with different authors (the challenge's lead and the review's), and the review record keeps its forms
- qa / architect: NFR1's history risk in FR2's control wording → Folded in: NFR1's grep list
