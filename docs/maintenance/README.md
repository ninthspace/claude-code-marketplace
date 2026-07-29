# CPM Plugin — Maintenance Reference

Development-facing records for the `cpm` plugin: dependencies on external components,
formats CPM writes that something else parses, and coupling between skills that a change to
one of them can break.

**Nothing here is loaded at runtime, and nothing here is referenced from a skill.** That is
the point of the file. A `SKILL.md` is read in full on every invocation of that skill, in
every project the plugin is installed in, so a record aimed at a maintainer is paid for by
every run that will never consult it. This file is the single home for that material, and
`CLAUDE.md` is the only thing that points here — see *A SKILL.md is not a change log* there
for the rule.

**Each record below is a record, not an instruction.** Where a behaviour is recorded here,
its operative counterpart lives in the skill, and the test suites assert the pair. Change
one without the other and the suite fails on the half that moved.

## Contents

- [`cpm:ralph` — ralph-loop state file schema](#cpmralph--ralph-loop-state-file-schema)
- [`cpm:ralph` — `cpm:do` interaction gates](#cpmralph--cpmdo-interaction-gates)
- [`cpm:epics` ↔ `coverage-rollup.sh` — the blocking classes](#cpmepics--coverage-rollupsh--the-blocking-classes)
- [SessionStart hooks ↔ the harness — the hook payload size limit](#sessionstart-hooks--the-harness--the-hook-payload-size-limit)

---

## SessionStart hooks ↔ the harness — the hook payload size limit

Both SessionStart hooks (`cpm/hooks/session-start.sh`, `cpm/hooks/session-start-compact.sh`)
write to stdout, which Claude Code injects into the session context. **Hook output is capped
at 10,000 characters.** Past that, the harness does not trim to the cap — it writes the whole
output to a file under the session's `tool-results/` directory and inlines a ~2 KB preview,
under a notice reading `Output too large (NNKB). Full output saved to: <path>` followed by
`Preview (first 2KB):`.

**This cap is the reason the hooks name files instead of emitting them.**

| What | Value | Status |
|---|---|---|
| Cap on hook stdout | **10,000 characters** | Documented. |
| What happens on breach | Replaced by a **~2 KB preview**, not trimmed to 10 KB | Bug — [anthropics/claude-code#44086](https://github.com/anthropics/claude-code/issues/44086). Closed as inactive, not fixed. |
| The notice | Descriptive (`Full output saved to: …`), not imperative — the model is given a path but not told to read it | Bug — [anthropics/claude-code#55750](https://github.com/anthropics/claude-code/issues/55750), the SessionStart case specifically. Closed as a duplicate of #44086. |

Both issues are **closed without a fix**, so this behaviour should be treated as the status
quo rather than as something about to change.

**There is no escape hatch in the output format.** The cap is on the output *string*, not on
stdout specifically — the hooks reference states it covers `additionalContext`,
`systemMessage` and plain stdout alike, for every hook type and event. Switching these hooks
to the JSON `hookSpecificOutput.additionalContext` form would buy nothing, so do not spend
time on it expecting to.

**How it failed.** Before 2026-07-28 both hooks `cat`-ed `skill-conventions.md` (45,822 bytes)
plus every current-session progress file, and the compact hook added the compact summary.
One real session emitted 86,748 bytes. What reached context was bytes 0–2047: the session id,
the user name, `## Roster Loading`, and 794 of the 1,435 bytes of `## Perspectives`, cut
mid-word. `## Conversational Output` was at byte 28,335, `## Implementation Guidelines` at
37,923, and the compact summary at 55,250. None arrived. No output said so — a session that
had been told it received the shared conventions had received 2.4% of them.

**Why the budget is where it is, and why the margin is thin.** `CPM_PAYLOAD_BUDGET` in
`session-start.sh` is **9,600 characters** against the 10,000 cap, with a measured worst case
of ~9,235. Characters, not bytes: the cap is stated in characters and this output is full of
em dashes at three bytes each, so a byte-denominated budget compared against a
character-denominated cap would be measuring the wrong thing.

That is only ~8% headroom, and it is not comfortable. Over half the payload is the
`CORE_SECTIONS` extract (~5,100 characters for three sections), which is a deliberate
trade — inlining them saves every session a Read call — but it means **adding a section to
`CORE_SECTIONS` is not a free change.** Re-measure before doing it. If the core has to grow,
the cheaper savings have already been taken (the other-session lists are one row per file at
`CPM_LIST_CAP=3`, and the section index is running text rather than a bulleted list), so the
next lever is dropping a section back out of the core.

**What actually defends against the failure, if the cap is breached anyway.** Ordering. The
payload is emitted most-urgent-first — ralph warning, then the session's own state, then the
conventions — so that anything inside the ~2 KB preview still reaches the session. The two
things that can cost a user work are inside it; the conventions extract, which names a file
that is on disk either way, is deliberately not. This is asserted, not merely intended.

**When to update**: if a `Preview (first NKB)` notice ever shows a size other than 2 KB, or
the 10,000-character cap changes, revise the figures here **and** `HARNESS_LIMIT` /
`HARNESS_PREVIEW` in `cpm/hooks/tests/test-session-start-budget.sh`, which is the only other
place those two external constants are written down.

**Operative counterparts** (this record documents them; it does not define them):
`CPM_PAYLOAD_BUDGET` and `CPM_LIST_CAP` in `cpm/hooks/session-start.sh`, `CORE_SECTIONS` in
`cpm/hooks/lib/conventions-core.sh`, and the assertions in
`cpm/hooks/tests/test-session-start-budget.sh` — which pin the payload's independence from
document size, the emission order, and the budget's own relationship to the cap, not merely
the payload's size.

---

## `cpm:ralph` — supported ralph-loop version

**Supported: `ralph-loop@ninthspace-ralph` 1.2.0 or later.** This is a *stated* minimum, not an enforced one — see below for why — and it is written in four places that must agree:

| Site | What it says |
|---|---|
| `README.md` (marketplace root) | Install instruction plus what is lost below it |
| `cpm/README.md` | The same, with the per-change table |
| `cpm/skills/ralph/SKILL.md` step 1c | The supported version, and the warning text naming it |
| here | This record |

`cpm/hooks/tests/test-ralph-supported-version.sh` extracts the version from each and requires one distinct value, so bumping the minimum in one place fails until it is bumped in all of them.

**Why it is not enforced.** A registered Stop hook exposes no version to the skill, and a version is a proxy for the question that actually matters: what the hook *does* on a turn ending in a tool call. A hook can be installed, registered, and still delete the state file at the first iteration boundary. Step 1c therefore runs `cpm/hooks/lib/ralph-hook-probe.sh` against whichever hook is present and branches on its exit code. The version is what a user is told to install; the probe is the gate.

**When to update**: raise the minimum when a fork behaviour that CPM's own documentation describes lands in a new release. As of 1.2.0 there are three — fail-closed extraction (1.1.0), the promise-marker disambiguation (1.2.0), and the honoured `active` field (1.2.0). The last two are recorded in the tables below and in review 02 (OBS-15, OBS-37).

---

## `cpm:ralph` — ralph-loop state file schema


`cpm:ralph` writes `.claude/ralph-loop.local.md` directly instead of invoking the ralph-wiggum plugin's `setup-ralph-loop.sh` script. The stop hook (`stop-hook.sh`) parses this file to drive the loop. The file format is the implicit contract between `cpm:ralph` and the stop hook.

**State file path**: `.claude/ralph-loop.local.md`

**Expected format** (YAML frontmatter + markdown body):

```markdown
---
active: true
iteration: 1
max_iterations: {integer, 0 = unlimited}
completion_promise: "{text}" or null
started_at: "{utc_timestamp from Bash: date -u +\"%Y-%m-%dT%H:%M:%SZ\"}"
session_id: {current session id, unquoted}
---

{prompt text}
```

| Field | Type | Stop Hook Usage |
|---|---|---|
| `active` | boolean | **Plugin-dependent** — see below |
| `iteration` | integer | Compared against `max_iterations`; incremented each loop |
| `max_iterations` | integer | Loop stops when `iteration >= max_iterations` (0 = unlimited) |
| `completion_promise` | string or null | Matched against `<promise>` tags in assistant output |
| `started_at` | ISO 8601 string | Informational; not parsed by stop hook |
| `session_id` | string | Compared against the hook's own session; a mismatch exits without touching the file. Absent or empty reads as legacy and does not gate |

**`active` is the one field whose meaning differs by plugin**, and `cpm:ralph` writes it as `true` on all of them:

| Plugin | Reads `active`? | Effect of `active: false` |
|---|---|---|
| `ralph-loop@ninthspace-ralph` | Yes | Pauses: the session exits and the state file is left byte-for-byte untouched, so restoring `true` resumes at the same iteration |
| `ralph-loop@claude-plugins-official` | No | None — the loop continues to its iteration cap |
| `ralph-wiggum@claude-code-plugins` | No | None — the loop continues to its iteration cap |

Where the field is unread, termination is tested by the state file's *existence* alone. The operative counterpart is in `cpm/skills/ralph/SKILL.md` Step 3c, which instructs the skill to tell the user which behaviour their installed hook has — the failure this guards is a kill switch that silently does nothing.

**Both generated prompts write this field to stop themselves**, which is what makes the row above a contract rather than a note. A loop cannot stop by saying it is stopping: ending a turn is precisely what the Stop hook intercepts, so an instruction to stop that names no action instructs nothing. Both templates therefore define *stop the loop* as setting `active: false` in the state file, leaving the rest byte-for-byte intact so the run can be inspected or resumed. Because the field is unread on two of the three plugins, each definition carries a second clause: if the same prompt arrives again with the same verdict, delete the state file instead — the one termination every plugin in the table honours. If a plugin ever changes which of the two it obeys, both templates change with it, and `test-ralph-promise.sh` and `test-ralph-two-phase-prompt.sh` assert that each *stop the loop* still names a mechanism.

**When to update**: If any ralph plugin changes the state file path, frontmatter field names, or parsing logic in `stop-hook.sh`, this skill's Step 3c must be updated to match. The stop hook uses `sed`, `grep`, and `awk` to parse the frontmatter — any format change that breaks these parsers will break the loop.

## `cpm:ralph` — `cpm:do` interaction gates


This table records how each `cpm:do` gate is handled under an autonomous run. Most are overridden by the prompt's blanket instruction ("choose the most reasonable option for every AskUserQuestion"); three are not, and each says so in its own row — the Stale-Progress Check is suppressed structurally by its guard, while the Retro Check and Change Type Decision gates take an explicit branch in `cpm:do` because for them the blanket instruction picks a wrong answer rather than no answer.

| `cpm:do` Location | Gate Purpose | Prompt Override |
|---|---|---|
| Stale-Progress Check (shared convention, runs at every `/cpm:*` skill startup — including the `/cpm:do` this loop wraps) | Offer cleanup of stale/leftover progress files from other sessions, at most once per session | **Fully suppressed — no prompt, no output, no action.** Suppression is *guard-level*, not prompt-driven: the shared guard (`hooks/lib/cleancheck-guard.sh`) detects the active ralph loop via `.claude/ralph-loop.local.md` and returns `SUPPRESS`, so the check self-silences before any prompt regardless of the prompt's autonomous instruction. No prompt clause is required (and none is added) — the gate cannot stall the loop |
| Input — Epic Doc (multiple epics) | Ask user which epic to work on | Auto-select from the epic list in order |
| Test Runner Discovery | Ask user for test command | Proceed with self-assessment |
| Retro Check — consumption disposition gate | Force a per-run disposition (Applied/Deferred/Not relevant here) on each prior-epic retro observation; durable retirement (the gated in-cycle Obsolete) is a separate deliberately-confirmed action, never auto-taken | **Do not block, do not "choose the most reasonable option".** Branch by category using `cpm:do`'s single-source safe/defer split (its Retro Check → Autonomous mode), not a blanket defer: **auto-apply** safe categories (Codebase discoveries, Patterns worth reusing), recording `**Retro applied**: {nn} · {category} · applied (autonomous, safe-category) — {what it did}` and carrying each into the run as context; **defer** judgement-heavy categories (Scope surprises, Criteria gaps, Complexity underestimates, Testing gaps), recording `**Retro applied**: {nn} · {category} · deferred (autonomous run, unreviewed)`; Smooth deliveries is informational. Surface **both** the auto-applied and deferred lists in the run summary for post-loop human review. **Never auto-retire** — apply or defer only, never the Obsolete retire |
| Termination — Blocker | Confirm external blocker with user | Skip the task and continue to next |
| Termination — Ambiguity | Ask user to clarify unclear criteria | Mark story "Blocked -- criteria ambiguous" and continue |
| Guidelines — Change Type Decision (*Surface change moments explicitly*) | Present a four-option `AskUserQuestion` when a change-worthy situation appears mid-task — a criterion that contradicts reality, a story whose scope is wrong | **Do not block, do not "choose the most reasonable option".** Take `cpm:do`'s autonomous branch (its **Change Type Decision** section → *Autonomous mode*, entered from Guidelines → *Surface change moments explicitly*), which resolves the change moment instead of presenting it: inline edit, retro observation, or amend the epic under execution — never `/cpm:pivot`. Amendment is guarded by a citable contradiction, and leaves a `**Pivot deferred**` breadcrumb for each artefact it could not reach — sometimes none; `cpm:do` holds the rule. Unlike the rows below, the blanket instruction is not merely insufficient here but harmful: one of the four options is Pivot, whose own gates would stall the loop, and the shared matrix's *when in doubt, choose pivot* default makes it the one a blanket "most reasonable option" tends to land on |
| Step 4 — Verification gate test failure | Ask user: fix, continue, or stop | Fix automatically; skip after stuck threshold |
| Step 4 — Verification round limit | 2 fix attempts exhausted; ask user | Mark unmet criteria as known issues and proceed |
| Step 4 — TDD Red phase unexpected pass | Ask user: investigate, skip TDD, or stop | Investigate and fix the test |
| Step 4 — TDD Green phase still failing | Ask user: continue, skip TDD, or stop | Continue working on implementation |
| Step 5 — Unmet acceptance criteria | Ask user: continue working or mark complete | Continue working; skip after stuck threshold |
| Step 5 — Coverage matrix edit failure | Ask user: continue or stop | Continue without recording proof |
| Step 8 — Next epic check | Ask user: continue to next epic or stop | Continue to next epic automatically |
| Step 8 — Completion of the last epic | No `cpm:do` gate; this is the loop's own exit | Run `coverage-rollup.sh --epic {epic_glob} --verdict` and emit `ALL_EPICS_COMPLETE` only on exit 0 — the template carries the operative instruction |
| Graceful Degradation — Test command fails | Ask user: new command, continue, or stop | Continue without tests |
| Graceful Degradation — No test + TDD | Ask user: provide runner or acknowledge | Fall back to standard workflow |

**Stale-Progress Check is guard-suppressed, not prompt-overridden**: unlike the `AskUserQuestion` gates below it, the Stale-Progress Check safety-net (now part of every `/cpm:*` skill's startup) is silenced *structurally* — its shared guard returns `SUPPRESS` whenever `.claude/ralph-loop.local.md` is present. It therefore needs no autonomous instruction in the generated prompt and can never pause the loop; the table row records it so a maintainer adding a gate here knows guard-level suppression is a valid override mechanism, not only the prompt instruction.

**The table records; the template acts.** The stop hook feeds the *template line* back verbatim on every iteration and the loop never reads this table, so an instruction that exists only here documents a behaviour the loop does not have. The completion row's last cell says so on purpose — the row is here because the table is where a reader looks for what the loop does at each decision point, and the loop's own exit is one.

**Retro generation is not a gate**: retro *generation* at `cpm:do` Step 8 writes the retro file automatically (no `AskUserQuestion`), so it runs unchanged under autonomous execution — only the *consumption* gate above needs an override. Generation still fires at epic completion during a Ralph run.

**`cpm:epics` gates are not rows in this table, and that is deliberate.** The table is scoped to the gates of the skill this loop wraps. `cpm:epics` holds its own dispositions in its **Autonomous Mode** section — the single source — and the template carries a one-sentence reference to it rather than a copy. Two copies of a gate table is how a disposition changes in one place and not the other; a reference cannot go stale.

**When to update**: If `cpm:do` adds, removes, or changes an `AskUserQuestion` gate, review the prompt template's Autonomous Behaviour section and this table. A new gate that isn't overridden will cause the Ralph loop to pause and wait for user input — defeating the purpose of autonomous execution.


---

## `cpm:epics` ↔ `coverage-rollup.sh` — the blocking classes

Two components decide, independently, which requirement classes may not be left uncovered:

| Component | Site | What it does |
|---|---|---|
| `cpm:epics` | Step 4, **Cross-epic gap check** | Flags a requirement covered by no coverage matrix as a **GAP** that must be resolved before proceeding |
| `coverage-rollup.sh` | the `(label in deferred) &&` condition | Refuses to let a Scope deferral remove a requirement from the count |

**They must block on the same set — currently must-have and environmental.** If one side
gains a class, the other is wrong until it does too. The two are not derived from each other
at runtime: each names its classes in its own idiom, so the agreement is a convention, not a
mechanism.

`cpm/hooks/tests/test-epics-environmental-gap.sh` asserts the pair, and does it two ways
deliberately. A **correspondence** oracle derives the blocking set from each side and compares
them, so a class renamed consistently in both places stays green. An **inventory** assertion
then pins the set to exactly `must` ∪ `environmental`, because correspondence alone cannot
tell "both sides block on the right classes" from "both sides block on everything".

**When to update**: changing the blocking classes means changing both components *and* the
inventory assertion in that suite. The correspondence oracle will not catch a class added to
both sides at once — that is what the inventory is for.
