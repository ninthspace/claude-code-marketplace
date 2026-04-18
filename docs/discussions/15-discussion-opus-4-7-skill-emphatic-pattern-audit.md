# Discussion: Optimise CPM plugin skills for Claude Opus 4.7 — emphatic-pattern audit

**Date**: 2026-04-17
**Agents**: Bella (Senior Developer)

## Source Material

Anthropic Opus 4.7 announcement — key points relevant to CPM:

- **Literal instruction interpretation**: 4.7 takes instructions literally (vs. 4.5/4.6 which interpreted loosely or skipped parts entirely). Existing prompts may need re-tuning.
- **Self-verification**: model devises ways to verify its own outputs before reporting back.
- **Planning improvements**: catches its own logical faults during the planning phase.
- **Agentic gains**: 14% improvement over 4.6, fewer tool errors, better loop resistance.
- **Tokenizer**: 1.0–1.35× heavier — context budget tighter, so verbose skill files cost more.
- **Effort levels**: new `xhigh` between `high` and `max`; recommends `high`/`xhigh` for coding/agentic work.
- **Memory**: improved file-system-based memory across sessions.

## Bella's Audit

Identified emphatic blocks across CPM skills calibrated for 4.5/4.6 behaviour but unnecessary (and now actively expensive at the new tokenizer rate) for 4.7:

### Patterns stripped

**`cpm/skills/do/SKILL.md`**:

