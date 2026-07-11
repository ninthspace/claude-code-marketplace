# Plan: Opus 4.7 Deferred Optimisations

**Date**: 2026-04-17 (created), 2026-04-18 (revised)
**Status**: Pending — local testing of completed Pass 1 + Pass 2 in flight; revised priority list below
**Source**: `docs/discussions/15-discussion-opus-4-7-skill-emphatic-pattern-audit.md`
**Additional references**:

- Anthropic: *Best practices for using Claude Opus 4.7 with Claude Code* — https://claude.com/blog/best-practices-for-using-claude-opus-4-7-with-claude-code
- Smart Ape: *Opus 4.7 is the first model that punishes bad prompting* — https://x.com/the_smart_ape/status/2045070676063649908

## Context

Anthropic released Claude Opus 4.7 with several behavioural shifts relevant to the CPM plugin:

- **Literal instruction following** — the model "will not silently generalize instruction from one item to another, and will not infer requests you didn't make" (Anthropic)
- **Self-verification** — devises ways to verify its own outputs before reporting back
- **Improved planning** — catches its own logical faults during the planning phase
- **14% better tool use**, fewer tool errors, better loop resistance — but **calls tools less often and reasons more**
- **Tokenizer 1.0–1.35× heavier** — verbose skill files cost more
- **More judicious about subagents** — tends to delegate less unless explicitly told when to delegate
- **Default effort raised to `xhigh` in Claude Code** across all plans
- **Adaptive thinking only** — no fixed budgets; the model decides how long to think; **ambiguous prompts make it overthink** (Smart Ape: "the ambiguity tax")
- **Sampling parameters removed from API** — `temperature`/`top_p`/`top_k` now error on Opus 4.7

The bottom line: **prompt imprecision is now directly priced in dollars and quality**. The Kakar example linked in the Smart Ape thread — "68 minutes, millions of tokens burned... 28 files +49474 −724... app completely broken" — is exactly the failure mode `/cpm:ralph` is exposed to under 4.7 if its prompt isn't rewritten.

## What Was Already Done (Pass 1 + Pass 2)

See `docs/discussions/15-discussion-opus-4-7-skill-emphatic-pattern-audit.md` for the full audit. Summary:

- **Pass 1** — Stripped emphatic blocks (HARD RULE / KNOWN FAILURE MODE / all-caps) from `do/SKILL.md`, `quick/SKILL.md`, `ralph/SKILL.md`. State Management sections reframed.
- **Pass 2** — 60+ inline `**Update progress file now**` reminders deleted or compressed across 12 skill files; 11 State tracking lines tightened; remaining "Do not skip" / "This is mandatory" prefixes softened.
- **Net impact**: ~2,800 tokens saved per invocation.
- **Verification**: Final grep confirms no emphatic patterns or verbose reminders remain.

These passes addressed the *cost* of redundant scaffolding. They did **not** address the *risk* of imprecise instructions, which is the larger problem under 4.7.

## URGENT Items — Direct Cost / Quality Risk Under 4.7

These four items are the difference between 4.7 being an upgrade and 4.7 being a money fire. They should be done **before** local testing of the Pass 1 + Pass 2 changes goes any further, because some of them will affect what "good behaviour" looks like in those tests.

### U1. Rewrite the `/cpm:ralph` autonomous prompt

**Current state** — `ralph/SKILL.md:107` produces a ~500-char prompt that is fed verbatim to the autonomous loop on every iteration:

> Run /cpm:do. Work through epics {epic_range} sequentially ({epic_glob}). When an epic completes and offers the next epic choice, always continue to the next epic. Only work on the specified epics -- do not scan for or continue to other epics beyond this list. Do NOT use AskUserQuestion -- make autonomous decisions: fix test failures yourself, use inline planning instead of formal plan mode, keep working until acceptance criteria pass, skip a task after 3 consecutive failures. Commit after each completed story but NEVER push to remote.{story_filter_clause}{test_runner_clause}{resume_clause} When the last specified epic completes, output ALL_EPICS_COMPLETE.

