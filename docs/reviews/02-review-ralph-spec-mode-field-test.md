# Review: `cpm:ralph` Spec-Mode Field Test

**Date**: 2026-07-28
**Source**: `/Users/chris/Work/git/ralph-test2` — autonomous run of `/cpm:ralph docs/specifications/01-spec-expense-settler.md`
**Scope**: Plugin (`cpm` 3.7.0), evidenced by a live autonomous run against a separate greenfield repo
**Method**: Read-only observation, 45s poll, ~5 hours. Every claim verified against source or a throwaway fixture before being recorded.
**Findings**: 38 observations — 12 actionable against the plugin (5 fixed, 7 open), 2 belonging to the Stop-hook plugin, the remainder evidence about the run

## Summary

The first end-to-end field test of `cpm:ralph` in **spec mode** — a greenfield repo containing nothing but a specification, with the loop responsible for the whole chain from `cpm:epics` through delivery. It ran 24 iterations, produced 24 commits, 450 Pest tests and 12 Dusk tests, and **terminated by refusing to emit `SPEC_DELIVERED`** because 19 coverage rows were `[target]` or `[manual]` and it judged itself not entitled to assess them. Zero automatable rows were left unticked.

That outcome is what spec 45 wanted, and it is the headline. The value of this document is the other two things it captured: **twelve defects in CPM that only a greenfield spec-mode run can surface**, and a record of what the loop did well that is worth not re-litigating.

One defect is **not** in the 38. The delivered application has no entry point — no page posts to the create route — and the observation log never noticed, because every check it ran was a check on the checks. It was found afterwards by a separate agent reading the delivered app. That is the single most important finding here and it is recorded in full under *The finding that is not an observation* below.

## Disposition

Verified against `cpm` 3.7.0 source on 2026-07-28. Line references are to that revision.

### Tier 1 — fixed 2026-07-28

| Obs | Finding | Component | Status |
|---|---|---|---|
| 8, 10 | `cov_base_label` strips only a trailing parenthesised qualifier, so `FR7 — Pence-exact remainder rule` and `R1 — Subagent delegation` never match `FR7` / `R1`. Range labels (`FR3-FR5`) are a third unhandled form. | `cpm/hooks/lib/coverage-parse.sh` | **Fixed.** A descriptive tail is stripped; a label naming several requirements resolves to nothing and the row is reported `UNRESOLVED` rather than reduced to its first member. Spec 40 went from `SUMMARY spec 10 10 0 0` exit 3 to `10 0 10 0` exit 0. The new record found one live malformed row (`FR8, FR5` in `46-02`), since split. |
| 1 | `coverage-rollup.sh` returns **1** for a missing `docs/epics/`, and the phase clause reads exit 1 as "could not run — stop". Iteration 1 of a greenfield spec-mode run *is* that state. | `cpm/hooks/lib/coverage-rollup.sh` | **Fixed.** A missing *default* directory returns 4, so a first iteration routes to phase 1; a `--matrix-dir` the caller named and got wrong keeps the read-failure code, so a typo is not answered by generating epics into a path nothing will read. OBS-3's `mkdir` workaround was never codified and is now unnecessary. |
| 6 | The autonomous `cpm:epics` wrote its progress file as `docs/plans/cpm-session-state-epics.md`; the convention is `docs/plans/.cpm-progress-{session_id}.md`. Nothing can discover the file it wrote. | 14 skills deferring without stating the path | **Fixed at the immediate layer.** All 18 skills that keep a progress file now state the path and the session-less fallback at the deferral point. The root — an 80.8 KB SessionStart payload inlined at 2 KB, so *every* "follow the shared X procedure" pointer targets an unread file — is untouched and remains the larger finding. |

Two things surfaced while fixing these, neither part of the original 38:

- **The documented fallback is outside the classifier glob.** `skill-conventions.md:144` names `.cpm-progress.md` for the hooks-absent case; `progress-classify.sh` globs `.cpm-progress-*.md`, which requires a session suffix. Consistent rather than broken — `CPM_SESSION_ID` comes from the same hooks whose absence selects the fallback, so nothing is classifying in that case — but the two halves live in different files and neither mentions the other. Now pinned by a test so widening the glob is a deliberate act.
- **`test-inspect-skill.sh` pinned a file rather than a change.** Its criterion is that introducing `/cpm:inspect` left `/cpm:audit` alone; its implementation compared the working tree against the commit before inspect appeared, which asserts that `cpm/skills/audit/` never changes again. The OBS-6 sweep touched audit and failed a criterion it has nothing to do with. Corrected to compare the commit that added inspect against its parent — the change that could actually have violated the must-NOT — and verified still to fire when pointed at a commit that did touch audit.

### Tier 2 — design decisions, not mechanical fixes

| Obs | Finding | Component | Status |
|---|---|---|---|
| 19 | `[target]` conflates production-host facts (genuinely uncheckable) with development-environment facts (checkable by anything running in that environment). Separately, `coverage_matrix_rows` emits columns `$2,$3,$4,$6,$8` — column 7, where the tag lives, is **never extracted**, so a self-ticked `[target]` row counts as ordinary verification. | `cpm/hooks/lib/coverage-parse.sh`, `cpm/skills/spec/SKILL.md` | **Open.** The vocabulary needs splitting before extracting the column is worth doing. ENV6/ENV8 were legitimately ticked; ENV1–ENV5 host claims were not checkable. |
| 5 | Test-runner discovery checks `composer.json`, `package.json`, `Makefile`… none of which exist in the greenfield case spec mode exists for. The spec's `ENVn` block states the answer, and `cpm:spec` calls that block *"the only place test tooling is captured"*. | `cpm/skills/ralph/SKILL.md:104-108` | **Open.** In spec mode, read `ENVn` first and config files second. Note `cpm:epics` *did* read the block correctly — the defect is confined to ralph's pre-flight reporting. |
| 2 | Bare `/cpm:ralph` in a spec-only repo: the skill says stop, the agent offered spec mode instead. The entire field test ran on the improvised branch. | `cpm/skills/ralph/SKILL.md:51` | **Open — needs a decision.** Either carve the case out explicitly or make the branch harder to route around. The helpful behaviour is currently undocumented improvisation. |

### Tier 3 — cheap, do alongside

| Obs | Finding | Component | Status |
|---|---|---|---|
| 4 | The exit-code contract is stated only *inside* the prompt template — text being assembled, not guidance the assembling agent reads. Costs ~3 tool calls per run re-deriving it from the script. | `cpm/skills/ralph/SKILL.md:159` | Open |
| 9 | The companion-asset rule says "a UI mockup **or diagram**" and prescribes `[manual]` visual conformance. A data-flow diagram is not built to look like anything. A mockup is a design target; a diagram is an argument. | `cpm/skills/epics/SKILL.md:177` | Open |
| 37 | CPM writes `active: true` into the ralph state file but ships no Stop hook, and the hook that exists terminates on file *existence*. `session-start.sh:59` already documents deletion as the kill switch. | `cpm/skills/ralph/SKILL.md:239,261` | Open — CPM's half only. Drop the field or say it is inert; a no-op named `active` is the trap. |
| 12, 21 | No gitignore guidance anywhere in ralph's SKILL.md or shared conventions. The loop committed CPM's own session state before catching it. | `cpm/skills/ralph/SKILL.md` | Open |
| 3 | Pre-flight wrote to the repo (`mkdir -p docs/epics`) to get past OBS-1. | `cpm/skills/ralph/SKILL.md` | Absorbed — disappears when OBS-1 is fixed at the script. |

### Not CPM's to fix

| Obs | Finding | Owner |
|---|---|---|
| 15 | The Stop hook prints the completion promise every iteration, so any transcript grep for `SPEC_DELIVERED` fires on the instruction rather than the emission. | `ralph-loop` plugin — `cpm/README.md:213` is explicit that CPM supplies no Stop hook |
| 37 | The hook ignores the `active:` field entirely; the only occurrences of the string are comments. | `ralph-loop` plugin |
| 14 | The assembled prompt is one 5,246-character line (template is 3,188 at `ralph/SKILL.md:172`). It cost a run. | Verify whether a single line is required by the hook's feedback format before treating this as CPM's choice. |

### Fixed — not from the 38

| Finding | Component | Commit |
|---|---|---|
| Reachability — a Must Have covered only by system-response criteria passes every gate while the delivered system has no way in | `cpm/skills/epics/SKILL.md` Step 3 (Reachability standard) and Step 4 (Unreachable gap class) | `2e3054e`, 2026-07-28 |

## The finding that is not an observation

The 38 entries below verify test counts, coverage arithmetic, oracle-verification patterns and `[target]` refusals. Every claim they check is true. **None of them asks whether a person can use the delivered application, and it turns out nobody can.**

The root cause runs the full chain and no link is individually wrong:

1. Spec FR1 describes route behaviour — what the system returns when a trip is created.
2. `cpm:epics`' **acceptance criteria fidelity** rule says to use the spec's language verbatim, so the criterion propagates faithfully.
3. The resulting criterion — "creating a trip mints a token and returns the trip URL" — is specific, observable and verifiable. It passes the testability standard outright.
4. Tests discharge it by posting directly to `/trips`. All FR1 tests do. Every browser journey starts at `/t/{token}`.
5. The coverage matrix ticks the row honestly.
6. No story owns the landing page, because no requirement describes one.

`/` says "Trip creation is not built yet". There is no `<form action=…>` anywhere in the application. `POST /trips` works and is unreachable.

The gate that can catch this is `cpm:epics` Step 4, because nothing downstream asks the question: `cpm:do` verifies criteria as written, and the roll-up counts ticks. That is what commit `2e3054e` implements — a **Reachability standard** in Step 3 requiring that a requirement naming a user action carry at least one criterion describing the affordance that reaches it, and an **Unreachable** GAP class in Step 4 that blocks a Must Have covered only by response criteria.

The monitoring failure is worth recording separately from the plugin defect. The log spends five hours praising the loop for never trusting a green result until it has seen the check fail on purpose — and then reports the run as delivering a working application on the strength of checks that were all sound and all beside the point.

## What the run demonstrated — evidence, not changes

Two things here are validation of existing CPM design and should not be re-litigated:

- **OBS-36 vindicates `cpm:epics` Step 3c.** Three Livewire components each passed their own story's criteria and did not compose on the same page: a participant added in one did not appear in another's payer list. The defect is unreachable from any single story's acceptance criteria *by construction*. A breakdown that verified story by story and stopped would have shipped it with a fully-ticked matrix. Step 3c reads as ceremony until this counter-example.
- **OBS-31's vacuous-assertion trap** is real but Pest-specific: a negated `toContain` with a trailing message passes unconditionally, because Pest reads every argument as a needle. Loud in the positive direction, silent when negated. This belongs in a library document, not a skill.

The run's distinguishing property, across five unrelated subjects (OBS-23, 25, 31, 33, 35), was that **it did not trust a green result until it had seen the check fail on purpose** — and a recurring preference for making an invariant *structural* rather than *procedural*: `Pence` has no float constructor, `TripToken::mint()` takes no arguments, revocation follows from replacing the digest rather than being a list of things to invalidate.

It also found three contradictions in the spec itself, the sharpest being that **FR11 and FR14 are jointly unsatisfiable at their stated bounds** (OBS-34): 128 bits × log₁₀2 = 38.53, minus 9 for a billion live trips = 29.53, under FR14's 10³⁰ floor. A compliant implementation taking FR11 at its word fails FR14 at scale.

## Reading the log below

It is a **running log**, kept in order as the run progressed, and it is preserved unedited — including where it was wrong. Predictions that did not hold and assessments that were later overturned are left in place with their corrections following, because the corrections are part of the evidence:

- **OBS-5** was logged as a structural failure, then downgraded once the matrices showed `cpm:epics` had read the `ENVn` block correctly.
- **OBS-6 addendum** and **OBS-11** record predictions that turned out wrong — the loop repaired both label defects autonomously rather than halting as OBS-8 forecast.
- **OBS-18 → OBS-19** is an over-broad `[target]` alarm aimed at the wrong thing.
- **OBS-30 → OBS-31** is the sharpest: OBS-30 assessed FR11's tests by reading their *names*, and two of the ones it praised were among the four vacuous assertions the loop later found and fixed. A test name is not evidence.

---

## Run record

**Subject**: `/Users/chris/Work/git/ralph-test2`, spec `docs/specifications/01-spec-expense-settler.md`
**Run**: session `34e1eabd`, `/cpm:ralph` invoked 12:32 BST, 2026-07-28. Spec mode, 50 iterations.
**Plugin under test**: cpm 3.7.0 (cache), matching this repo's source.
**Watcher**: `ralph-watch.sh`, armed 12:35, read-only, 45s poll.

Baseline at launch: 1 commit, spec only. No epics, no `.claude/ralph-loop.local.md`, no progress files.
Spec carries FR1–FR22, NFR1–NFR9, ENV1–ENV13, ENVX1–ENVX5 — a full spec-45-era environmental block,
so this run exercises the environmental-label path properly.

---

## OBS-1 — Spec mode cannot start in a repo that has never run `cpm:epics` (blocking)

`coverage-rollup.sh:474-477` returns 1 when `docs/epics/` does not exist:

```
if [ ! -d "$MATRIX_DIR" ]; then
  echo "coverage-rollup: matrix directory does not exist: $MATRIX_DIR" >&2
  return 1
fi
```

The spec-mode phase clause (`cpm/skills/ralph/SKILL.md:187`) reads:

> Exit 1 or 2 means the check could not run: say so and stop, and never read either as phase 1 not started.
> Exit 4 means phase 1 and no epics exist for this spec yet: run `/cpm:epics` on `{spec_path}` …

Iteration 1 of a spec-mode run in a fresh project **is** the missing-directory state. The prompt
instructs the loop to stop on the very first thing it does.

**Verified** in a throwaway fixture using this repo's `coverage-rollup.sh` and the test spec:

| `docs/epics/` | exit | stderr |
|---|---|---|
| absent | **1** | `matrix directory does not exist` |
| present, empty | **4** | `no matrix … names 01-spec-expense-settler.md as its source spec` |

The script draws its line at *"directory missing"* vs *"directory present, no matrix names this spec"*.
Spec mode needs both to mean phase 1. SKILL.md:212 already argues correctly that **exit 4, not the
untraced count, is what routes into `/cpm:epics`** — the reasoning is sound; the enumeration just
never contemplated the directory not existing.

**Recommended fix**: make `--spec` return 4 for a missing matrix directory. A missing directory and an
empty one are the same statement — *no matrix names this spec* — and collapsing them keeps the phase
decision on exit codes rather than pushing the loop into parsing stderr. The alternatives are worse:
adding "exit 1 + this stderr" to the phase clause makes the loop parse text, and having ralph's
pre-flight create the directory (see OBS-3) buries a load-bearing behaviour in a validation step.

---

## OBS-2 — The agent invented a mode-selection gate where the skill specifies a stop

Invoked as bare `/cpm:ralph`, no arguments. By `SKILL.md:22` that is auto-discovery → epic mode, and
by Step 1a.3 (`:51`):

> **Epic mode** — report to the user and stop: "No incomplete epics found. Nothing to run."

The agent instead ran `AskUserQuestion` — *"No epic paths were given and no epics exist. How should
this run be scoped?"* — with "Spec mode on the settler spec (Recommended)" first. That answer is what
the run is now executing.

The behaviour is helpful and probably what a user wants. It is not what the skill says, and it means
this field test is exercising a mode the skill would not have reached unaided.

**Decision needed**: if bare `/cpm:ralph` in a spec-only repo *should* offer spec mode, Step 1a.3's
epic-mode branch needs that case carved out explicitly. If it should stop, the agent over-helped and
the branch needs to be harder to route around.

---

## OBS-3 — Pre-flight wrote to the repo

`mkdir -p docs/epics` ran during pre-flight, to get past the exit-1 above. Pre-flight is otherwise
read-only: it stats scripts, runs the hook probe, and reads the spec.

It is load-bearing (without it OBS-1 stops the run on iteration 1) but undocumented, and a pre-flight
that aborts after this point leaves a stray empty directory behind. If OBS-1 is fixed at the script,
this workaround should disappear rather than be written down.

---

## OBS-4 — The exit-code contract is not readable from where pre-flight needs it

Three tool calls went on grepping and `sed`-ing `coverage-rollup.sh` for `exit 1|2|3|4` to work out
the semantics. Those semantics are stated — but only inside the *prompt template* (`:187`, `:193`),
which is the text being assembled, not something the assembling agent reads as guidance. Cost is
~3 calls per run plus the risk of reading them wrong.

---

## OBS-5 — Test-runner discovery is structurally guaranteed to fail in spec mode

Step 1d (`SKILL.md:102-108`) discovers the test runner by checking `composer.json`, `package.json`,
`Makefile`, `pyproject.toml`, `Cargo.toml`. In a greenfield spec-mode run **none of those exist yet** —
the application is what the run is about to build. The check cannot succeed in the case spec mode is
designed for, and the assembled prompt duly carries:

> No test runner was discovered in this project -- have /cpm:do establish or discover one at runtime.