- Line 146 — `> **HARD RULE — PROGRESS FILE UPDATE**` (~100 words of reinforcement) → calm one-line pointer to State Management
- Line 275 — `> **THIS STEP HAS THREE PARTS. ALL THREE ARE MANDATORY...` → "This step has three parts: mark complete, capture an observation, and write the progress file."
- Lines 285-287 — `> **THIS STEP IS MANDATORY FOR VERIFICATION GATES. DO NOT SKIP IT.** ... not optional bookkeeping` → calm 1-sentence rationale
- Line 289 — inline `You MUST record an observation...` → "Record an observation."
- Lines 306-308 — `> **YOU ARE ABOUT TO SKIP THIS. DO NOT SKIP THIS.** ... data loss bug` → calm 1-sentence ordering instruction
- Line 315 — `**Step 6 is not complete until the Write tool call... MUST be the Write call...**` → removed (now covered by Part C's clear instruction)
- Line 403 — `> **KNOWN FAILURE MODE**` block → "Why this matters" 1-sentence framing

**`cpm/skills/quick/SKILL.md`**:

- Line 26 — `> **HARD RULE — PROGRESS FILE UPDATE**` (mirror of do:146) → calm one-line pointer
- Line 320 — `> **KNOWN FAILURE MODE**` (mirror of do:403) → "Why this matters" framing

**`cpm/skills/ralph/SKILL.md`**:

- Line 110 — `**CRITICAL — prompt hygiene rules:**` → `**Prompt hygiene rules** (substantive — the stop hook parses this prompt back):` — substance preserved, shout dropped

### Patterns kept

- Inline `MUST` in flowing prose (e.g. `do:186` "you MUST continue the task loop") — normal English emphasis, fine for 4.7.
- Substantive blockquotes at `epics:79`, `epics:315`, `ralph:220` — transition notes, verification rules, dependency documentation. Not emphatic scaffolding.

### Patterns flagged but NOT touched

The ~60 inline `**Update progress file now**` reminders sprinkled through 14 skill files (per-step prompts with content hints). These are different in character from the emphatic blocks — they encode *what* to capture at each step, not just *that* you should capture. Tightening them is a worthwhile follow-on pass but bigger than the original audit scope.

## Approach Used

- **Pass 1**: Strip duplicate all-caps and KNOWN FAILURE MODE blocks. Mechanically safe.
- **Pass 2**: Restructure so the canonical progress-file rule lives in one place per skill (State Management's "Why this matters" + Create/Update/Delete lifecycle), with one calm reminder at top-of-process.
- Both passes implemented in this session.

## Risks Flagged

- Step 6 scaffolding in `do/SKILL.md` (lines 275–315) was specifically added to defend against 4.6 mid-step truncation. If 4.7 truncates here, the symptom is silent: a story marked complete with no retro and a stale progress file. **Test plan**: run `/cpm:do` on a real epic and verify Step 6 fires all three parts (status update, retro observation, progress file write). User confirmed local testing before publishing.

## Files Changed

- `cpm/skills/do/SKILL.md` — 4 emphatic blocks removed, calm replacements written; State Management section reframed
- `cpm/skills/quick/SKILL.md` — 2 emphatic blocks removed; State Management section reframed
- `cpm/skills/ralph/SKILL.md` — 1 shout-prefix removed, substantive content preserved

## Follow-on Work — Pass 2 (Inline Reminders) — ALSO COMPLETED

After the emphatic-pattern audit, the user said "please continue" and Bella picked up the largest remaining item.

### Pass 2 scope
60+ instances of `**Update progress file now** — write the full \`.cpm-progress-{session_id}.md\` with Step N summary before continuing.` across 13 skill files: architect, archive, brief, discover, epics, library, pivot, present, quick, retro, review, spec.

### Decision rule applied

- **Bare reminders** (no content hint) → DELETED entirely. The State Management section already specifies when and what to write; the inline drumbeat was 4.5/4.6 calibration.
- **Reminders with a content hint** (parenthetical describing what to capture) → COMPRESSED to `*Progress note: capture {hint} in the {Step N} summary.*` — keeping only the informative bit.
- **"Then delete" markers** → COMPRESSED to `*Workflow complete — delete the progress file.*` — preserves the cleanup signal.
- **Cadence overrides** (e.g. architect:111 "after each decision is resolved") → kept as `*Cadence note: ...*` since they override the default per-phase cadence.

### Also caught during Pass 2

- **State tracking lines** in 11 skills (architect, spec, epics, library ×2, brief, archive, retro, discover, review, present, pivot) — same `mandatory ... do not skip it` pattern, tightened for consistency with the do/quick versions.
- **`ralph/SKILL.md:42`** — "**Do not skip this step.**" → "**Ordering**: this step runs after epic discovery and before any other pre-flight checks — autonomous execution depends on it." (substance preserved, shout dropped)
- **`quick/SKILL.md:167`** — "**This is mandatory — do not skip it.**" prefix to "Write the Spec File" → softened to a clear statement that the written spec is a hard gate.

### Total token impact

- Pass 1 (emphatic blocks): ~660 words saved
- Pass 2 (inline reminders): ~1,370 words saved
- Pass 2 (state tracking lines): ~110 words saved
- **Total: ~2,140 words / ~2,800 tokens saved across the plugin**, weighted toward the most-invoked skills (do, quick, epics).

### Verification
Final grep across `cpm/skills/`: no matches for `Update progress file now|HARD RULE|KNOWN FAILURE|MANDATORY|YOU ARE ABOUT TO|do not skip it|This is mandatory — do not skip`.

Line counts: 4996 (start) → 4898 (final) = 98 lines removed. The line count understates the impact because verbose blocks were replaced with single short lines.

## Remaining Follow-on Work (DEFERRED — Plan v1)

Initial three deferred items captured at end of audit session:

1. **TDD sub-loop tightening** (`do/SKILL.md` lines 209–226) — 25 lines of micro-direction for the red-green-refactor loop that 4.7 likely doesn't need at that level of specificity.
2. **`[plan]` tag heuristic review** — 4.7's planning catches logical faults better; some stories currently tagged `[plan]` may no longer need formal plan mode.
3. **`/cpm:ralph` defensive scaffolding review** — 14% better tool use and loop resistance means some defensive scaffolding may be loosenable.

These were saved to `docs/plans/02-plan-opus-4-7-deferred-optimisations.md` for tracking across sessions.

## Plan Revision (2026-04-18) — Plan v2

After Plan v1 was saved, the user surfaced two additional references and asked Bella to review the plan in light of them:

- Anthropic: *Best practices for using Claude Opus 4.7 with Claude Code* — https://claude.com/blog/best-practices-for-using-claude-opus-4-7-with-claude-code
- Smart Ape: *Opus 4.7 is the first model that punishes bad prompting* — https://x.com/the_smart_ape/status/2045070676063649908

### What the references changed

The original plan focused on **what to strip** (continuation of the audit). The references made clear that under 4.7 the bigger lever is **what to add** — explicit precision in stop criteria, fallback rules, negative constraints (must-NOTs), and task budgets. Anthropic: *"the model will not silently generalize instruction from one item to another, and will not infer requests you didn't make."* Smart Ape's framing: imprecision is now directly priced ("the ambiguity tax"), and the cited Suhail Kakar disaster ("68 minutes, millions of tokens burned... 28 files +49474 −724... app completely broken") is the failure mode `/cpm:ralph` is exposed to under 4.7 if its prompt isn't rewritten.

### New URGENT items added to the plan

- **U1**: Rewrite `/cpm:ralph` autonomous prompt — currently has all four anti-patterns (negative instructions, vague stop criteria, no task budget, no fallback). Highest-risk text in the plugin under 4.7.
- **U2**: Explicit stop criteria across every loop (`/cpm:do`, `/cpm:ralph`, facilitation loops in `/cpm:spec`/`/cpm:epics`)
- **U3**: Explicit fallback rules in every Graceful Degradation section (scenario → return value, not scenario → vague action)
- **U4**: Negative-to-positive instruction rewriting across all skills (Anthropic: *"Positive examples of the voice you want work better than negative 'Don't do this' instructions."*)

### New HIGH items added

- **H1**: Acceptance criteria templates need "must NOT" clauses (per Smart Ape's "never falls back to today's date" example)
- **H2**: Effort calibration per skill — document recommended `xhigh`/`high`/`medium` per skill (table included in plan)
- **H3**: Subagent delegation guidance — currently absent; Anthropic provides explicit rule
- **H4**: Tool-grounding language for exploratory skills (`/cpm:discover`, `/cpm:spec`, `/cpm:library`) — 4.7 calls tools less, may need stronger nudge

### Re-prioritisation

Original three items demoted to MEDIUM — they're real but subordinate to the URGENT and HIGH additions. Suggested sequencing: U1 first (don't run ralph against a real codebase under 4.7 until U1 lands), then U2–U4 in parallel, then H1–H4, then M1–M3.

### Cost-risk framing (added to plan)

Under Opus 4.7:

- Vague stop criteria → adaptive thinking burns tokens trying to decide when to stop
- Negative-only instructions → model may take a positive action the user doesn't want
- Missing fallback rules → model guesses, often wrongly
- Vague acceptance criteria → "passing but wrong" implementations
- No task budget → unbounded cost on autonomous loops

The U1–U4 items are the difference between Opus 4.7 being an upgrade and being a regression versus running CPM on a cheaper model.

Full plan: `docs/plans/02-plan-opus-4-7-deferred-optimisations.md`.