**Anti-patterns it contains**, all flagged by the references:

- Negative instructions: "Do NOT use AskUserQuestion", "NEVER push to remote", "do not scan for or continue to other epics"
- Vague stop criteria: "keep working until acceptance criteria pass" — what counts as "pass" when criteria don't have a runnable check?
- No task budget — under 4.7's adaptive thinking, this is uncapped cost
- No fallback rules — "fix test failures yourself" doesn't say what to do if a fix isn't viable
- "skip a task after 3 consecutive failures" — what counts as a "failure"? Test red? Tool error? Self-assessed dead-end?

**Why deferred to URGENT priority**: this is the direct exposure surface between 4.7 and a real codebase, running unattended. Get it wrong and the user's wallet pays.

**How to rewrite** — restructure into positive instructions with explicit criteria:

1. **Positive task framing** instead of "Do NOT use AskUserQuestion": *"Make autonomous decisions for every choice point. When `/cpm:do` would normally ask the user, pick the option labelled in the autonomous-defaults section below."*
2. **Explicit stop criteria per task**: not "keep working until acceptance criteria pass" but *"a task is complete when (a) all `[unit]`/`[integration]`/`[feature]` tagged criteria have a passing test result from the cached test runner, AND (b) all `[manual]` criteria have a self-assessment line in the progress file."*
3. **Explicit failure rules**: *"a 'failure' for the 3-strike skip rule is: a test command exit code ≠ 0 after a code change attempt. A tool error or permission denial is not a failure — retry once after 30s, then surface to the progress file as a blocker."*
4. **Task budget**: include `task_budget` advisory based on the story size (count of tasks × estimated tokens per task). Smart Ape's heuristic: 2–3× the tokens a competent engineer would need.
5. **Fallback for ambiguous criteria**: *"if a story's acceptance criteria don't allow you to determine completion, mark the story 'Blocked — criteria ambiguous' and continue to the next story. Do not guess what the criteria meant."*
6. **Length**: prompt may exceed 500 chars after this rewrite. The old "under 500 characters where possible" guideline at `ralph:115` was for 4.6's input handling, not a hard requirement. Keep it tight but don't sacrifice clarity for length.

**Decision criteria**: the rewritten prompt must answer all five Smart Ape migration questions in the affirmative: explicit intent, success criteria, constraints, task budget + stop criteria, no negative-only instructions.

### U2. Add explicit stop criteria across every loop

**Loops in CPM that need stop criteria audited**:

- `/cpm:do` Per-Task Workflow loop — `do:317` "If none exist (and hydration found no unblocked stories), the work loop is done" — what is "done" when stories are blocked on external dependencies? Define explicitly.
- `/cpm:do` epic-batch loop — `do:370` decision tree for "Continue to next epic" / "Stop here" — already explicit, good.
- `/cpm:ralph` — covered by U1.
- `/cpm:spec`/`/cpm:epics` facilitation loops — multiple "refine with the user" steps that have no explicit termination signal. Currently rely on the user pressing through. Under 4.7 the model may now stall waiting for "perfect" facilitation.
- `/cpm:consult`/`/cpm:party` — already have explicit "wrap up" trigger word, good.
- `/cpm:do` Step 4 verification gate — *"if any criteria are not met, flag them to the user"* — needs explicit language about how many AskUserQuestion rounds before treating as a blocker.

**How to fix**: each loop spec should include a section titled "Termination" that lists:

- (a) The success exit condition (positive)
- (b) The blocker exit condition (positive: "exit with a blocker note when X")
- (c) The ambiguity exit condition (positive: "if criteria can't be evaluated, exit with a 'criteria ambiguous' note and continue")

**Why deferred to URGENT**: facilitation loops without termination criteria are how `/cpm:spec` sessions become 90-minute model burns under 4.7's adaptive thinking. The model overthinks waiting for "good enough."

### U3. Add explicit fallback rules to Graceful Degradation sections