Meanwhile the spec states the answer outright, in the block CPM designates as the single capture site
for exactly this (`cpm/skills/spec/SKILL.md` Step 3a: *"This is the only place test tooling is
captured"*):

| Label | Says |
|---|---|
| ENV6 | Pest 3 or later installed and runnable in development |
| ENV7 | Playwright or Laravel Dusk with headless Chromium |
| ENV8 | An isolated database per test run |
| ENV9 | k6, wrk or equivalent for load generation |
| ENV10 | axe-core or equivalent, driven from the browser automation |
| ENV11 | A test configuration denying outbound network access |
| ENV12 | Node LTS and npm for Vite asset compilation |

`{spec_path}` is already resolved in Step 1a, so the file is in hand when Step 1d runs. In spec mode
the `ENVn` block should be consulted first and the config files second — the spec is a statement of
what the target *must* provide, and the config files are at best evidence of what it currently does.

Same shape as OBS-1: a pre-flight check written against a repo that has already been built in, applied
to a run whose entire premise is that it has not been.

**Resolved at 12:41 — outcome is fine, the reporting is what's wrong.** The first coverage matrix traces
ENV6 to a story criterion reading *"Pest 3 or later is installed and the suite runs to completion from a
single command"*, and ENV7, ENV8 and ENV12 likewise. So `cpm:epics` **did** read the spec's `ENVn` block
and derive the tooling from it — the single capture site worked. The defect is confined to ralph's
Step 1d, which reports "no test runner discovered" when the answer was in the file it had already
resolved. Cost is a misleading pre-flight line and a `{test_runner_clause}` that tells `/cpm:do` to
discover something the spec already stated. Lower severity than first logged.

---

## OBS-6 — The autonomous `cpm:epics` wrote its progress file under a name nothing can find (live failure)

At 12:39 phase 1 wrote:

```
docs/plans/cpm-session-state-epics.md
```

The convention is `docs/plans/.cpm-progress-{session_id}.md` — no leading dot here, no session ID, wrong
stem. `progress-classify.sh:122` globs `"$STATE_DIR"/.cpm-progress-*.md`, so this file matches nothing.
Confirmed live: running the classifier against the repo with the file present emits **zero records**.

**Why it happened — and it is the SessionStart truncation, not a model slip.**

1. `epics/SKILL.md:430` says only *"Follow the shared **Progress File Management** procedure."* It never  
   states the filename.
2. The filename exists in exactly one place: `skill-conventions.md:138`.
3. That line sits at **byte 13,645** of `skill-conventions.md`. The CPM SessionStart hook's output is  
   too large to inline and is persisted to a file with a ~2 KB preview — so byte 13,645 never reached  
   the running agent's context.
4. The agent had a pointer to a procedure it could not read, and invented a plausible name from the  
   one thing it *could* see: the skill's own format template, whose H1 is `# CPM Session State`. Hence  
   `cpm-session-state-epics.md`.

The convention itself describes the split that broke: *"Skills define their own format; everything else
below is shared."* The format half lives in the SKILL.md and was followed exactly — correct H1, correct
`**Skill**`, `**Step**`, `**Input source**`, `**Session**` fields. The path half lives in the shared file
and was not. `CPM_SESSION_ID` was available (the file records it), so the agent had the ID and only
lacked the place to put it.

**Consequences, in order of immediacy:**

- **The next autonomous commit will sweep it into history.** The prompt says *"Commit after each  
  completed story"*, and this is not a dotfile, so it is a visible untracked file in `docs/plans/`.
- **Invisible to the Stale-Progress Check.** If this run dies, the next session's safety-net finds nothing.
- **Spec 45 FR12's leftover detection is defeated.** That story detects a leftover `cpm:epics` progress  
  file by classifying candidates and comparing `**Input source**` to `{spec_path}`. This file *has* a  
  correct `**Input source**` — the content the story needs is present and unreachable, because detection  
  routes through the classifier's glob.
- **`/cpm:clean` will not find it.**

**Fix, two layers.** Immediate and cheap: have `epics/SKILL.md` (and every skill that defers to the
shared procedure) state the path literally, since the pointer is worthless when the target does not
load. Root: the SessionStart hook payload has exceeded the inline limit on all 149 sessions ever
recorded — see the /doctor finding — so *every* "follow the shared X procedure" reference in every CPM
skill is currently a pointer into a file the agent has not read. This is the first observed instance of
that costing correctness rather than just tokens.

**Positive note from the same event.** The epic breakdown itself is sound: 7 epics with correct
parent-scoped two-part numbering (`01-01` … `01-07`), and a dedicated `01-07-epic-environmental-verification`,
which is the ENV block getting its own epic — a good sign against OBS-5's concern.

---

## OBS-7 — A `[target]` requirement can reach `SPEC_DELIVERED` having only been checked by proxy in dev

The first coverage matrix (`01-01-coverage-application-foundation.md`) carries a prominent section
headed **"Fidelity note — tag divergence on the ENV rows"**, stating that rows 1, 2, 5, 6, 7, 11, 12 and
13 carry a story tag differing from the spec's: the spec assigns `[target]`, the story criteria carry
`[integration]` or `[feature]`. It says this is *"deliberate and is recorded here rather than resolved,
because it is a judgement a reviewer should see."*

**The run's behaviour here is honest.** It did not hide the divergence; it wrote it up under its own
heading. The problem is that nothing mechanical carries it forward.

**Nothing reads the marker.** `coverage_matrix_rows()` (`coverage-parse.sh:472-479`) emits
`KIND / BASE / LABEL / SPEC_TEXT / COVERED_BY / VERIFIED` — columns 2, 3, 5 and the tick. The
**"Spec Test Approach" column, which is where `[target]` lives, is column 6 and is never extracted.**
The fidelity note itself is prose in a Notes section no parser reads.

**So the chain completes with nothing objecting:**

1. Spec marks ENV3 `[target]` — checkable only against the real deployment target.
2. `cpm:epics` writes a locally-checkable proxy criterion — *"the SQLite database file path is  
   configuration-driven, not hardcoded"* — and tags it `[integration]`.
3. `cpm:do` runs it, it passes, `✓` lands in the Verified column.
4. The roll-up counts the row verified; column 6 was never read.
5. `--spec … --verdict` exits 0 and the loop emits `SPEC_DELIVERED`.

ENV3 — *persistent storage surviving deploys and restarts* — has at no point been checked against
anything. The same applies to ENV2 (WAL on the target), ENV7 (browser automation on the target), ENV12
and ENV13 (compiled assets on the production host).

**The prompt's `[target]` rule cannot fire here.** It reads *"A `[target]` criterion is checkable only
against the real deployment target, so never self-assess one and never count it as met."* That rule is
applied by `cpm:do` to the **story criterion's** tag — and the story criterion's tag is `[integration]`.
The re-tagging at the epics step disarms the guard before `cpm:do` ever sees it. `[target]` is
load-bearing in the spec and inert everywhere downstream.

Some of the individual re-tags are defensible in isolation — *"`PRAGMA journal_mode` reports `wal`"*
genuinely is testable locally. The issue is not any one row's judgement; it is that the judgement is
recorded only in prose, and the mechanism treats a proxy exactly as it treats the requirement.

**Recommended fix — the machinery already exists.** `coverage-parse.sh` already has a `story-originated`
row kind that *"carries no BASE, so nothing downstream can count one toward a requirement's state."*
That is precisely the semantics a local proxy for a target-only requirement needs. So:

1. **`cpm:epics` must not downgrade a `[target]` spec tag.** The requirement row inherits `[target]`  
   and stays uncounted. Any locally-checkable proxy is written as an additional **story-originated**  
   row, which reports separately and cannot satisfy the requirement.
2. **Make column 6 load-bearing.** Have `coverage_matrix_rows()` emit the spec test approach, and have  
   the roll-up report a `[target]` row as `target-only` in the SUMMARY rather than counting a `✓` on it.

Either alone closes the hole; together they also make the existing tag mean what it says.

---

## OBS-8 — The generated matrices trace nothing, and the same defect is live in this repo (critical)

At 12:43, with three matrices written, the roll-up reports:

```
SUMMARY	spec	46	46	0	0        ← 46 requirements, 46 untraced
EXIT=3
```

…while emitting ROW records for FR3, FR4, FR5, FR6, FR7, FR8, FR9, NFR3, NFR8, NFR9 out of those very
matrices. The rows are parsed. They just never link to a requirement.

**Root cause — a contract gap between the template and the parser.**

`coverage-parse.sh:75-76,180` defines the label cell as a bare label with an optional **parenthesised**
qualifier:

> `FR1 (must NOT)` and `FR6 (cross-site)` resolve to `FR1` and `FR6`

`coverage_base_label` strips only that parenthesised qualifier. Verified directly:

| input | `coverage_base_label` returns |
|---|---|
| `FR7` | `FR7` |
| `FR1 (must NOT)` | `FR1` |
| `FR7 — Pence-exact remainder rule` | `FR7 — Pence-exact remainder rule` |

`cpm:epics` wrote the third form. It never matches the spec's `FR7`, so every requirement stays untraced.

And the template does not forbid it. `epics/SKILL.md:289` reads:

```
| 1 | {requirement label} | {exact text from spec requirements section} | … |
```

`{requirement label}` is unspecified. Writing `FR7 — Pence-exact remainder rule` is a reasonable reading
— it is more informative — and it silently breaks the join. The parser's constraint is stated only in
the parser.

**This is already live in this repo, not just the test.** Same parser, same command, two formats:

| spec | matrix label format | SUMMARY | exit |
|---|---|---|---|
| 45 | `FR4`, `FR1 (must NOT)` | `19 0 19 0` — 0 untraced | 0 |
| 40 | `R1 — Subagent delegation` | `10 10 0 0` — **10 of 10 untraced** | 3 |

Spec 40's matrices carry rows referencing R1, R2, R10. The roll-up reports every one of its eleven
requirements as having no matrix row at all.

**Predicted consequence for this run.** When phase 1 finishes the seventh epic, the next iteration
re-reads the phase check, gets exit 3 with untraced 46, and hits this clause:

> An untraced count that is not 0 on any other code means `/cpm:epics` has already run and what it wrote
> does not cover the spec: report that partial set from the STATE records … leave every epic doc already
> on disk exactly as it is, and **stop**; never run `/cpm:epics` twice in one run.

So the loop should **halt at the end of phase 1 and never build anything** — reporting, correctly by its
own rules, that the epics do not cover the spec. The rules are working; the input to them is wrong.

### The content is right; only the format is wrong

Measured at 12:47 with 6 of 7 epics written, comparing spec labels against labels appearing in any
matrix row — i.e. ignoring the linking bug entirely:

- **49** labels in the spec; the roll-up scopes to **46** (it correctly excludes the three *Could Have*  
  FRs — FR20, FR21, FR22).
- **33** already have at least one matrix row.
- **13** do not: ENV1, ENV4, ENV5, ENV9, ENV10, ENV11, ENV13, ENVX3, ENVX4, ENVX5, NFR1, NFR4, NFR7.
- **0** rows reference a label the spec does not define — nothing fabricated.

Those 13 are precisely the ones the seventh epic — `01-07-epic-environmental-verification` — exists to
carry, together with the three NFRs that depend on environmental tooling (NFR1 and NFR7 need ENV9's load
generator; NFR4 needs ENV3's persistent storage). So the generation is on plan, and if 01-07 covers them
the matrices will describe complete coverage while the roll-up still reports 46 untraced.

**That makes the defect purely mechanical, and the cheaper fix is at the parser.**

Two options, and the second is better:

1. **Pin the format at the template.** `epics/SKILL.md:289` specifies a bare label with only the  
   parenthesised qualifiers the parser recognises. Correct, but it fixes nothing already written —  
   spec 40's matrices in this repo stay broken until edited by hand.
2. **Normalise in `coverage_base_label`.** Take the leading `^[A-Z]+[0-9]+` token as the base. Labels are  
   `FR\d+`, `NFR\d+`, `ENV\d+`, `ENVX\d+`, `R\d+` — none can contain an em-dash or a space — so this is  
   unambiguous, it preserves the existing `(must NOT)` / `(cross-site)` handling, and it repairs every  
   matrix already on disk with no document edits. Spec 40 would start tracing again immediately.

Do both: (2) to make the join robust, (1) so generated matrices stay canonical. Either way a test
asserting `coverage_base_label` over a real generated matrix's label column is what was missing — it
would have caught this, and would flag spec 40's matrices today.

Worth noting what this vindicates: `SKILL.md:212` argues that a non-zero untraced count is *"evidence
about the epics, not about the phase"* and must not send the loop back to generation forever. That
reasoning is exactly what stops this from becoming an infinite regeneration loop.

---

## OBS-9 — The companion-asset rule conflates a mockup with a diagram (low severity)

The spec references its companion asset at line 123, inside the *Token transport* architecture decision:

> See diagram: [token flow and exposure surface](assets/01-expense-settler-token-flow.html)

No epic and no matrix references it. **That is the right outcome**, and the run also honoured the
prohibition half of the rule — it extracted no requirements from the asset.

But it is right for a reason the skill does not draw. `epics/SKILL.md`'s rule opens *"When a `spec` or
`architect` artifact references an HTML companion asset (a UI mockup **or diagram**…), a story criterion
that says 'build to match this asset' describes visual conformance"* and prescribes `[manual]`/`[feature]`.
Read literally, a 31 KB **data-flow diagram of token exposure surfaces** would get a `[manual]`
visual-conformance criterion — which would be meaningless, since nothing is built to look like it.

A mockup is a design target; an explanatory diagram is an argument. Only the first takes "build to match
this" semantics. The rule should say so, or the run's correct behaviour here is luck rather than
compliance.

---

## OBS-10 — Range labels: a third format, and it defeats the OBS-8 fix I recommended

Phase 1 finished at 12:48 — 7 epics, 7 matrices, 14 files. A label-by-label tally appeared to show five
in-scope requirements with no matrix row: ENV4, ENV5, ENV10, ENV11, ENVX3.

**That reading was wrong, and the reason matters.** Epic 01-07 covers them with **range labels**:

```
| 3 | ENVX1–ENVX3 | Full suite passes with no queue worker, no scheduler, and no websocket server …
| 7 | ENV9–ENV11  | Development environment provides load generation with timing capture, an accessibility …
| 9 | ENV1–ENV5   | Production host satisfies PHP 8.3+, SQLite 3.35+ in WAL, persistent writable storage …
```

One row asserting coverage of up to five requirements. So the content gap is not real — but a **third
label format** now exists, and it is the most dangerous of the three.

**It defeats the fix recommended above.** OBS-8 option 2 was *"take the leading `^[A-Z]+[0-9]+` token as
the base."* Applied to `ENV1–ENV5` that yields `ENV1` — and silently drops ENV2, ENV3, ENV4, ENV5. The
row would resolve, the roll-up would report ENV1 traced, and four requirements would read untraced while
a row on disk claims to cover them. That is worse than today's failure, which at least fails uniformly
and visibly. **Do not ship that normalisation without handling ranges.**

**The deeper problem is the contract, not the parser.** A coverage matrix's value rests on one row per
requirement-to-criterion mapping — `epics/SKILL.md:294` says so directly: *"Where a single spec
requirement maps to multiple story criteria, include one row per criterion so each mapping is
independently visible."* A range row inverts that: several requirements, one criterion, one Verified
cell. Ticking it would mark five requirements verified on one piece of evidence.

**Fix**: `cpm:epics` must emit one row per requirement, never a range — stated at the template alongside
the bare-label rule. The parser should additionally *reject* a label it cannot resolve to exactly one
requirement rather than silently taking the first token, so a fourth format cannot fail quietly the way
this one nearly did.

**Credit where due.** The run tracked the target-only ENVs deliberately rather than losing them:
`01-01-epic-application-foundation.md:154` records *"ENV1, ENV4, ENV5 are not covered here. They are
`[target]` rows in the spec"*, deferring them to the environmental epic. The intent was right; the
notation defeated it.

**Corrected coverage position**: all 46 in-scope requirements have a matrix row. FR20, FR21 and FR22 are
*Could Have* and correctly out of the roll-up's 46. The only barriers to a clean phase-1 finish are the
two label-format defects, OBS-8 and OBS-10.

---

## OBS-11 — The loop repaired both label defects autonomously. The halt prediction was wrong.

At 12:50 all seven matrices were rewritten simultaneously (each ~300–800 bytes smaller), then 01-07 was
rewritten again at 12:50:52 (+3,092 bytes). Result:

| time | SUMMARY (`req untraced delivered in-progress`) | exit |
|---|---|---|
| 12:48 — phase 1 finished | `46 46 0 0` | 3 |
| 12:50 — em-dash titles stripped | `46 7 0 39` | 3 |
| 12:51 — ranges expanded | **`46 0 0 46`** | 3 |

The loop diagnosed OBS-8 and OBS-10 and fixed both without human input:

- `FR7 — Pence-exact remainder rule` → `FR7` across all seven matrices.
- `ENV1–ENV5`, `ENV6–ENV8`, `ENV9–ENV11`, `ENVX1–ENVX3` expanded into individual rows. 01-07's label  
  column now reads ENVX1…ENVX5, ENV1…ENV13, NFR1, NFR2, NFR4, NFR7 — one row per requirement.

**Untraced is 0, so by the phase clause the loop moves to phase 2 and starts building.** The prediction
recorded in OBS-8 — that it would halt at the end of phase 1 — did not hold, because the loop repaired
the input to the rule rather than obeying the rule over broken input. That is a better outcome than the
one predicted, and it is the strongest evidence so far that the autonomy design works.

**It did this within its constraints.** Checked explicitly:

- **No fabricated verification.** Zero data rows carry a `✓`. Every `✓` in the tree is either the header  
  *"Verification rule"* line or prose about `[target]` rows. The scorecard's Verified column was not  
  touched.
- **No second `cpm:epics` run** — the prompt forbids it, and no regenerated epic set appeared.
- **No content loss** — row counts held or grew; the expansion added rows rather than replacing them.

**The design question this raises, stated plainly.** The mechanism here was *"the coverage number is bad
→ edit the coverage matrices → the number improves."* On this occasion the edit was pure format
normalisation and entirely legitimate. But it is the loop editing its own scorecard, and what made it
safe is precisely that it left the Verified column alone. That invariant — **a loop may normalise a
matrix's structure but must never write its Verified column outside a `cpm:do` verification gate** — is
currently an emergent property of good behaviour rather than a stated rule. It is worth writing down.

**What this does not change.** OBS-8 and OBS-10 remain real defects in what `cpm:epics` generates, and
the self-repair cost roughly three iterations of a 50-iteration budget. More importantly the loop fixed
*its own* repo — **spec 40 in `claude-code-marketplace` still reports 10 of 11 requirements untraced**
and no loop is going to notice that.

---

## OBS-6 addendum — the "it will be committed" prediction was wrong

`cpm:epics` deleted `docs/plans/cpm-session-state-epics.md` at the end of phase 1, before the commit. It
is absent from history (`git log --all --diff-filter=A -- 'docs/plans/*'` returns nothing). The correct
lifecycle ran despite the wrong filename.

The rest of OBS-6 stands unchanged and is unaffected by this: while the file existed it was invisible to
`progress-classify.sh`, so a crash during phase 1 would have left nothing the Stale-Progress Check or
spec 45 FR12's leftover detection could find. The recovery path was broken for the ~12 minutes it
mattered; the cleanup path was not.

---

## OBS-12 — The loop's own state file was committed, and will be re-committed every iteration

Commit `78137e8` includes `.claude/ralph-loop.local.md` (+10 lines) alongside the 14 epic artefacts.

The repo has **no `.gitignore`**, and the commit workflow stages everything. The `.local.md` suffix
signals intent — `cleancheck-guard.sh` keys on this exact path as the marker of an in-flight loop — but
nothing enforces it. Neither `cpm:ralph`'s SKILL.md nor the ralph-loop plugin mentions gitignore.

Consequences over a 50-iteration run:

- The file's `iteration:` counter changes every cycle, so **every story commit carries state-file churn**  
  alongside the real work.
- The full assembled prompt (~5 KB) sits in the repo's history.
- When the loop finishes cleanly the plugin deletes the file, which lands as a deletion commit.
- *"Keep all commits local"* protects against pushing, not against the file being tracked. Anyone who  
  later pushes the branch carries the loop state with it.

**Fix**: `cpm:ralph` pre-flight should ensure `.claude/ralph-loop.local.md` is gitignored before arming —
appending to `.gitignore`, or creating `.claude/.gitignore` containing the filename. It already writes
the state file; ensuring it is untracked is the same step's business.

---

## OBS-13 — The run found a genuine contradiction in the spec, and recorded rather than repaired it

The phase-1 commit message reads, unprompted:

> Records rather than repairs two things found in the source: the FR17 clipboard control versus NFR9's
> no-hand-authored-JS rule, and the split between application-level ENV criteria (checkable here) and the
> spec's `[target]` ENV rows (checkable only against a real host).

The first is a real defect in the spec that a human review missed. **FR17** requires *"a copy-link control
that states plainly that anyone with the link has full access"* — clipboard access needs JavaScript.
**NFR9** requires that *"the repository contains no hand-authored JavaScript beyond the Vite/Livewire
bootstrap."* The two cannot both hold as written.

This is exactly the behaviour `epics/SKILL.md:57` mandates for an autonomous run — *"A gap or
contradiction found in the source mid-run is **recorded, not repaired**"* — and the run did it without
being asked, in the commit message as well as the epic docs. It did not touch
`docs/specifications/`.

The second item is the OBS-7 fidelity divergence, surfaced again at commit level. So the divergence
*is* visible to a human reading the history — which somewhat softens OBS-7's severity, though it remains
invisible to the roll-up.

---

## OBS-14 — The prompt is written as one 5,246-character line, and it cost a run

The run was stopped by the operator at 12:52 because the stop hook's output looked corrupted:
`ninths/hooks` for the full plugin path, `coverage-rollup.sh--spec` with the space gone, `saSUMMARY`
mid-word. It was not corrupted. Verified against the state file on disk:

| check | result |
|---|---|
| `…/cpm/3.7.0/hooks/lib/coverage-rollup.sh` intact | present |
| truncated `ninths/hooks` | absent |
| `coverage-rollup.sh --spec` with space | present |
| body shape | **1 line, 5,246 chars** |

`iteration: 2` in the frontmatter confirms the hook ran and the loop advanced. `Stop hook error:` is
normal mechanics — ralph-loop blocks the stop and the prompt *is* the block reason. Every apparent
defect is terminal overwrite at wrap boundaries on a line no terminal can render.

**Wrapping is safe**, checked at all three places it could break:

- `stop-hook.sh:149` — `PROMPT_TEXT=$(awk '/^---$/{i++; next} i>=2' …)` takes every line after the  
  frontmatter, so a multi-line body passes through verbatim.
- `stop-hook.sh:180-185` — `jq -n --arg prompt "$PROMPT_TEXT"` escapes newlines into the JSON.
- The four CPM suites touching `ralph-loop.local.md` write only frontmatter lines or a placeholder  
  string; none assert on body prose. The long literals in the ralph suites are `sed` mutations against  
  `SKILL.md`'s fenced template, and the `1681 characters` assertion reads SKILL.md's own stated count —  
  neither sees the written state file.

Re-wrapping the body at 100 columns was verified **word-for-word identical**, 5,246 characters both
ways, 56 lines instead of 1.

**Fix**: `cpm:ralph` Step 3 should `fold -s -w 100` the body when writing the state file. The prompt is
the one artefact a human supervising an unattended run actually sees, at every iteration, and it is
currently unreadable. This defect has now cost one run directly.

---

## Phase 2 watch — baseline and stop criteria

Restarted 12:58 with `/cpm:ralph docs/specifications/01-spec-expense-settler.md` (spec path explicit —
bare invocation would now resolve to *epic* mode, since seven Pending epics exist, and would carry
`ALL_EPICS_COMPLETE` instead of `SPEC_DELIVERED`).

Before the restart landed, iteration 2 had already read `COUNTS: 46 requirements, 0 untraced, 0
delivered, 46 in progress`, entered phase 2, found no `[plan]` tags to strip, probed the toolchain
(PHP 8.4.23, Composer, Node v22.18.0, npm — ENV1 and ENV12 satisfiable locally) and invoked `/cpm:do`
on 01-01. The restart interrupted that.

**Baseline**: iteration 2, HEAD `78137e8`, 0 verified ticks, 0 test files, 2 commits.

**Stop immediately if**: `docs/specifications/` is modified; `SPEC_DELIVERED` is emitted while target
rows are unverified; `vendor/` or `node_modules/` becomes tracked (no `.gitignore` exists and the loop
stages everything); the epic set is regenerated wholesale.

**Do not stop for**: the mangled prompt display (OBS-14); `[target]` rows never receiving a `✓`;
01-07 Stories 3–5 remaining open at the end — all three are correct behaviour.

**Judgement calls**: iteration climbing without commits; the 3-strike skip rule firing repeatedly on one
story; iteration ≥ 45 of 50.

---

## OBS-15 — The completion promise appears in the hook's own output every iteration

My watcher grepped the transcript for `SPEC_DELIVERED</promise>` and fired twice on a run that had
emitted nothing (ticks 0, commits 2, iteration 2, zero assistant-authored promise tags). The string is
printed by the stop hook itself on **every** iteration:

> 🔄 Ralph iteration 2 | To stop: output `<promise>SPEC_DELIVERED</promise>` (ONLY when statement is TRUE…)

So the promise the loop is watched *for* is emitted by the watcher's own instrumentation. Any external
completion detector — a log scraper, a CI gate, a notifier — that greps a transcript or terminal capture
for the promise tag will report success on iteration 1 of a run that has done nothing.

A detector has to distinguish authorship, not just presence:

```sh
jq -r 'select(.type=="assistant") | .message.content? // empty
       | if type=="array" then .[] else empty end
       | select(.type=="text") | .text' "$transcript" \
  | grep -q '<promise>SPEC_DELIVERED</promise>'
```

Cheap mitigation on the plugin side: have the stop hook print the promise name without the tag
delimiters — `output the promise SPEC_DELIVERED in a promise tag` — so the literal matched string only
ever appears when the model writes it. The hook already compares the tag contents with literal string
equality, so nothing downstream depends on it printing the delimiters.

Logged as a finding rather than as an operator error because it is a property of the design: the loop
publishes its own exit signal into the channel an observer reads.

---

## What is working well

Recorded deliberately — a field test that lists only defects misreports the run.

- **`[manual]` discipline is exemplary.** Epic 01-05 carries 20 `[feature]`, 10 `[integration]`,  
  4 `[unit]`, 3 `[tdd]` against just 3 `[manual]`. The one substantive `[manual]` (NFR5 row 14,  
  *"usable one-handed on a phone at a restaurant table"*) propagates the spec's own justification  
  unchanged and is called out in a dedicated note. This is the *default to automation* guideline  
  working exactly as intended.
- **NFR5 was decomposed rather than deferred.** Rather than one untestable accessibility criterion, it  
  became four rows: automated WCAG scan, scan against Livewire-updated state (not just initial render),  
  keyboard/label checks, and the one genuinely human criterion. The second of those is a real insight  
  about Livewire the spec did not spell out.
- **must-NOT clauses propagated** with spec wording intact, including on money-path rows.
- **Epic decomposition is sound** — 7 epics, correct parent-scoped numbering, sensible boundaries, and a  
  dedicated environmental-verification epic for the ENV block.
- **The fidelity divergence was written down** rather than quietly applied (OBS-7). The judgement is  
  arguable; the transparency is not.

---

## Timeline

| Time | Event |
|---|---|
| 12:28 | prior session commits the spec (`6600906`) |
| 12:32 | `/cpm:ralph` invoked, no args |
| 12:32 | pre-flight: progress-classify clean, hook probe run, no test runner config found |
| 12:32 | `mkdir -p docs/epics` (OBS-3) |
| 12:32 | mode question asked (OBS-2); answer: spec mode, 50 iterations |
| 12:33 | prompt assembly begins |
| 12:35 | watcher armed, 4 tracked paths |
| 12:38 | loop launched — `.claude/ralph-loop.local.md` written, `active: true`, iteration 1/50, `completion_promise: "SPEC_DELIVERED"` |
| 12:38 | live phase check reads **exit 4** (because pre-flight created `docs/epics/`), so iteration 1 routes to `/cpm:epics` rather than stopping — OBS-1 and OBS-3 both confirmed in the live run |
| 12:39 | phase 1 running: `cpm:epics` writes `docs/plans/cpm-session-state-epics.md` — wrong name, invisible to the classifier (OBS-6). Plans 7 epics, `01-01` … `01-07` |
| 12:40 | first epic doc written: `docs/epics/01-01-epic-application-foundation.md` |

---

## OBS-16 — The loop scaffolds into a staging directory and moves, rather than scaffolding in place

Phase 2's first task had to install Laravel into a directory that was already a git repo with
`docs/` in it — `laravel new .` refuses a non-empty target. The loop's chosen route was to
scaffold into `.laravel-scaffold/`, then move the tree to the root and delete the staging dir.

Two things went right that are worth recording because neither is obvious:

- **Dotfiles moved with it.** The root now carries `.gitignore`, `.editorconfig`, `.gitattributes`,  
  `.env.example`. Laravel's own `.gitignore` is what keeps `vendor/` (78 MB, 8,573 files) and `.env`  
  out of the index — a move that skipped dotfiles would have left the repo one `git add -A` away  
  from committing the whole dependency tree.
- **The staging directory was cleaned up.** `.laravel-scaffold/` no longer exists.

Confirmed after the move: `git add -A --dry-run` stages ~60 paths across `app`, `bootstrap`,
`config`, `database`, `public`, `resources`, `routes`, `storage`, `tests` and the root config files.
No `vendor`, no `node_modules`, no `.env`. `git ls-files vendor node_modules` returns 0.

**Watcher defect found by this, not by the loop.** The `TESTS files 0 -> 15` alert during the move
was mine: `tests_n()` pruned `./vendor/*` by exact path, which does not match
`./.laravel-scaffold/vendor/*`. 13 of the 15 were vendor files. Fixed to prune `vendor`,
`node_modules` and `.git` by name at any depth. A monitor that reports a build's intermediate
states as anomalies costs the same attention as a real alert.

## OBS-17 — Phase 2 story mechanics look correct

Epic `01-01-epic-application-foundation.md` after the first work block:

- Story 1 `**Status**: In Progress`; tasks 1.1, 1.2, 1.3 `Complete`; all later stories `Pending`.
- `tests/Feature/ApplicationFoundationTest.php` written — a real test, alongside the two Laravel  
  `ExampleTest.php` stubs.
- `docs/plans/` created — `cpm:do`'s progress file, as designed.

Per-task status writes are landing in the epic doc as `cpm:do` specifies, so a mid-story crash
would resume from task 1.4 rather than restarting the story. That is the resume property spec 45
FR12 is about, observed working in the unmodified case.

## OBS-18 — OBS-7 confirmed in the field: a `[target]` row has been self-ticked and the roll-up counts it

Story 1 completed and committed as `cd73346`. Four rows in
`01-01-coverage-application-foundation.md` now carry ✓. Two of them — rows 1 (ENV2, WAL journal
mode) and 2 (ENV3, durable database path) — carry `` `[target]` `` in column 6, *Spec Test Approach*.

This is the exact hazard OBS-7 described, no longer theoretical. `coverage_matrix_rows()` extracts
columns 2, 3, 5 and the tick; **column 6 is never read**. So the roll-up sees two ordinary verified
rows and has no way to know that the check behind them can only be made against a real deployment
target. Current census across all seven coverage files: **26 `[target]` rows, 2 of them ticked.**

**The loop is not being careless about it — which is the interesting part.** The epic's author
wrote an unprompted *Fidelity note* below the matrix stating that the spec's ENV rows assert *an
environment provides* something (checkable only on a host, hence `[target]`) while the story criteria
assert *the application is configured* to use it (checkable here, hence an automated tag), and
warning in terms:

> A reader should not read a fully-verified column here as evidence that the deployment target
> satisfies ENV2, ENV3, ENV7 or ENV12 — it is not evidence of that, and epic 01-07 is where that
> question is asked.

So the distinction is understood and recorded in prose. It is simply invisible to the parser that
decides whether the promise fires. **Prose the machine cannot read is not a control.** If the fix
for OBS-7 is ever built, this note is the argument for extracting column 6 rather than for
re-tagging the rows.

**Sharpened watch item.** My earlier prediction — `SPEC_DELIVERED` is unreachable because 01-07's
`[target]` rows cannot be honestly ticked — now has a failure mode: if the loop ticks 01-07's rows
the same way, the promise fires on self-assessment of things requiring a real host. That is a
stop-and-inspect moment, not a success. The watcher now counts self-ticked `[target]` rows and
alerts on any increase, naming the requirement.

**Roll-up state at this point**: `SUMMARY spec 46 0 0 46`, exit 3 — 46 requirements, **0 untraced**
(phase 1's label self-repair held), 0 fully verified, 46 with rows outstanding. Exit 3 in the
completion clause means keep working, which is correct.

## OBS-19 — `[target]` conflates two different claims, and only one of them is unverifiable here

Story 2 ticked ENV6 and ENV8, both tagged `` `[target]` ``. The watcher raised it. Checked, and the
ticks are honest:

- **ENV6** — "Pest 3 or later installed and runnable in development." `composer.json` requires  
  `pestphp/pest: ^3.0`; `./vendor/bin/pest` runs **23 tests, 33 assertions, all passing**.
- **ENV8** — "An isolated database per test run." `phpunit.xml` forces `DB_DATABASE=:memory:`, and  
  `tests/TestCase.php::setUp()` throws on any persistent database file, with  
  `TestSuiteIsolationTest` exercising the guard.

**So OBS-18's alarm was aimed at the wrong thing.** `[target]` is being used for two claims that
are not alike:

| Claim | Example | Checkable by the loop? |
|---|---|---|
| **Production-host fact** | ENV2 WAL on the deployed database, ENV3 durable path, ENV4/ENV5/ENV13, NFR2/NFR4/NFR7 | **No** — needs the real host |
| **Development-environment fact** | ENV6 Pest installed, ENV8 isolated test DB, ENV7 Dusk runnable, ENV12 Node/npm for Vite | **Yes** — the loop *is* the development environment |

`cpm:spec` tagged every ENV row `[target]` uniformly. That uniformity is the defect, not the loop's
ticking: a development-environment requirement is verifiable by anything running in that
environment, and refusing to let it be ticked makes `SPEC_DELIVERED` unreachable for reasons that
have nothing to do with the deployment target. The watcher's signal is downgraded to NOTE
accordingly — only 01-07's host rows are stop-worthy.

**Worth carrying back to CPM**: `[target]` wants splitting, or `cpm:spec` wants guidance not to
apply it to development-tooling requirements. The distinction the loop drew by hand in its fidelity
note is the one the tag should be making.

## OBS-20 — The loop empirically disproved its own first fix and wrote the finding into the artefact

`phpunit.xml` carries this comment above the forced env block:

> …it does NOT stop an exported `DB_DATABASE` from reaching Laravel's `env()` resolution, which was
> verified by running the suite with one exported. The enforcement lives in `tests/TestCase.php`,
> which refuses to run against any persistent database file. Do not treat these lines as the
> guarantee.

The obvious implementation of ENV8's must-NOT is `force="true"` in `phpunit.xml`. The loop wrote
that, **tested it by exporting `DB_DATABASE` and running the suite**, found it insufficient, moved
the guarantee into `TestCase::setUp()`, and left a note at the weaker mechanism telling the next
reader not to trust it.

That is the behaviour the whole spec-mode design is trying to buy: a must-NOT clause treated as a
property to be falsified rather than a box to tick. Nothing in the prompt asked for the export
experiment.

## OBS-21 — CPM ships no gitignore guidance, and the loop committed CPM's own session state before catching it

`grep -rn 'gitignore' cpm/` across the whole plugin returns **nothing**. CPM writes its
session-state files into `docs/plans/` — a directory users commit — and never tells anyone to
ignore them:

- `docs/plans/.cpm-progress-{session_id}.md` — the per-skill progress file
- `docs/plans/.cpm-compact-summary-{session_id}.md` — written by the PostCompact hook

Both are transient by design; `skill-conventions.md:153` says to delete the compact summary
alongside the progress file. In an interactive session that is invisible, because a human staging
changes does not type them. **In autonomous mode with `git add -A`, leakage is guaranteed.**

Observed exactly that:

| Commit | Swept in |
|---|---|
| `cd73346` Story 1 | `docs/plans/.cpm-progress-34e1eabd-….md` |
| `29c4515` Story 3 | `docs/plans/.cpm-compact-summary-34e1eabd-….md` (317 lines) |

**Then the loop caught it unprompted.** Commit `d0ca09f` "Ignore session-scoped agent state" added

```
# Session-scoped agent state, not part of the project's history
/.claude/ralph-loop.local.md
/docs/plans/.cpm-*
```

and untracked both `.claude/ralph-loop.local.md` and the compact summary (327 deletions). Nothing in
the prompt asked for this — as with OBS-20, the loop noticed a property of its own output and fixed
it. Note it also ignored **ralph-loop's** state file, which is not CPM's to fix but is the same class
of mistake.

**The cleanup is one commit short.** `.cpm-progress-*.md` is still tracked at HEAD; `cpm:do` deleted
it from disk at the story boundary, so the pending deletion resolves on the next `git add -A`. And
untracking does not rewrite history — both files remain in `cd73346` and `29c4515` permanently.

**The CPM-side fix** is not a skill change: it is a line in whatever `.gitignore` guidance CPM gives
users, and CPM currently gives none. `cpm:ralph` is the skill that makes it load-bearing, because it
is the only one that commits without a human looking at the file list.

## OBS-22 — The loop survived an auto-compaction mid-run and kept its place

`docs/plans/.cpm-compact-summary-34e1eabd-….md` records:

```
**Captured**: 2026-07-28 13:20:13
**Trigger**: auto
```

So the ralph session hit automatic compaction during Story 3, roughly 35 minutes in. The PostCompact
hook wrote the summary, `session-start-compact.sh` re-injected it, and the loop continued — Story 3
finished and committed at 13:27, then it immediately went on to notice and fix the gitignore problem
(OBS-21).

No stall, no restarted story, no lost place in the epic. The "records **are** the state" design means
compaction costs the loop its conversation but not its position: phase and next story are re-derived
from the coverage roll-up and the epic docs on disk, both of which survive compaction untouched.
This is the property spec 45 is built on, observed under the real event rather than argued for.

## OBS-23 — ENV7's `[target]` tick is honest, and the loop falsified its own test harness to prove it

Story 4 ticked ENV7 (headless Chromium). This is the most demanding `[target]` row so far — it needs
a real browser binary, not just a composer package — so it was checked against the loop's own
transcript rather than accepted.

What the loop actually did, in order:

1. Probed for `Google Chrome.app` / `Chromium.app` and recorded the versions before choosing a driver.
2. `composer require --dev laravel/dusk` (8.6), `php artisan dusk:install`.
3. `php artisan dusk:chrome-driver --detect` — **because the installer's default ChromeDriver did not  
   match the installed Chrome.** The loop noticed the mismatch and pinned by detection.
4. Rewrote `DuskTestCase` to serve the application itself — claim a free port, migrate a scratch  
   database, shut down at exit — so `php artisan dusk` does not depend on someone having a server  
   running. Ambient-state dependence would have made the tick true only on this machine, today.
5. Ran the suite: **2 passed (5 assertions)**.
6. **Deliberately broke it** — the transcript shows a `1 failed, 1 passed` run under the note  
   *"proving dusk reports failure"* — then restored and re-ran to 2 passed.

Step 6 is the one that matters. A browser harness that silently no-ops passes every assertion written
against it; the tick would then be evidence of nothing. The loop tested the *oracle*, not just the
subject. The test file says so in a header comment, including why asserting on static text would have
been the weaker check.

This is the third instance of the same behaviour — OBS-20 (exported `DB_DATABASE` to disprove
`force="true"`), OBS-21 (caught its own session-state leak into git), and now this. The pattern is
consistent enough to call a property of the run rather than luck: **the loop tries to falsify its own
green results before recording them.**

## OBS-24 — Epic 01-01 closed; first requirements reach fully-verified

`01-01-epic-application-foundation.md` is `**Status**: Complete` — 4 of 4 stories, five commits
(`cd73346`, `8711186`, `29c4515`, `d0ca09f`, `be3e63b`).

Roll-up moved for the first time beyond zero verified:

```
SUMMARY  spec  46  0  2  44     exit 3
```

46 requirements, **0 untraced**, **2 fully verified**, 44 with rows outstanding. The two that closed
are the ones whose every row lives inside 01-01; requirements with rows in later epics stay open
until those land — which is the roll-up counting requirements rather than rows, working as designed.

Also visible in the epic header: the five **`**Autonomous gate**`** breadcrumbs recording that
`cpm:epics` ran its Step 2 / 3 / 3b / 3c / 4 gates without a human and what it decided at each. The
audit trail spec 45 asks for is present and legible.

Still iteration 2 of 100 with an entire epic delivered.

## OBS-25 — The loop caught a correctness trap the spec's own wording sets

Commit `df37c63` introduced `App\Money\Pence` — a `final readonly` value object with a private
constructor, no float constructor and no float accessor — plus `PenceCast`, which **throws** rather
than coerce when handed anything that is not a `Pence`:

> Accepting a bare number here would be the hole the value object exists to close: a float would
> round-trip through the column silently.

The interesting artefact is `tests/Support/MoneyPath.php`, which enforces FR7 ("no floating point
anywhere in the money path") by **tokenising the source with `token_get_all()`** rather than
grepping it. Its stated reason:

> FR7's prohibition is on floating point "anywhere in the money path", which a grep cannot check
> honestly: `/` appears in every doc comment, and `float` appears in prose. Tokenising the source
> separates operators from comments and strings, so the check can be strict without being noisy.

**And then the catch that matters.** Its list of float-returning functions includes `floor()`, with
this rationale:

> floor() is on the list deliberately. FR6 specifies a share as
> `floor(amount × weight ÷ total_weight)`, and writing that with PHP's floor() would route the money
> path through a float to reach an integer result. intdiv() is the integer equivalent and is what
> the formula means here.

The spec **tells the implementer to use floor**. In PHP, `floor()` returns a float even given
integers, so the literal reading of FR6 violates FR7 — and it violates it invisibly, because the
result is a whole number that looks correct until an amount exceeds 2^53 pence or a rounding mode
differs. The loop noticed that two requirements in the same spec contradict each other at the
language level, chose `intdiv()`, and wrote a test that will fail if anyone later takes the spec
literally.

That is not "tests pass". It is reading a specification as a claim about behaviour rather than a set
of instructions to transcribe — and it is the strongest single piece of evidence in this run that
spec mode is doing what it was designed to do.

## OBS-26 — A story dependency existed only in a task description, and the loop reordered rather than re-planned

First substantive (non-Status) epic edit of the run, in `01-02-epic-money-and-split-engine.md`:

> **Execution order: Story 3 before Story 2.** Both become unblocked when Story 1 lands, and Story 2
> is the lower number, but Task 2.4's own description says it "consumes the split rules from Story 3"
> and two of Story 2's criteria are about the rule resolving to share rows. Taking Story 2 first
> would mean either building the split rules inside it — duplicating Story 3 — or closing it with 2.4
> unfinished. Nothing about scope or criteria changes; this is execution order only, and the declared
> `**Blocked by**` fields are left as they are.

**The CPM-side finding**: `cpm:epics` declared both stories `**Blocked by**: Story 1`, but the real
dependency — Story 2 needs Story 3 — was recorded only inside a *task* description. `cpm:do`'s
hydration reads `**Blocked by**` at the **story** level and would have picked Story 2 first, exactly
as the loop says. Task-level dependencies are invisible to the ordering mechanism.

**The behaviour is right.** It did not edit `**Blocked by**` to match reality — that would have been
an autonomous re-plan, and re-planning is a judgement-heavy category `cpm:do` defers rather than
auto-applies. It changed only what it does next, and wrote down why, so the deviation from numeric
order is not a mystery to the next reader.

Worth carrying back: either `cpm:epics` should lift task-level dependencies into the story's
`**Blocked by**`, or `cpm:do` should read task descriptions when ordering. Today the gap is closed by
the executing agent noticing, which works here but is not a mechanism.

## OBS-27 — The `intdiv()` substitution needed a second-order fix, and got one

OBS-25 recorded the loop choosing `intdiv()` over `floor()` to keep FR6 out of the float path.
Commit `10674cf` shows that swap is not sufficient, and that the loop knew it:

```php
/**
 * Integer division that rounds towards negative infinity, as `floor` does.
 *
 * intdiv() truncates towards zero, which differs from floor for negative
 * results: intdiv(-7, 2) is -3 where floor(-7/2) is -4. …
 */
public static function floorDiv(int $dividend, int $divisor): int
```

`intdiv()` truncates toward zero; `floor()` rounds toward negative infinity. They agree on positive
operands and diverge on negative ones — so the obvious fix for OBS-25's trap introduces a different
bug, off by one pence, only on negative amounts. `IntegerMath::floorDiv` implements true floor
division in integers and `IntegerMathTest` pins the negative cases.

A naive reading of FR6 uses `floor()` and violates FR7. The obvious repair uses `intdiv()` and
violates FR6. The loop found both.

## OBS-28 — FR7's remainder rows are correctly left unticked, with a precondition test standing in

The split rules **deliberately under-allocate**. `SplitRuleTest` says so:

> `it('leaves the indivisible remainder unallocated for the remainder rule')`

FR7's remainder clause — *"added to the payer's own share, including when the payer is not among the
split participants"* — cannot be satisfied by a split rule, because a rule is handed the amount and
the participants and never learns who paid. It belongs one layer up. The coverage matrix agrees:
rows 15, 16, 18 and 19 (the remainder and sum-exactness criteria) are assigned to **Stories 4 and 5**
and are **unticked**, while row 13 (FR6's floor formula) is ticked against a concrete case
(1000 over weights 1:2:1 → 250/500/250).

What is notable is what went in *instead* of a premature tick — a property test asserting the
**precondition**:

```php
expect($total)->toBeLessThanOrEqual($amount->toInt(), "the {$name} rule over-allocated");
```

No rule may over-allocate, for any rule and any amount. That is the invariant which must hold before
a remainder rule can exist at all, it is checkable today, and it is not the same claim as
sum-equals-amount. Verifying the strongest checkable property rather than ticking the target one is
the distinction the whole coverage mechanism depends on, and the loop drew it unprompted.

## OBS-29 — FR7 delivered, including an edge case the spec does not mention

`ExpenseSplit::resolve()` (commit `fbfe3ce`) is where FR7 lands. Four decisions in 62 lines, each
with a stated reason:

1. **Payer must be on the trip** — throws otherwise. Distinct from "payer outside the *split set*",  
   which is legal and is FR7's named case.
2. **`$shares[$payerId] ?? Pence::zero()`** — creates the payer's row when they are outside the  
   split set. This is FR7's explicit clause, implemented rather than approximated.
3. **Negative remainder throws**, citing NFR3: *"fail loudly rather than store a ledger whose shares  
   exceed the expense they belong to."* Over-allocation is unrecoverable by an additive rule, so it  
   is refused instead of absorbed.
4. **Zero remainder adds no row** — *"Adding a zero row for a payer outside the split set would put  
   someone in the ledger who owes nothing on this expense."*

**Point 4 is not in the spec.** The obvious implementation applies `?? zero()->plus($remainder)`
unconditionally, and on an exact split with the payer outside the set that writes a £0.00 share row
for someone who owes nothing — which then surfaces in FR8's balances as a participant with a
zero position on an expense they were never part of. Nothing in FR7 forbids it; it is wrong anyway,
and the loop reasoned it out from what the ledger means rather than from what the spec said.

The rationale for the rule itself is written in human terms, not mechanical ones:

> …because a penny moved to whoever fronted the money is the least surprising answer when the group
> later checks the arithmetic by hand.

`ExpenseSplitTest` covers all four, plus the property *"sums to the expense amount exactly, for every
rule and every amount"*. Suite: **122 passed, 16,072 assertions** — the jump from 121 assertions to
16k is that property sweeping a real input space rather than three hand-picked examples.

## OBS-30 — FR11's must-NOT is enforced by an API that cannot express the violation

`App\Trips\TripToken` (commit `4044fb9`) implements FR11 — *"at least 128 bits from
`random_bytes()`, encoded URL-safely. No sequential IDs, no timestamps, no user-supplied entropy."*

The design move worth recording:

```php
/**
 * mint() takes no arguments. That is the enforcement of the must-NOT rather than
 * a stylistic choice — there is nothing to derive a token from.
 */
public static function mint(): self
```

The must-NOT forbids deriving a token from ids, timestamps or user input. A zero-argument factory
makes that **unrepresentable** rather than merely untested — the same move as `Pence` having no float
constructor (OBS-25). Both times the loop reached for "make the prohibited thing impossible to write"
over "add a test that would catch it".

**Three decisions the spec does not ask for, all correct:**

1. **32 bytes, not 16.** 256 bits against FR11's 128-bit floor, with the cost named: *"a longer URL,  
   which is paid once when the link is shared."*
2. **The raw token is never stored.** A `token_digest` column holds SHA-256; the migration comment  
   says *"The raw token is never a column."* FR11 governs generation only — storage is the loop's own  
   addition.
3. **SHA-256 rather than a password hash**, with the reasoning that separates understanding from  
   cargo-cult:

   > SHA-256 rather than a password hash because the column has to be indexed: lookup is by digest,  
   > and a salted hash cannot be looked up. The trade-off is acceptable because the input is 256 bits  
   > of uniform randomness, so there is no dictionary to run against it.

   Reaching for bcrypt/argon2 here is the common reflex and it breaks lookup outright. The loop  
   identified why the usual advice does not transfer, and why the property that makes it safe to  
   depart from it holds.

Also: `hash_equals()` for comparison, and **no `try`/`catch` around `random_bytes()`** — deliberate,
citing ENV4: *"no silent fallback … no weaker source to fall back to."* A catch here is how a CSPRNG
failure becomes a predictable token.

Tests pin each claim separately, including `it('is drawn from random_bytes and from nothing weaker')`
and `it('compares with hash_equals rather than a string comparison')` — assertions about the
*mechanism*, not just the output, which is the only way to catch a later refactor that keeps the
tests green while weakening the source.

Suite: **202 passed, 21,657 assertions.**

## OBS-31 — The loop found four of its own security tests were vacuous, fixed them, and built a scanner so it cannot recur

Commit `bf8301e`. From `tests/Unit/AssertionDisciplineTest.php`:

> A negated `toContain` with a trailing message reads like an assertion with an explanation attached.
> It is not: Pest takes every argument as a needle, and a negated expectation passes as soon as one
> of them is absent — so the message makes the check pass unconditionally. **Four of this suite's
> security checks were written that way, and none of them were testing anything.**
>
> The mistake is invisible on a green run, which is why it is worth a test rather than a note.

Two of the four, both removed in this commit, were **the FR11 assertions recorded in OBS-30**:

```php
- expect((string) $value)->not->toContain($token, "the raw token reached the {$column} column");
- expect($source)->not->toContain($weaker, "token generation must not reach for {$weaker}");
```

The first was the check that the raw token never reaches a database column. The second was the check
that token generation does not fall back to a weaker source than `random_bytes()`. Both passed
unconditionally, because the message string is never present in the haystack and a negated
`toContain` succeeds the moment any needle is absent. Replaced with `str_contains`, with the trap
named at the call site.

**Then it tested the scanner against itself:**

> `it('would catch the form it forbids')`
>
> The scan passes on a suite that happens to contain no such call, so on its own it cannot tell
> "none present" from "not looking".

It plants the forbidden form and confirms the scanner fires. Same instinct as OBS-23's deliberate
Dusk failure: **verify the oracle, not just the subject.** Third instance of the technique, after
`MoneyPath`'s tokeniser (OBS-25) and the Dusk falsification.

**`MethodSource` is the other half**, and its reasoning is correct in a way that is commonly got
wrong:

> Constant-time comparison is a property of control flow — what runs before the comparison, and
> whether anything returns before reaching it — so the checks built on this read the method's
> structure. **A timing measurement at test scale measures the machine it runs on, not the code.**

Timing-based tests for constant-time comparison are flaky and meaningless at unit scale. Reading the
token stream for early returns is the check that actually holds.

**Correction to OBS-30, and it is mine.** That entry assessed FR11's tests by reading their *names* —
`it('is drawn from random_bytes and from nothing weaker')` was among the vacuous four. The
implementation praise in OBS-30 stands (it was read from source), but the claim that the tests pinned
each property did not, for two of them. A test name is not evidence; the loop caught this and the
monitor did not.

Suite: **223 passed, 21,699 assertions.**

## OBS-32 — A recurring design move: make the invariant structural, not procedural

Three commits now show the same instinct, applied to three unrelated requirements. Each time the
loop had the choice between *testing that the bad thing does not happen* and *making the bad thing
unwritable*, and each time it took the second.

| Requirement | Procedural version (not taken) | What was built |
|---|---|---|
| FR7 — no floats in the money path | a test that greps for `float` | `Pence` has **no float constructor and no float accessor** |
| FR11 — no ids/timestamps/user input in a token | a test asserting the token is unpredictable | `TripToken::mint()` **takes no arguments** — nothing to derive from |
| FR12 — regenerating a link revokes the old one | invalidate sessions, then caches, then … | the digest is replaced; **revocation is a consequence, not a step** |

The third states the principle outright:

> Revocation of the old token is not a step here. It follows from the digest being replaced — the old
> token no longer hashes to what the row holds, so it stops resolving on every path at once,
> including sessions already exchanged from it. **A revocation implemented as a list of things to
> invalidate is a list that can be incomplete.**

That is the failure mode of every list-based revocation: each path is a separate thing to remember,
and the one nobody remembers is the vulnerability. The tests then check exactly the paths a list
would most likely miss — `it('revokes a session already exchanged from the old token')` and
`it('revokes an exchanged session on the Livewire endpoint too')`.

One more piece of precision in the same file: the update goes through the query builder rather than
the model, *"so the timestamps are left alone: 'trip data is unchanged' is asserted byte for byte, and
a touched `updated_at` is a changed byte."* The criterion says trip data is unchanged; an Eloquent
save would have touched `updated_at` and made that claim false while every obvious test still passed.

## OBS-33 — A completeness must-NOT tested against the route table, and the OBS-31 lesson carried forward

FR13's last row is a completeness claim — *"must NOT apply limits to only a subset of routes — every
token-accepting route is covered"* — which examples cannot discharge. `ThrottledRoutesTest` does
three things at once, each worth separating out:

**1. It reads the route registry rather than a list.**

> Read off the route table rather than from a list written here. A token-accepting route added later
> is covered by this check without anyone remembering to extend it — which is the failure the
> must-NOT describes.

Routes are selected by predicate (`{token}` in the URI, the `RequireTripSession` middleware, or the
Livewire update endpoint), so a route added next month is in scope automatically. Same principle as
OBS-32's revocation-by-consequence: no list means no list to forget.

**2. It guards against its own vacuous case.**

```php
// Guards the check itself: an empty set would satisfy the loop below.
expect($tokenAccepting->count())->toBeGreaterThanOrEqual(3);
```

A `foreach` over an empty collection passes trivially. This is the fourth time in the run the loop
has caught an oracle that could pass while testing nothing — after the Dusk falsification (OBS-23),
`MoneyPath`'s tokeniser (OBS-25), and `AssertionDisciplineTest`'s planted-form check (OBS-31).

**3. It applies OBS-31's lesson in new code, not just retroactively.**

```php
// in_array rather than toContain: Pest reads every argument as a needle, so
// the message would be asserted as one — loudly in this direction, silently
// in the negated one.
```

The vacuous-assertion trap was found and fixed two commits earlier. Here it is being *avoided in
fresh code*, with the reasoning restated at the call site — and with a distinction the original fix
did not need to make: the bug is **loud** in the positive direction (the message becomes a needle
that is not found, so the assertion fails) and **silent** in the negated one. The lesson survived the
story boundary and got sharper crossing it.

Suite: **274 passed, 21,861 assertions.**

## OBS-34 — The loop proved two of the spec's own requirements are jointly unsatisfiable at their stated bounds

Commit `439ea03`. FR14 asks for *"a documented brute-force calculation shows expected guesses to
first valid hit exceeds 10³⁰ at the enforced rate limit."*

The naive discharge is a markdown file with a number in it, correct on the day it is written and
stale thereafter. What was built instead:

- **`App\Trips\BruteForceResistance`** computes the figure from the two values that decide it,  
  **read from the code**, not restated: token length from `TripToken`, rate from `config/trips.php`.  
  *"change the token length or the per-IP limit and this answer changes with them, which is the point  
  of computing it instead of writing it down."*
- **`docs/security/brute-force-resistance.md`** — the narrative, cross-referenced to the class and the  
  test. The first documentation directory the loop created unprompted.
- Everything in log₁₀, because 2²⁵⁶ *"no integer type here holds and which would round to infinity as  
  a float"*.
- The threat model is right: success probability is `trips / space`, not `1 / space` — *"every one of  
  them is a valid target, so more trips make the attacker's odds better"* — and the property is  
  asserted at 1, 10⁶, 10⁹ and `PHP_INT_MAX` live trips, with the note that **the largest figure is the  
  weakest case, not the strongest.**

**And then the finding that matters.** One test is named
`it('needs more than FR11\'s floor to clear FR14\'s bar at a billion trips')`:

> FR11 asks for at least 128 bits, and at exactly that floor the expected guesses fall to 10^29.5
> once a billion trips are live — under FR14's 10^30. **The two requirements are not independent, and
> 256 bits is what makes them agree at any trip count this deployment could reach.**

The arithmetic: 128 × log₁₀2 = 38.53; minus log₁₀(10⁹) = 9; giving 29.53 — below FR14's 30. **A
compliant implementation that takes FR11 at its word fails FR14 at scale.** The spec states both
bounds as independent minima; they are not.

The loop found it, chose 256 bits, and **wrote a test that proves the contradiction** — asserting
`$log10At128Bits(1_000_000_000)` is *less than* 30. The failing case is pinned in the suite so nobody
can later "optimise" the token down to the spec's stated floor without a red test explaining why not.

This is the third spec-level contradiction found in the run — after `floor()`-vs-no-floats (OBS-25)
and `[target]` conflating host with dev-environment claims (OBS-19) — and the most consequential,
because both sides are security requirements and the naive reading is the insecure one.

Suite: **302 passed.**

## OBS-35 — Oracle verification reaches five instances; it is a property of the run, not a coincidence

Commit `140d9f0` adds a real axe-core scan — the npm package, injected through `Tests\Support\Axe`,
run inside Dusk against the rendered page, asserting zero WCAG 2.2 AA violations, **including on a
Livewire-updated view** rather than only the initial render.

And it checks the scanner works:

```php
// An image with no alternative text is planted, found, and removed.
$browser->driver->executeScript('… img.id = "planted-violation" … document.body.appendChild(img);');
$ids = array_column(Axe::violations($browser), 'id');
expect($ids)->toContain('image-alt');
```

A scan reporting zero violations on a clean page is indistinguishable from a scan that never ran.

**The full tally of the same instinct, across five unrelated subjects:**

| # | Subject | How the oracle was checked |
|---|---|---|
| 1 | Dusk browser harness (OBS-23) | deliberately broke a test, confirmed it reported failure |
| 2 | Float ban in the money path (OBS-25) | tokenised rather than grepped, so comments could not produce false passes |
| 3 | Vacuous-assertion scanner (OBS-31) | planted the forbidden form, confirmed the scanner fired |
| 4 | Route-coverage completeness (OBS-33) | asserted the matched set is non-empty, since a `foreach` over nothing passes |
| 5 | Accessibility scan (this) | planted an `image-alt` violation, confirmed axe reported it |

Five instances, five different failure modes, none prompted by the spec or the skill. The run's
distinguishing property is not that it writes tests — it is that **it does not trust a green result
until it has seen the check fail on purpose.**

**The scan also did work rather than rubber-stamping.** Blade changes in the same commit:
checkbox targets `h-4 w-4` → `h-6 w-6`, labels gaining `min-h-11`. That is WCAG 2.2's target-size
minimum being enforced — and it is the mechanical half of NFR5's one-handed-phone criterion, the row
whose `[manual]` justification said *"the scans above cover the mechanical half"*. The justification
was not a hand-wave; the scan it refers to exists and changed the markup.

## OBS-36 — The integration story earned its place: a defect no per-story test could have caught

Commit `dd36207`, titled *"Join the interface stories up, and fix what that found"*, is `cpm:epics`
Step 3c's integration story doing exactly what it exists for.

**The defect.** Three Livewire components — `ManageParticipants`, `ExpenseLedger`, `TripLedger` —
each passed its own story's criteria. On the same page they did not compose: a participant added in
one did not appear in another's payer list or split inputs. Every component was correct; the page was
broken.

**The fix**, applied to all three:

```php
$this->dispatch('trip-changed');            // from the mutating components

#[On('trip-changed')]
public function reread(): void {}           // in the ones that must re-render
```

with the edge case named:

> A participant added next door has to appear in the payer list and in the split inputs, and **until
> the first one is added there is no form here at all.**

So the empty-state transition — adding the *first* participant, which must make a form appear that
was not previously rendered — is the sharpest version of the bug, and it is called out rather than
discovered later.

**Why this is evidence about CPM rather than about this app.** The defect is unreachable from any
single story's acceptance criteria, by construction: each story's criteria were met. It is only
visible when two stories' outputs occupy the same page. A breakdown that verified story by story and
stopped would have shipped it with a fully-ticked coverage matrix.

Step 3c is easy to read as ceremony when every story is already tested. This is the counter-example,
found autonomously, in the first epic where more than one component shares a screen.

## OBS-37 — `active: false` in the ralph state file is a no-op, and the loop found it the hard way

The loop's final iteration reported:

> One thing I got wrong last iteration: I set `active: false` in `.claude/ralph-loop.local.md`
> expecting that to end the loop. The stop hook does not read that field — it continues while the
> state file exists, until the promise is emitted or the iteration cap is hit.

Confirmed against the hook source:

```bash
RALPH_STATE_FILE=".claude/ralph-loop.local.md"
if [[ ! -f "$RALPH_STATE_FILE" ]]; then
  exit 0
fi
```

Termination is tested by **file existence**. The only occurrences of the string `active` in
`stop-hook.sh` are comments (`# Check if ralph-loop is active`). The `active:` key is written into
the frontmatter at launch, is read by nothing, and changing it has no effect.

**Why it matters more than a cosmetic defect.** The field is named exactly as a kill switch would
be, sits in a file a user is invited to inspect, and fails silently — setting it false produces no
error and no change in behaviour, so the operator believes the loop is winding down while it
continues to the iteration cap. The loop tried the obvious thing, observed it not working, read the
hook, and used the real termination path.

**The fix is one of two, not both**: have the hook honour `active: false`, or drop the field from the
template. Leaving a no-op named `active` in a state file is the trap.

## OBS-38 — The run ended by refusing the promise, which is the outcome spec 45 wanted

Final state, every figure verified independently rather than read from the loop's report:

| | |
|---|---|
| Roll-up | `SUMMARY spec 46 0 27 19`, **exit 3** |
| Coverage rows | 114 of 133 verified |
| Unverified | **18 `[target]` + 1 `[manual]` = 19** |
| Automatable rows left unticked | **zero** |
| Pest | 450 passed, 25,864 assertions |
| Dusk | 12 passed, real Chromium |
| Commits | 24, one per completed story, none pushed |
| Epics | 01-01…01-06 Complete; 01-07 Stories 1–2 Complete, 3–5 target-only |
| `SPEC_DELIVERED` | **never emitted** |

The last line is the result. A loop whose only exit condition is a promise it cannot honestly make
had every incentive to make it anyway — the phrasing of the completion clause, 96 unused iterations,
and its own report describing the work as finished. It withheld the promise, wrote down which rows it
was not entitled to assess and what access each would need, and terminated by removing its own state
file.

The zero on the fourth row is what makes the rest meaningful: it did not stop early and call the
remainder target-only. Every criterion an automated check could close was closed.
