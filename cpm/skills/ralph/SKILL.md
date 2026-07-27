---
name: ralph
description: Autonomous multi-epic execution via the Ralph Wiggum plugin. Discovers epics, generates a Ralph-compatible prompt that wraps /cpm:do with autonomous behaviour overrides, validates prerequisites, and launches the loop. Triggers on "/cpm:ralph".
---

# Autonomous Multi-Epic Execution

Generate and launch a Ralph Wiggum loop that wraps `/cpm:do` for autonomous, unsupervised multi-epic execution. The skill discovers epics, validates prerequisites, assembles a self-contained prompt with autonomous behaviour overrides, and presents it for review before launching.

## Input

Parse `$ARGUMENTS` for:

1. **Epic paths** — one or more explicit paths (e.g. `docs/epics/23-epic-*.md docs/epics/24-epic-*.md`) or a range (e.g. `23 through 26`).
2. **A spec path** — a single path under `docs/specifications/` (e.g. `docs/specifications/45-spec-delivery-autonomy.md`), which selects **spec mode**: the loop generates the epics for that spec itself before working them.
3. **`--max-iterations N`** — maximum Ralph loop iterations (default: 50).
4. **`--story-filter`** — include/exclude specific stories (e.g. `--story-filter "1-3"` or `--story-filter "!4"`).
5. **`--dry-run`** — generate and display the prompt without launching.

**The mode comes from the path, not from a flag.** A path under `docs/specifications/` is spec mode; epic paths or a range are epic mode; no path at all is auto-discovery. There is no `--spec` flag and no second skill — the argument the caller already types carries the mode, so an invocation that worked before spec mode existed keeps working without being rewritten to declare which mode it meant. Step 1a resolves this.

If no path of any kind is provided, auto-discover all incomplete epics (see Process Step 1). The test is *"is there a path, and which directory does it point into"* rather than *"are there epic paths"* — a spec path **is** a path, so it selects its mode rather than falling through to auto-discovery.

## Process

### Stale-Progress Check (Startup)

Follow the shared **Stale-Progress Check** procedure (from the CPM Shared Skill Conventions loaded at session start).

### Step 1: Pre-flight Validation

Before generating the prompt, validate all prerequisites.

#### 1a. Epic Discovery

**Resolve the mode first — it decides what discovery is looking for.** Classify the paths in the arguments by the directory they sit in, never by a flag and never by reading the file:

| Argument shape | `{mode}` | What discovery resolves |
|---|---|---|
| One or more paths under `docs/epics/`, or a range | `epic` | the named epic files |
| A single path under `docs/specifications/` | `spec` | the incomplete epics naming that spec as their source — possibly none |
| No path at all | `epic` | every incomplete epic |

Store the result as `{mode}` and, in spec mode, the spec path as `{spec_path}`. Both are fixed here and read by later steps rather than re-derived from the arguments, so the mode is decided exactly once. A second path under `docs/specifications/`, or a spec path mixed with epic paths, is an error: report the arguments and stop, rather than guessing which one was meant.

If explicit epic paths were provided in arguments, resolve them (expand globs). If a spec path was provided, run the same discovery below and then keep only the epics whose `**Source spec**` field names `{spec_path}`, comparing basenames as `coverage-rollup.sh` does. Otherwise, auto-discover:

1. **Glob** `docs/epics/*-epic-*.md` to find all epic files.
2. Use Grep to search for `**Status**:` across the matched files, then filter to epics that are not `Complete`/`Done` (`Done` reads as a synonym for `Complete`) and not retired (`Superseded` / `Withdrawn` — terminal, user-set statuses for work no longer needed; a retired epic has nothing to run). Use Grep and Read tools directly (Bash loops with shell variables lose context).
3. If no runnable epics found (all `Complete` or retired), **branch on `{mode}`**:
   - **Epic mode** — report to the user and stop: "No incomplete epics found. Nothing to run." Unchanged; this is what the three shapes that predate spec mode still reach.
   - **Spec mode** — do **not** stop, and do not emit that message. Zero epics is spec mode's starting state rather than a failure: the run's first phase is what writes them. Report "No epics for `{spec_path}` yet — phase 1 generates them." and continue pre-flight with an empty resolved list.
4. Present the discovered epics and confirm with AskUserQuestion. In spec mode present `{spec_path}` alongside them, since the epics found are the run's starting position and the spec is what it is measured against — with none found there is still something to confirm.

For range-style references (e.g. `23 through 26`), expand to matching files: `docs/epics/23-epic-*.md`, `docs/epics/24-epic-*.md`, etc.

**Every input shape resolves to one epic list**, and the prompt's variables are derived from that list rather than from the arguments that produced it:

| Variable | Value |
|---|---|
| `{mode}` | `epic` or `spec`, from the mode resolution above |
| `{spec_path}` | the resolved spec path in spec mode; unset in epic mode |
| `{epic_count}` | the number of resolved epic files |
| `{epic_range}` | a human-readable label for the set (e.g. `23 through 26`, or the epic names when there is no range) |
| `{epic_glob}` | the resolved epic **paths**, space separated, exactly as they will be passed to a command |

**The three epic-mode shapes resolve to the epics the run will work; spec mode resolves to the epics that exist so far**, which at iteration 1 is normally none. That list is a starting position rather than the run's scope, so nothing downstream may read a resolved list as "every epic this run will touch" — in spec mode the run writes the rest of it.

`{epic_glob}` is a path list, not a pattern — every shape resolves to files before the prompt is assembled, so the loop never re-expands a glob against a directory that may have changed since launch. It is passed verbatim to `coverage-rollup.sh --epic` in the completion check (Step 2), which is why its form is fixed here rather than left to the assembly step — in epic mode. **In spec mode that list can be empty at launch, so `--epic {epic_glob}` would have nothing to pass**; spec mode's completion check asks a different question (*are the spec's requirements traced*), and the prompt that asks it is not built yet, so Step 2 still assembles epic mode's template today. Recorded here rather than left for a reader to hit. CPM epic filenames are numbered kebab-case and contain no spaces, so a space-separated list is unambiguous; a path containing a space would need quoting and does not occur.

#### 1b. Strip `[plan]` Tags

Formal plan mode (`EnterPlanMode`) creates an interactive approval gate that stalls autonomous execution. Strip `[plan]` tags from epic docs before launching the loop so `/cpm:do` uses inline planning for all stories.

**Ordering**: this step runs after epic discovery and before any other pre-flight checks — autonomous execution depends on it.

1. For each resolved epic path, use the Read tool to read the file. Scan the content for any heading line (lines starting with `##` or `###`) that contains the literal text `[plan]`. Use Read for this — reading each file directly avoids regex escaping issues with square brackets in Grep.
2. For each heading that contains `[plan]`, use the Edit tool to remove the `[plan]` tag and any trailing whitespace it leaves behind (e.g. `## Set up OAuth integration [plan]` → `## Set up OAuth integration`).
3. Track which stories were modified. Log a line per stripped tag for inclusion in the execution log: "Stripped `[plan]` from Story {N}: {heading text}".
4. If no `[plan]` tags are found, skip silently.

#### 1c. Ralph Stop Hook Detection

A ralph loop plugin's stop hook is the only external dependency — it intercepts session exit and feeds the prompt back to continue the loop. `cpm:ralph` writes the state file directly (no dependency on the setup script).

**Two plugins provide that hook and CPM works with either.** `ralph-loop` (Anthropic) is the maintained line; `ralph-wiggum` is the original it forked from. They install the same hook at the same relative path under different plugin names, so neither name may be treated as *the* dependency — a check written against one reports "not installed" on a machine running the other.

1. Check if a ralph stop hook is registered by scanning the session's available hooks for a "Stop" hook referencing `ralph-loop`, `ralph-wiggum`, or `stop-hook.sh`.
2. If not detected, warn the user: "No ralph stop hook detected. The loop mechanism requires either the `ralph-loop` or `ralph-wiggum` plugin — without the stop hook, writing the state file will have no effect. Install one from the Claude Code marketplace; `ralph-loop` is the maintained one." Use AskUserQuestion with options: "Continue anyway" or "Stop".
3. **Probe which direction the hook fails in**: resolve the plugin's `hooks/lib/ralph-hook-probe.sh` to an absolute path, run `bash <that path>`, and branch on its exit code. Unlike `{rollup_script}` (Step 1f) this path is never interpolated into the prompt — the probe answers a question about launching, so it runs once here and the loop never sees it. `0` — the hook fails closed; continue pre-flight without comment. `2` — no hook on disk; fold into the warning above rather than reporting twice. `1` — the probe could not run; say so and let the user decide, since an unrun probe is not a pass. `3` — **a hook fails open**: report "The installed stop hook deletes the loop's state file on a normal turn shape and exits 0. An unattended run would end silently and look like a clean finish." Name the hook the probe reported, since with both plugins enabled the safe one is not the one that matters. Use AskUserQuestion with "Patch or switch plugin first (recommended)" and "Arm the loop anyway".

**Both plugins enabled is a real configuration, and the dangerous hook wins.** Two registered Stop hooks both fire on the same session, and the state file only has to be deleted by one of them for the loop to die. The probe therefore runs *every* hook it finds and lets a single fails-open verdict decide, rather than stopping at the first one that passes.