**Affected files** (those with Graceful Degradation sections):

- `cpm/skills/do/SKILL.md` (lines 376–387)
- `cpm/skills/pivot/SKILL.md` (lines 178–187)
- `cpm/skills/library/SKILL.md` (graceful degradation notes scattered)
- `cpm/skills/architect/SKILL.md` ADR-not-found scenarios

**Current shape**: scenario → vague action ("fall back to standard workflow", "skip silently", "don't block").

**Required shape under 4.7**: scenario → explicit return value or action.

**Example rewrite** (`do:386` "No test command + `[tdd]` story"):

- Before: *"Fall back to the standard post-implementation workflow for this story and warn the user"*
- After: *"For each task in this story, treat it as a non-TDD task: implement first, then call AskUserQuestion with options 'Continue without tests', 'Provide a test command', or 'Skip this story'. If the user picks 'Continue without tests', append `[manual-only]` to the story heading in the epic doc and proceed. Do not silently degrade — every TDD-tagged story without a runner produces a visible artefact."*

**Why deferred to URGENT**: the Smart Ape's "if you can't find x, return y, don't guess" rule. Under 4.7 the model will literally do whatever the fallback says; vague fallbacks produce vague behaviour.

### U4. Rewrite negative instructions as positive guidance

**Why deferred to URGENT**: Anthropic guidance is direct: *"Positive examples of the voice you want work better than negative 'Don't do this' instructions."* CPM has dozens of these and Pass 1/Pass 2 only addressed the *emphatic* negatives, not all negatives.

**Audit pattern**: grep for `Don't|Do not|Never|Avoid` across `cpm/skills/`. Triage each:

- **Behaviour-shaping** ("Don't decompose for the sake of it") → rewrite as positive ("Decompose only when separate concerns can be tested independently")
- **Hard constraint** ("Never use Write — Edit preserves existing content") → keep but reframe as positive guarantee ("Use Edit so the existing content is preserved")
- **Path-of-least-resistance hint** ("don't over-explain between tasks") → rewrite as the desired behaviour ("move to the next task immediately after the current one completes")

**Decision criteria**: every "Don't / Never / Avoid" should have a positive form that's at least as clear. Where the positive form would be vague, leave the negative — but mark it as load-bearing in the don't-strip list below.

## HIGH Priority Items — Quality Optimisation

### H1. Acceptance criteria templates: add "must NOT" clauses

**Context**: `cpm:spec` and `cpm:epics` already have a "Testability standard" (`epics:120`) that flags vague positive criteria. They do not generate **negative criteria** — what the implementation must *not* do.

**Why this matters under 4.7**: Smart Ape's coding example: *"write a python function using dateutil that parses iso 8601 and us date formats, raises valueerror on ambiguous input, **never falls back to today's date**."* The negative clause prevents an entire class of "passing but wrong" implementations. Under 4.7's literal interpretation, leaving negatives unspecified means the model is allowed to choose any non-prohibited behaviour — including ones the user would reject if asked.

**How to apply**:

- Update `cpm:spec` Section 6b (tag acceptance criteria) to ask: *"Are there behaviours this criterion explicitly allows that you would reject? Capture those as `must NOT` lines paired with the positive criterion."*
- Update `cpm:epics` Step 3 to surface "must NOT" clauses from the spec when present, and propose them when absent on stories that touch security, data integrity, or external systems.
- Format: criteria appear as paired lines:
  - `- User receives a session token within 200ms of valid OAuth callback [integration]`
  - `- Implementation must NOT cache the token in browser localStorage [integration]`

**Decision criteria**: a story is ready for `/cpm:do` when every must-have criterion has either an obvious negative space (e.g. UI rendering) or an explicit `must NOT` pair.

### H2. Effort calibration per skill — document expected `effort` per skill

**Context**: Claude Code now defaults to `xhigh` across all plans. Anthropic recommends `xhigh` for "most coding and agentic uses" but explicitly allows `high`/`medium`/`low` for "cost-sensitive, latency-sensitive, or tightly scoped work."

