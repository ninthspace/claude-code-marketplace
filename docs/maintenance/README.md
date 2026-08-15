# Plugin Maintenance Reference

Development-facing records for the plugins in this repository — `cpm` and, since Epic 47-05,
`dpm`: dependencies on external components, formats one component writes that another parses,
and coupling between parts that a change to one of them can break.

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
- [`dpm` — FTS5 trigger names the dumper reads](#dpm--fts5-trigger-names-the-dumper-reads)
- [`dpm` — the retirement abort message the tool layer parses](#dpm--the-retirement-abort-message-the-tool-layer-parses)
- [`dpm` ↔ the harness — the MCP tool name prefix](#dpm--the-harness--the-mcp-tool-name-prefix)
- [`dpm:status` ↔ `dpm/tools/board` — the status-model reconciliation record](#dpmstatus--dpmtoolsboard--the-status-model-reconciliation-record)

---

## `dpm` ↔ the harness — the MCP tool name prefix

**The record.** A tool from a **plugin-bundled** MCP server is callable as
`mcp__plugin_<plugin-name>_<server-name>__<tool-name>`, with any character outside `A-Z`, `a-z`,
`0-9`, `_` and `-` replaced by `_`. For dpm — plugin `dpm`, server key `dpm` — that is
**`mcp__plugin_dpm_dpm__create_spec`**. The rule is the harness's, documented at
[Plugin-provided MCP servers](https://code.claude.com/docs/en/mcp#plugin-provided-mcp-servers),
and it is not the same as the `mcp__<server>__<tool>` form used by a server registered directly
with `claude mcp add`. The server also registers under the scoped name `plugin:dpm:dpm`, which is
what an `mcp_tool` hook's `server` field would take.

**Why it needs a record.** Nothing in this repository can check it. Every test that drives the
server spawns `bin/dpm-mcp.js` by path, so the suite supplies its own launch and never meets a
name the harness constructed — the same blind spot FR29's first half exists to name, applied to
FR29's second half. The corpus shipped `mcp__dpm__` in 456 places across the whole of M4 and every
suite was green, because the only oracle was a constant the corpus was read with.

**What can break it.** Renaming the plugin in `dpm/.claude-plugin/plugin.json`, or renaming the
`mcpServers` key, changes 171 tool names in one edit. Adding a second server makes the prefix
ambiguous, which is why `CALLABLE` refuses more than one rather than picking. A harness change to
the naming rule breaks every skill at once and no test in this repository would fail.

**What asserts it.** `CALLABLE` in `dpm/tests/support/skills.js` **derives** the prefix from the
manifest's `name` and its single `mcpServers` key rather than transcribing it, and every skill
sweep reads the corpus through it — so a skill left on an old prefix contributes no tool names and
fails `reachability.test.js`'s "names no tool at all". `reachability.test.js` pins the literal
`mcp__plugin_dpm_dpm__` against that derivation, the two sides differing in kind so the equality
is a claim rather than a tautology. `plugin.json`'s name and server key are asserted there too.
The literal is the transcription of an external rule, and this record is where the rule's source
is written down.

---

## `dpm` — FTS5 trigger names the dumper reads

**The record.** dpm's search indexes are maintained by triggers named for the index they
maintain: `document_fts_insert`, `document_fts_update`, `document_fts_delete`
(`dpm/src/schema/012-search.sql`), and the same pattern for `entry_fts`. **The dump filter in
`dpm/src/dump/objects.js` depends on that naming, and on those objects being triggers rather
than tables.**

SQLite creates an FTS5 index's storage as tables named `<index>_data`, `<index>_idx`,
`<index>_content`, `<index>_docsize` and `<index>_config`. A dump must exclude them — they are
the internal representation of a derived index, and committing them commits an unreadable second
copy of every indexed body. `isShadowOf` therefore excludes anything whose name starts with
`<index>_` — **scoped to `type = 'table'`**, because the project's own triggers match that same
prefix. Drop the type scope and the filter strips exactly the three triggers that rebuild the
index from the data; a restored database then holds every row, an empty index, and reports no
error. That is false-pass register entry #3 arriving out of the filter written to prevent #9.

**What can break it.** Renaming a trigger so it no longer carries the index prefix does no harm.
Naming a *real table* with the index prefix — `document_fts_notes` — silently excludes it and
loses its rows. Removing the `type === 'table'` condition breaks restore silently.

**What asserts it.** `dpm/tests/search-index.test.js` asserts the three trigger names;
`dpm/tests/dump.test.js` asserts the five shadow tables are excluded *by name and with a reason*
and that the virtual table and its triggers are kept; `dpm/tests/round-trip.test.js` asserts the
index is rebuilt from the data rather than carried. A real table caught by the prefix would fail
the no-silent-omission assertion, which names exactly what was dropped.

---

## `dpm` — the retirement abort message the tool layer parses

**The record.** `dpm/src/schema/retirement.js` generates one trigger per vocabulary reference, and
each raises exactly:

```
retired: <table>.<column>[, <table>.<column>…] references a retired <parent> row
```

**`dpm/src/tools/crud.js` parses that sentence** — for two things. It matches the shape to decide
the failure is a caller's and not the server's, and it lifts the qualified column names out so the
refusal can name the *value* the caller passed alongside the column the trigger blamed.

**Why the parsing exists at all.** `RAISE(ABORT, …)` takes a string literal; SQLite gives a trigger
no way to interpolate `NEW.<column>` into its own message. So the trigger can say which reference
was refused and can never say which item. The values are only in scope at the tool boundary, which
is where the naming is completed.

**What can break it.** Rewording the abort — including changing `retired:` to anything else, or the
`references a retired <parent> row` tail — silently costs both halves. The failure is not a wrong
message: a message the shape no longer matches falls through the translation entirely and reaches
the caller as a bare `Error` with `ERR_SQLITE_ERROR` and no `rpc` code, which the MCP boundary
renders as **Internal error**. The row is still correctly refused. The caller is told dpm broke.
That was the live behaviour until Epic 47-05 Story 6, because the translation matched only on
`constraint|FOREIGN KEY|UNIQUE|CHECK` and the abort contains none of those words.

Changing the qualified-column format — `<table>.<column>` — costs only the item naming, and does so
silently, since the enrichment degrades to an empty string rather than failing.

**What asserts it.** `dpm/tests/parity-integration.test.js`, over all four vocabularies: that the
error is a `ToolError` carrying `rpc.code === -32602` — **not** merely that a refusal happened,
which `assert.throws` satisfies against the broken state — and that its message contains the
retired item in quotes. `dpm/tests/vocabulary-tools.test.js` asserts the guards fire.

---

## `dpm:status` ↔ `dpm/tools/board` — the status-model reconciliation record

**The record.** `dpm/shared/status-model.md` is the single definition of how a dpm project's
planning state is derived (AD5), and it has two consumers: `dpm/skills/status/SKILL.md`, which
references it in prose, and `dpm/tools/board`, which implements it in code. Against the board the
reconciliation is automated in both directions — `dpm/tools/board/tests/test_contract.py`
reconciles the contract's rule names against the board's `DERIVATIONS` registry. **Against the
skill it cannot be**: the skill is prose, and no parse tells a passage that agrees with a rule from
one that never met it. This table is that second reconciliation. Every rule the contract states
carries a disposition here, and a rule with none fails a test.

| Contract rule | Disposition | What happened |
|---|---|---|
| readiness | amended in the skill | The skill's recommendation table offered `/dpm:do` without asking dpm's `ready` filter, so an epic held by a blocker was recommended as workable. The table gained a row for the epics `ready` returns and a row for held ones, and the skill gained *Readiness is asked for, not inferred from the stories*. It still does not restate `readyClause`, which is what the contract asks of both consumers. |
| blocking | amended in the skill, with a bounded omission | The same paragraph now names `list_dependency` as what identifies the blocker. **`gates_work` and `include_retired` were deliberately left out.** The skill never derives the held state — it asks `ready`, and the server has already applied the gating set — so the kinds would serve only to choose *which* edge to name. A project with a non-gating kind can therefore have the skill name an edge that holds nothing; that is a known limit, not a contradiction, and closing it means adding a `list_dependency_kind` call to Phase 1's inventory, which is a change beyond "amend where it contradicts". |
| retired blockers | conformed by delegation | The skill says nothing about a blocker whose status is `superseded` or `withdrawn`, and needs to: because it asks `ready` rather than deriving it, `readyClause`'s `blocker.status <> 'complete'` applies before the rows reach it. Recorded rather than amended — the conformance is real but invisible, and the readiness paragraph added above is what makes the delegation legible to a reader who would otherwise add the rule by hand. |
| in progress | deliberately left alone | The contract's derived value and its precedence order (`complete` → retired → `blocked` → in progress → `ready`/`pending`) are how the *board* renders an epic in a column. The skill prints a fraction and a narrative, never a state word per epic, so there is no passage for the precedence to contradict. The one place the two could disagree — an epic whose only incomplete stories are retired — the skill already handled correctly, and the board was changed to agree with it. |
| progress counts | conformed; the board was amended to match | The skill was right and the board was wrong. *Retired stories leave the count rather than joining either side of it*, and *say how many were retired alongside the fraction*, were already in Phase 1; the board counted a `withdrawn` story in the denominator forever. The board's `progress()` now excludes retired stories and carries the count, and the contract states the rule. The skill's Phase 1 `more` paragraph likewise sent the truncated-read rule into the contract and paging into the board. The skill prints no project-wide fraction, so the averaging trap the contract names cannot arise in it and no wording was added for it. |
| untraced requirements | conformed; the two shapes differ deliberately | The skill was already deriving this rule before the contract stated it — Phase 3b's **Untraced**, "no coverage rows at all", named as the load-bearing measurement and reported before the counts. Nothing in it contradicts the rule and nothing was amended. What is worth recording is the shape: `dpm:status` scopes `list_coverage` by `requirement_id` and asks once per requirement, over one spec; the board reads `list_requirement` and `list_coverage` unscoped, project-wide, and takes the set difference. The rule states the shapes are interchangeable, because otherwise the next reader finds two of them and assumes one is a bug. Two related things stay out of the skill: the contract's *untraced is a gap in the plan, not slow progress* is already Phase 3b's own wording, and the truncated-read rule the two reads are held to is the contract's preamble rule, which the skill's Phase 1 conformed to when it was written — Phase 3b's "a `limit` above its requirement count" is the raise-the-bound half of it and needed nothing. |
| candidate ordering | amended in the skill | The recommendation table's order was not the contract's: it read specs-before-epics, and its preamble said "one to three, in priority order" without saying the table's order was that order. Reordered so the first three command-carrying rows are the contract's three kinds — `epic_ready`, `spec_without_epics`, `retro_missing` — with a preamble that says so and cites the contract. The rows the contract has no kind for (`/dpm:discover` on an empty project, a session in flight, uncommitted changes) stay: they are not derived from planning rows and the contract does not claim them. The waiver rule needed nothing — *Retro-waived epics are settled* already stated it. |

**Deliberate omissions in the other direction.** The contract's *Graceful degradation* table has no
skill counterpart and wants none: `no-database`, `tool-surface-mismatch` and `server-failed` are
states of a board spawning servers across many projects, and a skill running in a project whose
tools answered it has a database by construction. The *Inputs* table's `list_dependency_kind` row
is unreferenced by the skill for the reason recorded against *blocking* above.

**Why it needs a record.** What was left alone is the half that would otherwise be lost — after the
pass, an unamended passage and an unexamined one look identical. Three of the four contradictions
this reconciliation found were the *board's*, not the skill's, which is the case a record written
as a list of skill edits cannot express at all.

**What can break it.** Adding a `###` rule to *Derivation rules* in `dpm/shared/status-model.md`
without dispositioning it here. Rewriting the amended passages in `dpm/skills/status/SKILL.md` —
the recommendation table, the readiness paragraph, Phase 1's retired-story and `more` paragraphs —
puts the skill back out of conformance with no signal, since only the rule *names* are checked
mechanically.

**What asserts it.** `dpm/tools/board/tests/test_contract.py` reconciles this table's first column
against the contract's rule headings, in both directions and over a floor, so a rule added to the
contract fails until it appears here and a disposition for a rule that no longer exists fails too.

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

**The fork is ahead of the minimum, deliberately.** 1.2.1 adds a marker on the pause path, so a paused run is attributable in a transcript instead of reading like a crashed session. Nothing in CPM branches on it — the run summary already reports the outcome, and CPM stops by deleting the file rather than pausing — so it changes what a reader sees afterwards, not what a run does. The minimum stays at 1.2.0 for that reason: raising it would make users reinstall for a behaviour no CPM instruction depends on, which is exactly the coupling this record exists to keep honest.

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

**Neither generated prompt uses this field to stop itself, and that is deliberate.** A loop cannot stop by saying it is stopping — ending a turn is precisely what the Stop hook intercepts — so both templates define *stop the loop* as an action on a file. The action is **deleting** the state file, not setting `active: false`, for a reason that lives outside this record: `cleancheck-guard.sh` suppresses the shared Stale-Progress Check on this file's *existence*, so a run that ended by pausing would leave CPM's safety net silently off in that project for every later session and every skill. On any spec naming a production-host requirement that is the ordinary way runs end, so it would not stay rare. The delete is also the one termination all three plugins in the table honour, and the same one the hook itself performs on a matched promise — a run that stops this way leaves the project in the state a finished run leaves it in.

The field therefore matters here only as a *user-facing* kill switch, which is what the table above and Step 3c are about. `test-ralph-promise.sh` and `test-ralph-two-phase-prompt.sh` assert both halves: that each *stop the loop* names a mechanism, and that the mechanism is not a pause.

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