**Registration is not the property that matters.** Step 2 above has been in this skill since the beginning and it passed throughout a live run in which the hook deleted the state file at the first iteration boundary. The hook was installed and registered the whole time; what it did on a turn ending in a tool call is a different question, and the only way to ask it is to run the hook. That is what step 3 does — it builds a state file and a two-record transcript whose last assistant record is a bare tool call, runs the real hook against them in a scratch directory, and checks whether the state file survived.

**Why this is a behavioural probe and not a grep of the hook's source.** Reading the hook for a known-bad line pins CPM to one vendor's wording, passes the moment upstream rephrases it, and still says nothing about what the hook does. It would also have to be updated for each new way of getting this wrong. Running it answers the question directly and keeps working across versions and forks.

**Why it is checked at every launch rather than once.** The hook lives in the plugin cache, which is overwritten on update. A machine where this was fixed by hand is one `/plugin update` away from being a machine where it is not, and nothing announces that. The failure it guards against is specifically the silent one — a run that ends with no promise, no error and no state file is indistinguishable from one that finished — so the check has to be cheap enough to repeat, and it is: one subprocess against a scratch directory.

**Permissions note**: The loop will pause on permission denials at runtime; the stop hook re-invokes after the user grants them. To avoid mid-loop stalls, users can pre-add common Bash permissions (`Bash(git:*)`, `Bash(bash:*)`, `Bash(find:*)`, `Bash(grep:*)`) to `~/.claude/settings.json` before launching.

#### 1d. Test Runner Discovery

Discover the project's test runner for inclusion in the generated prompt:

1. Check project config files (`composer.json`, `package.json`, `Makefile`, `pyproject.toml`, `Cargo.toml`) for test commands.
2. If found, report: "Discovered test runner: {command}. This will be referenced in the generated prompt."
3. If not found, note: "No test runner discovered. The generated prompt will instruct `/cpm:do` to discover one at runtime."

#### 1e. Resume Detection

Check for evidence of a previous Ralph run:

1. **Glob** `docs/plans/ralph-log-*.md` for existing execution logs.
2. If an execution log exists, read it and summarise the state: which epics completed, which are in progress, any skipped tasks.
3. Use Grep to check the target epic docs' `**Status**:` fields to confirm the current state. Use Grep and Read tools directly.
4. If a previous run is detected, present the state to the user with AskUserQuestion: "Found a previous Ralph run. {N} epics completed, {M} remaining. Resume from where it left off?" Options: "Resume" or "Start fresh (ignore previous state)".

#### 1f. Roll-Up Script Resolution

The generated prompt gates its completion promise on `coverage-rollup.sh`'s exit code, so the path to that script has to be in the prompt as an **absolute path resolved here**, not as a variable the loop expands later.

1. Resolve the plugin's `hooks/lib/coverage-rollup.sh` to an absolute path and store it as `{rollup_script}`.
2. Confirm the file is readable. If it is not, warn the user: "The coverage roll-up script was not found at {path}. The loop will run, but its completion promise will not be script-backed — it would fall back to the model's own judgement, which is what FR8 exists to remove." Use AskUserQuestion with options: "Continue anyway" or "Stop".

**Why resolved here rather than written as `${CLAUDE_PLUGIN_ROOT}`**: the prompt is fed back to the model as a plain user turn by the stop hook, not executed inside a skill, so a plugin-relative variable is not guaranteed to be set when the completion check runs — and an unset one expands to a bare `/hooks/lib/coverage-rollup.sh`, which exists nowhere. That is spec 43's defect exactly: a path built from a variable that is set for hooks and not for the call that uses it, failing silently. Interpolating the resolved path keeps the prompt self-contained, which is what every other `{...}` in the template already does.

### Step 2: Prompt Assembly

Assemble the ralph-loop prompt as plain text — no markdown, code fences, backticks, or XML tags (the stop hook feeds the prompt back verbatim on each iteration). Interpolate these variables into the template:

- `{epic_count}`, `{epic_range}`, `{epic_glob}` — from Step 1a, which defines each; `{epic_glob}` is a space-separated path list, not a pattern
- `{rollup_script}` — the absolute path resolved in Step 1f
- `{max_iterations}` — from arguments or default (50)
- `{story_filter_clause}`, `{test_runner_clause}`, `{resume_clause}` — include when applicable, omit otherwise
- `{task_budget_clause}` — "Task budget: {N} tasks, estimate ~2000 tokens per task." Count `###` task headings in target epic docs.
- `{completion_promise}` — `ALL_EPICS_COMPLETE` in epic mode, `SPEC_DELIVERED` in spec mode. Taken from `{mode}` (Step 1a) and fixed for the run; it is written into the state file's frontmatter in Step 3 and is the same literal string the prompt's completion clause tells the model to emit.

#### One promise per mode, fixed at launch