**Why this matters**: running mechanical CPM skills (status, templates, archive, the entire library backfill workflow) at `xhigh` burns money for no quality gain. Running reasoning-heavy skills (do, epics, spec, architect) below `xhigh` will produce noticeably worse output under 4.7.

**Proposal** — add a `**Recommended effort**:` field to each SKILL.md frontmatter or top-of-file section:

| Skill | Recommended effort | Rationale |
|-------|-------------------|-----------|
| do | xhigh | Reasoning-heavy execution loop, multi-step verification |
| epics | xhigh | Decomposition, fidelity, coverage matrix |
| spec | xhigh | Requirements synthesis, architecture decisions |
| architect | xhigh | Trade-off exploration, ADR generation |
| ralph | xhigh | Autonomous execution; cost-vs-quality leans quality |
| consult, party | xhigh | Multi-perspective reasoning |
| review | xhigh | Adversarial critique, dimension matching |
| brief, discover | high | Facilitation with light reasoning |
| pivot | high | Surgical edits with light cascade reasoning |
| quick | high | Lightweight by design |
| retro, present | medium | Mostly synthesis from existing artefacts |
| status, templates, archive, library (mechanical paths) | medium | Mechanical scans and file ops |

**Output**: a single table in `cpm/shared/skill-conventions.md` under a new "Effort Recommendations" section. Users adjust their Claude Code config based on the table.

**Why deferred (not URGENT)**: this is a documentation change, not a behaviour change. Won't fix bad output, but will reduce cost waste.

### H3. Subagent delegation guidance

**Context**: Anthropic explicit guidance: *"Do not spawn a subagent for work you can complete directly in a single response (e.g., refactoring a function you can already see). Spawn multiple subagents in the same turn when fanning out across items or reading multiple files."*

**Where CPM uses subagents currently**:

- `cpm/skills/do/SKILL.md` Step 5b — `laravel-simplifier:laravel-simplifier` agent for Laravel projects
- `cpm/skills/review/SKILL.md` — agent personas for adversarial review (in-character, not actual subagents)

**Where CPM probably *should* be using subagents but doesn't**:

- `cpm:spec` Section 4 (Architecture Decisions) — could fan out to architecture specialist agents
- `cpm:epics` Step 3 (Break into Stories) — could fan out per-epic to parallelise breakdown
- `cpm:discover` Phase 3 (Current State exploration) — could spawn explore agents per area

**Proposal**: add a section to the shared conventions document explaining when to delegate. Reference the Anthropic rule. Then audit each skill for fan-out opportunities and add explicit `Task` tool invocations where they apply.

**Why deferred**: needs design work per skill, not just a global rule. Worth doing after the URGENT items so the test surface is more stable.

### H4. Tool use frequency for exploratory skills

**Context**: Anthropic: *"the model calls tools less often and reasons more."* For skills whose value depends on grounding in real codebase state — `cpm:spec`, `cpm:discover`, `cpm:library`, `cpm:status` — fewer tool calls means more guessing.

**Affected skill sections**:

- `cpm/skills/discover/SKILL.md:75` *"If there's an existing codebase to explore, use Read, Glob, and Grep to understand the current state before asking questions."* — this is already explicit, but may need stronger language under 4.7.
- `cpm/skills/spec/SKILL.md:106` *"If there's an existing codebase, explore it first..."* — same.
- `cpm/skills/architect/SKILL.md` — implicit codebase exploration, no explicit tool guidance.

**Proposal**: add a positive "Codebase grounding" section to skills that depend on it: *"Before answering each question to the user, run Read/Glob/Grep against the current codebase to ground your suggestions in what actually exists. Reasoning without grounding produces plausible-sounding but wrong recommendations under Opus 4.7."*

**Why deferred**: documentation change, not behaviour change. Pairs naturally with H3.

## MEDIUM Priority Items (the original three)

These were the deferred items from the original plan, before the new references were factored in. They're still valid but less urgent than U1–U4 and H1.