**The tag differs by mode and nobody is asked which one to use** (FR10). `completion_promise` is per-run frontmatter, so the two modes can name different achievements without a choice existing at any point: `{mode}` is resolved once in Step 1a, and the promise follows from it. That is what preserves the argument for a single promise — the objection to two tags was that an *available choice* lets the weaker path survive, not that two strings are one too many. `ALL_EPICS_COMPLETE` at the end of a spec-mode run names the wrong achievement in a log read by someone who was not there.

**Evidence goes beside the tag, never inside it.** The stop hook compares the `<promise>` tag's contents to `completion_promise` with literal string equality after whitespace normalisation, so a tag carrying counts, a summary or a file list never matches, and the loop runs to its iteration cap on finished work. Both completion clauses put their coverage line on its own line next to the promise for exactly this reason. Spec 44's AD4 assumed the tag could carry its evidence; it cannot, and this is the second spec to say so.

#### The phase predicate

**In spec mode the phase judgement is a reading of `coverage-rollup.sh`'s records, and of nothing else** (AD1). The loop runs `bash {rollup_script} --spec {spec_path} --verdict` and takes two things from that one run: its exit code, and the `SUMMARY` record's `untraced` field. Phase 1 — generating the epics — is over when that field reads `0`; phase 2 — working them — is over when the run exits `0`, which is the script's own statement that no row is unverified. There is no marker file and no phase written down anywhere: the records **are** the state, so a run that resumes mid-flight re-reads its position instead of remembering it.

**A phase that cannot make progress stops; it does not repeat.** Exit `4` is the only code that sends the loop into `/cpm:epics`, because it is the only one meaning *no matrix names this spec yet*. An untraced count above zero on any other code means `cpm:epics` has already run and what it wrote does not cover the spec — a second run cannot fix that, and would actively make it worse: sub-numbers are assigned `max + 1`, so each run writes a **fresh** set of epic docs rather than completing the set already there. The first live spec-mode run generated a new set every iteration until the cap. Phase 2 carries the mirror rule: its exit-`3` branch keeps working only while an epic still has unfinished work, since another pass over completed epics cannot change the verdict.

This is a liveness rule, not a phase-semantics change: `untraced == 0` still ends phase 1. What changed is what happens when it does not — the loop reports what is missing and stops, rather than repeating a step whose output it has already seen.

**The loop relays; it does not compute.** It names the fields it read and repeats their values verbatim — it never counts rows, sums a column, or decides for itself that a requirement is traced or a row verified. Those judgements exist in exactly one place (NFR2), and it is the same rule the epic-mode completion clause already states as *never work that verdict out yourself from the records*.

**Phase is never inferred from the epic files.** That `docs/epics/` holds four matching files, or none, says nothing about which phase the run is in: a partially-generated set looks exactly like a complete one on disk, and at iteration 1 spec mode's epic list is legitimately empty (Step 1a). The count of files is not consulted, and `{epic_count}` is a label for the user rather than an input to this decision.

**Template** (written into `.claude/ralph-loop.local.md` body; use `--` for dashes; `ALL_EPICS_COMPLETE` must match `completion_promise` frontmatter):

**Length: 2858 characters**, measured on the template line below before interpolation — the assembled prompt is longer, since the `{...}` placeholders expand at runtime. This is a *measurement*, not a target: every clause is an override without which the loop stalls or drifts, so the figure is not something to cut toward. It was allowed to read "around 1100" against an actual 1,477 for long enough that the drift is now what the number is for. `test-ralph-autonomous-wiring.sh` asserts this figure against the line's actual length, so any edit to the template fails the suite until the figure is updated here — it did exactly that when epic 44-03 added the completion-check clause, which is the point of stating a number. Keep new clauses to a sentence.

```
Run /cpm:do on epics {epic_range} sequentially ({epic_glob}). Continue to each next epic automatically. Make all decisions autonomously -- choose the most reasonable option for every AskUserQuestion. Use inline planning for all stories. Task complete means: all tagged criteria ([unit]/[integration]/[feature]) have passing test results, and all [manual] criteria have self-assessment lines in the progress file. A failure (for the 3-strike skip rule) is a test command exit code != 0 after a code change attempt -- tool errors and permission denials are retries, not failures. If acceptance criteria are ambiguous and completion cannot be determined, mark the story Blocked -- criteria ambiguous and continue to the next story. At the do retro consumption gate, do not block -- branch by category: auto-apply safe categories (codebase discoveries, patterns worth reusing), recording Retro applied: {nn} {category} applied (autonomous, safe-category) -- {what it did} and carrying each as context; defer the rest (scope surprises, criteria gaps, complexity underestimates, testing gaps) as Retro applied: {nn} {category} deferred (autonomous run, unreviewed); smooth deliveries informational; never auto-retire. List both applied and deferred observations in the run summary. At the do Change Type Decision gate, do not block and do not pick one of its options -- take do's autonomous branch: inline edit, retro observation, or amend the open epic doc so later stories inherit the fix; never /cpm:pivot. Amend only on a citable contradiction, and record a Pivot deferred breadcrumb for each artefact left behind. Report amendments separately from the deferred observations. If a cpm:epics gate is reached, do not block -- take cpm:epics' Autonomous Mode branch, and never restate its rules here. Commit after each completed story. Keep all commits local.{story_filter_clause}{test_runner_clause}{task_budget_clause}{resume_clause} When the last specified epic completes, run bash {rollup_script} --epic {epic_glob} --verdict and let its exit code decide: on 0, print one line reading COVERAGE: N of M rows marked verified across K matrices -- aggregation, not verification, since every mark was placed by cpm:do on its own work, and it counts rows in these epics, not requirements in a spec, so it cannot say a spec is delivered -- then output ALL_EPICS_COMPLETE; on 3, do not output it, name the unverified rows the script emitted and keep working; on any other code, do not output it and say the check could not run. Never work that verdict out yourself from the records, and never output ALL_EPICS_COMPLETE without having run that command in the same turn. Put the counts on their own line beside the promise, never inside the promise tag the stop hook matches -- it compares that text exactly, so anything added inside it stops the loop from ever ending.
```

#### Spec mode's two phases

**Spec mode assembles the same template with two sentences swapped, not a second template.** Every autonomy rule in the line above applies unchanged in spec mode — they are about how `cpm:do` behaves without a human, which the mode does not alter — so they exist in one copy and are substituted into rather than restated. Assemble spec mode's prompt from the template above with exactly two replacements:

1. Replace the **opening sentence** — the first sentence of the template, the one naming `{epic_range}` and `{epic_glob}`, together with the "continue automatically" sentence after it — with the **phase clause** below.
2. Replace the **completion clause** — the final sentence group, the one gating the promise on the roll-up's exit code — with the spec-mode completion clause (Task 3.2).

Both boundaries are described rather than quoted. Quoting them here would put a second copy of the template's own opening in the file, and four suites locate the template by grepping for that sentence — a second copy is not a documentation flaw but a broken extractor, which is how this paragraph came to be worded this way.

**Phase clause** (spec mode; **1258 characters**, measured on the block below before interpolation and asserted by `test-ralph-two-phase-prompt.sh`):

```
Work spec {spec_path} to completion. This run has two phases and you re-check which one you are in at the start of every iteration: run bash {rollup_script} --spec {spec_path} --verdict, then read the SUMMARY record's untraced field and the exit code. Exit 1 or 2 means the check could not run: say so and stop, and never read either as phase 1 not started. Exit 4 means phase 1 and no epics exist for this spec yet: run /cpm:epics on {spec_path}, taking cpm:epics' Autonomous Mode branch, and end the iteration there. An untraced count of 0 means phase 2. An untraced count that is not 0 on any other code means /cpm:epics has already run and what it wrote does not cover the spec: name those requirements and stop, and never run /cpm:epics twice in one run, since a second run writes a fresh set of epics instead of completing the set already there. Before the first /cpm:do of phase 2, strip [plan] tags from the epic docs this run generated, by the rule ralph pre-flight step 1b applies: remove the tag from any story heading carrying it and log one line per strip, touching no epic doc this run did not write. In phase 2, run /cpm:do on every epic doc naming {spec_path} as its source spec, in filename order, continuing to each next epic automatically.
```

**Completion clause** (spec mode; **991 characters**, measured on the block below before interpolation and asserted by the same suite):

```
When phase 2 has no epic left to work, run bash {rollup_script} --spec {spec_path} --verdict and let its exit code decide: on 0, print one line reading COVERAGE: N of M rows marked verified across K matrices, R of R requirements traced -- aggregation of the marks cpm:do placed on its own work, not independent verification -- then output SPEC_DELIVERED; on 3, do not output it, name the untraced requirements and the unverified rows the script emitted, and keep working only while an epic still has unfinished work, stopping otherwise since another pass over epics that are already complete cannot change the verdict; on 4, do not output it and go back to phase 1, since no matrix names this spec yet; on any other code, do not output it and say the check could not run. Never work that verdict out yourself from the records, and never output SPEC_DELIVERED without having run that command in the same turn. Put the counts on their own line beside the promise, never inside the promise tag.
```

**Four codes, and the two that must not collapse.** In the completion clause `3` and `4` both mean *do not promise yet*, and answering them the same way would be the easy edit — but they resume at different phases, so the clause names them separately. `1` and `2` mean *stop*, and reading either as `4` would send a loop that cannot read its own inputs into generating epics against a spec it never parsed. Spec 44's failure is the reason this is written as four branches rather than "0 means done, anything else means continue": a branch on a code the script never returns reads perfectly and never fires, so Story 5 runs the command the clause names and compares.