### M1. TDD sub-loop tightening — `do/SKILL.md` lines 209–226

**What**: 25 lines of explicit micro-direction for red-green-refactor.

**Why now MEDIUM, not low**: 4.7's improved planning and self-verification probably handle TDD discipline with terser instructions, but TDD is high-stakes — getting it wrong means tests don't actually drive design. The "more literal instruction following" change cuts both ways here: explicit phase numbering may help 4.7 stay on track, OR may be over-direction it doesn't need.

**How to assess** (unchanged from original plan): run `/cpm:do` on an epic with `[tdd]` stories, observe whether each phase fires correctly. Decision criteria: if 4.7 reliably runs all three phases without skipping, compress to 1–2 sentences per phase. If it skips, *expand* (4.7 needs more direction, not less).

### M2. `[plan]` tag heuristic review — `epics/SKILL.md` lines 137–143

(Unchanged from original plan — see prior version of this document for full text. Still relevant; not affected by the new references.)

### M3. `/cpm:ralph` defensive scaffolding review

(Unchanged from original plan — but note this is now subordinate to U1 above. Do U1 first; M3 may be partly absorbed into the U1 rewrite.)

## Don't-Strip List (preserved from original plan)

These were considered during the audit and explicitly preserved — re-stripping them would change behaviour:

- `cpm/skills/do/SKILL.md` — `**Note**` blockquote on plan-mode loop continuation (~line 184)
- `cpm/skills/do/SKILL.md` — "core TDD discipline — do not skip or compress these phases" (line 207) — note: this is a **negative instruction** that should be candidate for U4 rewriting in positive form
- `cpm/skills/epics/SKILL.md` — `**Transition note**` on epic numbering shape coexistence (~line 79)
- `cpm/skills/epics/SKILL.md` — `**Verification rule**` blockquote on coverage matrix (~line 315)
- `cpm/skills/ralph/SKILL.md` — `**Prompt hygiene rules** (substantive — the stop hook parses this prompt back)` block — substance is load-bearing for the stop hook contract
- `cpm/skills/ralph/SKILL.md` — `**This section documents dependencies between cpm:ralph and external components.**` blockquote (~line 220)
- `cpm/skills/review/SKILL.md` — `**Never use Write** — Edit preserves the existing content.` (line 308) — substantive content-preservation rule, but candidate for U4 rewriting in positive form

## Suggested Sequencing

1. **First, before any further local testing**: Do **U1 (ralph prompt rewrite)**. The Kakar disaster mode is real and immediate. Until U1 lands, don't run `/cpm:ralph` against a real codebase under 4.7.
2. **Next**: U2 (stop criteria), U3 (fallback rules), U4 (negative-to-positive rewrite). These can be done in parallel — they touch overlapping files but the changes don't conflict.
3. **Then**: H1 (must-NOT clauses), H2 (effort calibration), H4 (tool grounding). These improve quality across the plugin without behavioural risk.
4. **Then**: H3 (subagent delegation). Needs design work per skill; do after the rest of the changes have settled.
5. **Last**: M1, M2, M3 (the original three deferred items). These are quality optimisations; address after observing 4.7 in the wild against the URGENT/HIGH-fixed plugin.

## Key Cost-Risk Statement

Under Opus 4.6, vague CPM skills produced acceptable output because the model interpreted intent. Under Opus 4.7:

- Vague stop criteria → adaptive thinking burns tokens trying to decide when to stop
- Negative-only instructions → model may take a positive action the user doesn't want
- Missing fallback rules → model guesses, often wrongly
- Vague acceptance criteria → "passing but wrong" implementations
- No task budget → unbounded cost on autonomous loops

The **U1–U4 items above are the difference between Opus 4.7 being a quality + cost upgrade and being a quality + cost regression** versus running the same skills on a cheaper model. The Smart Ape's framing applies directly to CPM: *"the ones who adapt win on both quality and cost. the ones who don't will blame the model. it's not the model. it's you."*