**The same code means different things in the two clauses, deliberately.** In the phase clause, exit `3` with untraced work means *`cpm:epics` has had its turn and fell short* — stop. In the completion clause it means *rows remain unverified* — keep working, while there is work left to do. Both readings are about what the next action could achieve, which is the only question a loop with no memory can usefully ask.

**Fail closed** (NFR1). Every branch above except `0` leaves the promise unemitted, and the `any other code` catch-all makes that the default for codes that do not exist yet rather than a list to be kept current. An unreadable spec, a missing script, a permission error and a code added next year all reach the same place: no promise, and a line saying the check could not run.

**What spec mode costs.** Substituting both clauses gives an assembled spec-mode prompt of **4,077 characters** — the template's 2,858 less the 103-character opening and the 927-character completion clause it replaces, plus the two blocks above. AD3 estimated "roughly 3,400" for carrying both phases; the first assembly came in at 3,656 and the liveness guards took it past the estimate to this figure. That overrun is recorded rather than corrected: the guards were bought with a live run that burned its whole iteration cap generating epic docs, which is a worse cost than 421 characters. It is stated here because the epic-mode figure a suite asserts is a *different* number, and a reader who checks only that one would conclude the two-phase prompt was free.

**Why the phase is re-read every iteration rather than carried.** The loop has no memory between iterations beyond the state file, which the stop hook rewrites only to advance `iteration:` (AD3). Reading the phase from the records each time is therefore not a cost but the only honest option — and it is what makes a resumed run correct, since the records describe the epics that exist now rather than the ones that existed at launch.

**Phase 1 is never "done" on its own** (FR6). It ends when the *next* check reports 0 untraced, which is a fact about the epics `cpm:epics` just wrote — so the clause ends the iteration rather than declaring anything, and the completion tag is unreachable from inside it. A spec with no epics reports 0 untraced only when there are no requirements to be untraced; that case exits 4, which is why 4 routes to the generation step rather than to phase 2 or to the failure branch.

**What a non-zero untraced count is evidence of depends on whether epics exist.** Before `cpm:epics` runs there are no matrices, the script exits 4, and untraced is unmeasurable — nothing to compare rows against. After it runs, an untraced requirement is evidence about the *epics*, not about the phase: `cpm:epics` is not obliged to cover everything the spec lists — its own cross-epic gap check blocks on some requirements and merely warns on others — so a count that never reaches 0 is a possible and legitimate outcome of a phase 1 that finished properly. Treating it as "phase 1 unfinished" is what made the first live run repeat generation forever, and it is why exit 4 — not the count — is what sends the loop into `/cpm:epics`.

**What the completion line measures, and what it cannot.** The loop runs `coverage-rollup.sh` in **epic scope**, so the number it prints is rows marked verified out of rows present, across the matrices for the epics it was given. Every one of those `✓` marks was placed by `cpm:do` on its own work, which is why the line says **aggregation, not verification**: it reports what this run claimed, counted up, and adds no independent evidence. A wall of green means every row was marked, not that anything works.

The measurement that would discriminate is the **untraced count** — requirements in a spec with no matrix row anywhere claiming them — and epic scope cannot produce it, because it has no requirement list to compare against. That is `--spec` scope's measurement, which `cpm:status` presents and which spec mode's phase predicate reads directly (see *The phase predicate* above); **epic mode has no spec-scope promise**, and gains none by counting its rows more carefully. So a passing completion line here means "the epics I was pointed at have no unverified rows left", never "the spec is delivered". A spec with a requirement no epic ever covered produces the same clean line.

### Step 3: State File Write and Launch

#### 3a. Existing State File Guard

Before writing, check if `.claude/ralph-loop.local.md` already exists using the Read tool:

1. If the file exists, read it and present a warning: "An active ralph loop state file already exists. Iteration: {iteration}, prompt: {first 80 chars of prompt text}..." Use AskUserQuestion with options:
   - "Overwrite" — proceed with writing the new state file
   - "Abort" — stop without writing (leave existing file untouched)
2. If the file does not exist, proceed directly to Step 3b.

#### 3b. Present (Dry-Run)

**Capture the current UTC time** before displaying or writing the state file. Run `date -u +"%Y-%m-%dT%H:%M:%SZ"` via the Bash tool and store the output as `{utc_timestamp}`. Always use the Bash tool for timestamps — LLM-generated times are unreliable.

Display the state file content that would be written:

```
Here's the ralph loop state file that will be written to .claude/ralph-loop.local.md:

---
active: true
iteration: 1
max_iterations: {max_iterations}
completion_promise: "{completion_promise}" (or null)
started_at: "{utc_timestamp}"
session_id: {session_id}
---

{assembled_prompt}
```

If `--dry-run` was specified, stop here.

#### 3c. Confirm and Execute

Use AskUserQuestion: "Ready to launch the Ralph loop?" Options:
- "Launch it" — write the state file and start
- "Edit first" — let the user modify the prompt before launching
- "Save and exit" — save the state file content to `docs/plans/ralph-command-{timestamp}.md` for later use

If "Launch it":
1. Write `.claude/ralph-loop.local.md` using the Write tool with the exact content shown in the dry-run. The file must use the frontmatter schema the stop hook expects:
   - `active: true`
   - `iteration: 1`
   - `max_iterations: {value from arguments or default}`
   - `completion_promise: "{text}"` (quoted) or `null` (unquoted)
   - `started_at: "{utc_timestamp}"` (the value captured via Bash in Step 3b)
   - `session_id: {session_id}` — the current session's id, unquoted, the same value the progress-file convention uses
   - Followed by `---` and then the assembled prompt text

**Why `session_id` is written.** The state file is project-scoped but the Stop hook fires in *every* session open on that project. `ralph-loop` compares this field against the session its hook was invoked for and exits without touching the file when they differ, so a second window on the same repo neither steals the loop nor deletes its state. `ralph-wiggum` has no such field and ignores it, which is why writing it is safe on either plugin.

**Write the real id or omit the field — never a placeholder.** A field that is absent, or present but empty, reads as legacy and the hook behaves as it always did. A field holding a *wrong* id matches no session, so every Stop hook exits early, the prompt is never fed back, and the loop silently does not run. That failure looks exactly like the loop having finished, which is the class of failure step 1c exists to remove — so if the session id is not available, leave the line out rather than guessing at it.
2. Output an activation message:

```
Ralph loop activated!

Iteration: 1
Max iterations: {N or "unlimited"}
Completion promise: {text or "none"}

The stop hook is now active. When you try to exit, the same prompt will be
fed back to you. You'll see your previous work in files, creating a
self-referential loop where you iteratively improve on the same task.
```

3. Then output the assembled prompt text so Claude begins working on it immediately.

If "Edit first": present the prompt for the user to modify, then re-present from 3b.
If "Save and exit": write the state file content to `docs/plans/ralph-command-{timestamp}.md`.

## State Management

Follow the shared **Progress File Management** procedure.

**Lifecycle**:
- **Create**: before Step 1.
- **Delete**: after the Ralph loop is launched, or after dry-run output is presented.

(No update step — pre-flight is short enough to write once at creation and replace at end.)

**Format**:

```markdown
# CPM Session State

**Skill**: cpm:ralph
**Step**: {N} — {Step Name}
**Epic list**: {resolved epic paths}
**Max iterations**: {value}

## Pre-flight Results
- Epics found: {count} ({list})
- Ralph plugin: {detected/not detected}
- Test runner: {command or "none"}
- Resume: {yes — resuming from log {path} / no — fresh run}

## Next Action
{What to do next}
```


## Maintenance Coupling

> **This section documents dependencies between `cpm:ralph` and external components.** Changes to `cpm:do`'s interaction gates or the ralph-wiggum plugin's state file format may require updates to this skill.

### Ralph Wiggum State File Schema

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
---

{prompt text}
```

| Field | Type | Stop Hook Usage |
|---|---|---|
| `active` | boolean | Not currently checked by stop hook (presence of file implies active) |
| `iteration` | integer | Compared against `max_iterations`; incremented each loop |
| `max_iterations` | integer | Loop stops when `iteration >= max_iterations` (0 = unlimited) |
| `completion_promise` | string or null | Matched against `<promise>` tags in assistant output |
| `started_at` | ISO 8601 string | Informational; not parsed by stop hook |

**When to update**: If the ralph-wiggum plugin changes the state file path, frontmatter field names, or parsing logic in `stop-hook.sh`, this skill's Step 3c must be updated to match. The stop hook uses `sed`, `grep`, and `awk` to parse the frontmatter — any format change that breaks these parsers will break the loop.

### cpm:do Interaction Gates

This table records how each `cpm:do` gate is handled under an autonomous run. Most are overridden by the prompt's blanket instruction ("choose the most reasonable option for every AskUserQuestion"); three are not, and each says so in its own row — the Stale-Progress Check is suppressed structurally by its guard, while the Retro Check and Change Type Decision gates take an explicit branch in `cpm:do` because for them the blanket instruction picks a wrong answer rather than no answer.

| `cpm:do` Location | Gate Purpose | Prompt Override |
|---|---|---|
| Stale-Progress Check (shared convention, runs at every `/cpm:*` skill startup — including the `/cpm:do` this loop wraps) | Offer cleanup of stale/leftover progress files from other sessions, at most once per session | **Fully suppressed — no prompt, no output, no action.** Suppression is *guard-level*, not prompt-driven: the shared guard (`hooks/lib/cleancheck-guard.sh`) detects the active ralph loop via `.claude/ralph-loop.local.md` and returns `SUPPRESS`, so the check self-silences before any prompt regardless of the prompt's autonomous instruction. No prompt clause is required (and none is added) — the gate cannot stall the loop |
| Input — Epic Doc (multiple epics) | Ask user which epic to work on | Auto-select from the epic list in order |
| Test Runner Discovery | Ask user for test command | Proceed with self-assessment |
| Retro Check — consumption disposition gate | Force a per-run disposition (Applied/Deferred/Not relevant here) on each prior-epic retro observation; durable retirement (the gated in-cycle Obsolete) is a separate deliberately-confirmed action, never auto-taken | **Do not block, do not "choose the most reasonable option".** Branch by category using `cpm:do`'s single-source safe/defer split (its Retro Check → Autonomous mode), not a blanket defer: **auto-apply** safe categories (Codebase discoveries, Patterns worth reusing), recording `**Retro applied**: {nn} · {category} · applied (autonomous, safe-category) — {what it did}` and carrying each into the run as context; **defer** judgement-heavy categories (Scope surprises, Criteria gaps, Complexity underestimates, Testing gaps), recording `**Retro applied**: {nn} · {category} · deferred (autonomous run, unreviewed)`; Smooth deliveries is informational. Surface **both** the auto-applied and deferred lists in the run summary for post-loop human review. **Never auto-retire** — apply or defer only, never the Obsolete retire |
| Termination — Blocker | Confirm external blocker with user | Skip the task and continue to next |
| Termination — Ambiguity | Ask user to clarify unclear criteria | Mark story "Blocked -- criteria ambiguous" and continue |
| Guidelines — Change Type Decision (*Surface change moments explicitly*) | Present a four-option `AskUserQuestion` when a change-worthy situation appears mid-task — a criterion that contradicts reality, a story whose scope is wrong | **Do not block, do not "choose the most reasonable option".** Take `cpm:do`'s autonomous branch (its Guidelines → *Surface change moments explicitly*), which resolves the change moment instead of presenting it: inline edit, retro observation, or amend the epic under execution — never `/cpm:pivot`. Amendment is guarded by a citable contradiction, and leaves a `**Pivot deferred**` breadcrumb for each artefact it could not reach — sometimes none; `cpm:do` holds the rule. Unlike the rows below, the blanket instruction is not merely insufficient here but harmful: one of the four options is Pivot, whose own gates would stall the loop, and the shared matrix's *when in doubt, choose pivot* default makes it the one a blanket "most reasonable option" tends to land on |
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

**The completion row is a record, not the mechanism.** Its last cell says so on purpose: the stop hook feeds the *template line* back verbatim on every iteration and the loop never reads this table, so an instruction that lives only here documents a behaviour the loop does not have (retro 21). The row exists because the table is where a reader looks for what the loop does at each decision point, and the loop's own exit is one — but the template is the site that acts.

**Retro generation is not a gate**: retro *generation* at `cpm:do` Step 8 writes the retro file automatically (no `AskUserQuestion`), so it runs unchanged under autonomous execution — only the *consumption* gate above needs an override. Generation still fires at epic completion during a Ralph run.

**`cpm:epics` gates are not rows in this table, and that is deliberate.** The table is scoped to the gates of the skill this loop wraps. `cpm:epics` holds its own dispositions in its **Autonomous Mode** section — the single source — and the template carries a one-sentence reference to it rather than a copy. Two copies of a gate table is how a disposition changes in one place and not the other; a reference cannot go stale. As with the completion row above, this paragraph is a record for a maintainer looking here first, and the template is the site that acts.

**When to update**: If `cpm:do` adds, removes, or changes an `AskUserQuestion` gate, review the prompt template's Autonomous Behaviour section and this table. A new gate that isn't overridden will cause the Ralph loop to pause and wait for user input — defeating the purpose of autonomous execution.

## Guidelines

- **Facilitate the setup, automate the execution.** The skill's interactive phase is pre-flight and launch confirmation. Once Ralph starts, everything is autonomous.
- **Deterministic prompts.** Same epics + same config = same prompt. No randomness.
- **Fail fast on pre-flight.** If prerequisites are missing, tell the user immediately — only generate a prompt that can succeed.
- **Dry-run is the default first step.** Always show the user what will run before running it.
- **The execution log is the audit trail.** It survives across Ralph iterations and is the primary post-run artifact for the user to review.
