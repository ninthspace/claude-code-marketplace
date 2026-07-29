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
   - **Epic mode** — report to the user and stop: "No incomplete epics found. Nothing to run." Before stopping, glob `docs/specifications/[0-9]*-spec-*.md`; if any exist, name them and add one line: "Spec mode runs a spec from scratch — `/cpm:ralph {path}`." Then stop. **Do not offer spec mode, and do not ask which one to use.** The stop is still a stop.
   - **Spec mode** — do **not** stop, and do not emit that message. Zero epics is spec mode's starting state rather than a failure: the run's first phase is what writes them. Report "No epics for `{spec_path}` yet — phase 1 generates them." and continue pre-flight with an empty resolved list.
4. Present the discovered epics and confirm with AskUserQuestion. In spec mode present `{spec_path}` alongside them, since the epics found are the run's starting position and the spec is what it is measured against — with none found there is still something to confirm.

**Why the epic-mode stop names the specs but does not offer them.** The mode comes from the path, and a bare invocation supplied no path — so there is nothing to resolve, and a gate that resolved one would move the mode decision out of the argument and into a question. That matters more than it sounds: spec mode commits a loop to generating a whole epic set and delivering it, which is a much larger thing than the run the caller asked for, and an option presented as recommended gets accepted.

The stop was nonetheless the wrong shape, and being a dead end is what makes it worth routing around: it reports that there is nothing to run in a repository that plainly has something to run, and names no way forward. Naming the specs and the command is the whole remedy — the user types the path, which is where the mode has always come from.

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

`{epic_glob}` is a path list, not a pattern — every shape resolves to files before the prompt is assembled, so the loop never re-expands a glob against a directory that may have changed since launch. It is passed verbatim to `coverage-rollup.sh --epic` in the completion check (Step 2), which is why its form is fixed here rather than left to the assembly step — in epic mode. **In spec mode that list can be empty at launch, so `--epic {epic_glob}` would have nothing to pass**; spec mode's completion check asks a different question (*are the spec's requirements traced*), and the prompt that asks it is not built yet, so Step 2 still assembles epic mode's template today. CPM epic filenames are numbered kebab-case and contain no spaces, so a space-separated list is unambiguous; a path containing a space would need quoting and does not occur.

#### 1b. Strip `[plan]` Tags

Formal plan mode (`EnterPlanMode`) creates an interactive approval gate that stalls autonomous execution. Strip `[plan]` tags from epic docs before launching the loop so `/cpm:do` uses inline planning for all stories.

**Ordering**: this step runs after epic discovery and before any other pre-flight checks — autonomous execution depends on it.

1. For each resolved epic path, use the Read tool to read the file. Scan the content for any heading line (lines starting with `##` or `###`) that contains the literal text `[plan]`. Use Read for this — reading each file directly avoids regex escaping issues with square brackets in Grep.
2. For each heading that contains `[plan]`, use the Edit tool to remove the `[plan]` tag and any trailing whitespace it leaves behind (e.g. `## Set up OAuth integration [plan]` → `## Set up OAuth integration`).
3. Track which stories were modified. Log a line per stripped tag for inclusion in the execution log: "Stripped `[plan]` from Story {N}: {heading text}".
4. If no `[plan]` tags are found, skip silently.

#### 1c. Ralph Stop Hook Detection

A ralph loop plugin's stop hook is the only external dependency — it intercepts session exit and feeds the prompt back to continue the loop. `cpm:ralph` writes the state file directly (no dependency on the setup script).

**Three plugins provide that hook and CPM works with any of them.** `ralph-loop@ninthspace-ralph` **1.2.0 or later** is the supported configuration — the fork CPM is developed against, and the version this skill's documented loop behaviour is written against. `ralph-loop@claude-plugins-official` (Anthropic) is the line it forked from, and `ralph-wiggum@claude-code-plugins` the original before that. All three install the same hook at the same relative path under two distinct plugin names, so no name may be treated as *the* dependency — a check written against one reports "not installed" on a machine running another, and the fork and its upstream share a name and differ only by marketplace.

**The version is stated, never checked.** A registered hook carries no version this skill can read, and a version is the weaker question anyway: step 3 below runs the hook and branches on what it *does*, which is what a version number is a proxy for. So name the supported version when telling a user what to install, and gate on the probe.

1. Check if a ralph stop hook is registered by scanning the session's available hooks for a "Stop" hook referencing `ralph-loop`, `ralph-wiggum`, or `stop-hook.sh`.
2. If not detected, warn the user: "No ralph stop hook detected. The loop mechanism requires a ralph-loop or ralph-wiggum plugin — without the stop hook, writing the state file will have no effect. Install `ralph-loop@ninthspace-ralph` 1.2.0 or later, whose stop hook does not delete the loop's state file when it cannot read the transcript, does not print the completion promise inside its own tags, and honours `active: false` as a pause." Use AskUserQuestion with options: "Continue anyway" or "Stop".
3. **Probe which direction the hook fails in**: resolve the plugin's `hooks/lib/ralph-hook-probe.sh` to an absolute path, run `bash <that path>`, and branch on its exit code. Unlike `{rollup_script}` (Step 1f) this path is never interpolated into the prompt — the probe answers a question about launching, so it runs once here and the loop never sees it. `0` — the hook fails closed; continue pre-flight without comment. `2` — no hook on disk; fold into the warning above rather than reporting twice. `1` — the probe could not run; say so and let the user decide, since an unrun probe is not a pass. `3` — **a hook fails open**: report "The installed stop hook deletes the loop's state file on a normal turn shape and exits 0. An unattended run would end silently and look like a clean finish." Name the hook the probe reported, since with both plugins enabled the safe one is not the one that matters. Use AskUserQuestion with "Patch or switch plugin first (recommended)" and "Arm the loop anyway".

**Both plugins enabled is a real configuration, and the dangerous hook wins.** Two registered Stop hooks both fire on the same session, and the state file only has to be deleted by one of them for the loop to die. The probe therefore runs *every* hook it finds and lets a single fails-open verdict decide, rather than stopping at the first one that passes.

**Registration is not the property that matters.** A hook can be installed and registered throughout a run in which it deletes the state file at the first iteration boundary — step 2 passes the whole time. What a hook *does* on a turn ending in a tool call is a different question from whether it is present, and the only way to ask it is to run the hook. That is what step 3 does — it builds a state file and a two-record transcript whose last assistant record is a bare tool call, runs the real hook against them in a scratch directory, and checks whether the state file survived.

**Why this is a behavioural probe and not a grep of the hook's source.** Reading the hook for a known-bad line pins CPM to one vendor's wording, passes the moment upstream rephrases it, and still says nothing about what the hook does. It would also have to be updated for each new way of getting this wrong. Running it answers the question directly and keeps working across versions and forks.

**Why it is checked at every launch rather than once.** The hook lives in the plugin cache, which is overwritten on update. A machine where this was fixed by hand is one `/plugin update` away from being a machine where it is not, and nothing announces that. The failure it guards against is specifically the silent one — a run that ends with no promise, no error and no state file is indistinguishable from one that finished — so the check has to be cheap enough to repeat, and it is: one subprocess against a scratch directory.

**Permissions note**: The loop will pause on permission denials at runtime; the stop hook re-invokes after the user grants them. To avoid mid-loop stalls, users can pre-add common Bash permissions (`Bash(git:*)`, `Bash(bash:*)`, `Bash(find:*)`, `Bash(grep:*)`) to `~/.claude/settings.json` before launching.

#### 1d. Test Runner Discovery

Discover the project's test runner for inclusion in the generated prompt:

1. **In spec mode, read the spec's environmental block first.** `{spec_path}` is resolved in Step 1a, so the file is already in hand. Read its `## Non-Functional Requirements` section and take the test tooling from the `ENVn` entries that name it — a test runner, a browser automation driver, an isolated test database. Report what the spec named, and whether it named a tool (`Pest 3 or later`) or a command: a tool is what the run has to install before it can have a command, so say which was found rather than reporting a tool as though it were runnable.
2. Check project config files (`composer.json`, `package.json`, `Makefile`, `pyproject.toml`, `Cargo.toml`) for test commands. In spec mode these confirm or complete what step 1 found; in epic mode they are the only source.
3. If found, report: "Discovered test runner: {command}. This will be referenced in the generated prompt."
4. If not found, note: "No test runner discovered. The generated prompt will instruct `/cpm:do` to discover one at runtime."

**Why the spec is consulted first, and only in spec mode.** A greenfield spec-mode run has no `composer.json`, no `package.json` and no `Makefile` — the application is what the run is about to build — so a discovery consulting only those files cannot succeed in the case spec mode exists for. It reports "no test runner discovered" and assembles a prompt telling `/cpm:do` to find one at runtime, while the answer sits in the file this same pre-flight already resolved. `cpm:spec` Step 3a is the single site at which a spec captures test tooling, which makes the `ENVn` entries a statement of what the target *must* provide; the config files are evidence of what the project currently *has*, and in epic mode that is the better question, which is why the order does not change there.

#### 1e. Resume Detection

Check for evidence of a previous Ralph run:

1. **Glob** `docs/plans/ralph-log-*.md` for existing execution logs.
2. If an execution log exists, read it and summarise the state: which epics completed, which are in progress, any skipped tasks.
3. Use Grep to check the target epic docs' `**Status**:` fields to confirm the current state. Use Grep and Read tools directly.
4. If a previous run is detected, present the state to the user with AskUserQuestion: "Found a previous Ralph run. {N} epics completed, {M} remaining. Resume from where it left off?" Options: "Resume" or "Start fresh (ignore previous state)".

**Spec mode also looks for a leftover `cpm:epics` progress file.** A spec-mode run that dies during phase 1 leaves two things behind — the loop's own state file, and the progress file `cpm:epics` was keeping — and the second one records how far generation got. In spec mode only, after step 4:

5. Run the classifier directly:
   `CPM_SESSION_ID="$CPM_SESSION_ID" bash "${CLAUDE_PLUGIN_ROOT}/hooks/lib/progress-classify.sh"`
6. Keep the records whose `SKILL` field reads `cpm:epics` and whose classification is not `CURRENT`. For each, Read the file and compare its `**Input source**` to `{spec_path}` by basename, the way step 1a compares `**Source spec**`.
7. On a match, add it to step 4's presentation — path, phase, age label, and the file's `## Epic Files` table showing which epics were Written and which were still Pending, which is the resume state itself — and let the same Resume / Start fresh gate decide. With no previous execution log, present it on its own using the same gate.
8. **Read it; never delete or overwrite it.** The shared **Stale-Progress Check**'s rule governs here unchanged — no path auto-executes a delete — and "Start fresh" means this run ignores the file, not that anything removes it.

**Why this does not consult the guard, and why the guard is left alone.** `cleancheck-guard.sh` returns `SUPPRESS` whenever `.claude/ralph-loop.local.md` is present, which is exactly the state a relaunch after a dead loop is in — so the shared safety-net is silent at the one moment this file most needs surfacing. That silence is the autonomous carve-out and it is correct: its subject is *prompting the user mid-loop*, which is what would stall an autonomous run. This step asks a different question at a different time, before the loop is armed, so it calls the classifier — which is read-only and prompts nobody — and does not consult the guard at all. Adding a ralph exemption inside the guard would answer this one caller by un-silencing the safety-net for every other skill during every run.

#### 1f. Roll-Up Script Resolution

The generated prompt gates its completion promise on `coverage-rollup.sh`'s exit code, so the path to that script has to be in the prompt as an **absolute path resolved here**, not as a variable the loop expands later.

1. Resolve the plugin's `hooks/lib/coverage-rollup.sh` to an absolute path and store it as `{rollup_script}`.
2. Confirm the file is readable. If it is not, warn the user: "The coverage roll-up script was not found at {path}. The loop will run, but its completion promise will not be script-backed — it would fall back to the model's own judgement, which is what the script-backed check exists to remove." Use AskUserQuestion with options: "Continue anyway" or "Stop".

**The exit codes, stated here because assembly depends on them.** Both completion clauses and the phase predicate branch on `{rollup_script} --verdict`'s exit code, so the contract is guidance you read while assembling — not only text you copy into the template. Do not re-derive it by reading the script.

| Code | Means | What the loop does with it |
|---|---|---|
| `0` | Ran cleanly, nothing outstanding | The only code that permits the completion promise |
| `1` | Read failure — input unreadable, message on stderr names the file | Say the check could not run; never emit the promise |
| `2` | Usage error — the invocation is wrong | Same as `1`: the check did not run |
| `3` | Ran cleanly, work remains | Name the rows it emitted and keep working |
| `4` | No matrix names this spec yet | Spec mode only, and only under `--verdict`: the one code that sends the loop into `/cpm:epics` |
| `5` | Ran cleanly; every remaining unverified row is `[target]` | **Terminal.** Nothing here can close them. Report and stop the loop — never emit the promise |

`4` and `5` are reachable only with `--verdict`; without the flag a no-matrix read collapses into `1`. Every code other than `0`, `3` and `5` means the verdict is unknown rather than negative, and the difference matters: a loop that treats "could not run" as "work remains" runs to its iteration cap on finished work.

**`5` is the terminal state that `3` was missing.** A `[target]` criterion is unverifiable from anywhere but the deployment host, so on any spec naming a production-host requirement, `0` is unreachable and `3`'s "keep working" describes work that does not exist. Both completion clauses therefore branch on `5` and stop — see *Stopping without the promise* below, which is the only place either clause is allowed to end a run that has not earned its promise.

**Why resolved here rather than written as `${CLAUDE_PLUGIN_ROOT}`**: the prompt is fed back to the model as a plain user turn by the stop hook, not executed inside a skill, so a plugin-relative variable is not guaranteed to be set when the completion check runs — and an unset one expands to a bare `/hooks/lib/coverage-rollup.sh`, which exists nowhere — a path built from a variable that is set for hooks and not for the call that uses it, failing silently. Interpolating the resolved path keeps the prompt self-contained, which is what every other `{...}` in the template already does.

#### 1g. Session-State Ignore Check

The assembled prompt instructs the loop to commit after each completed story, and an autonomous run stages everything. Three files are session-scoped agent state that no run should be committing, and one of them changes on **every** iteration:

| Path | Written by | Churn |
|---|---|---|
| `.claude/ralph-loop.local.md` | the ralph plugin | `iteration:` changes every cycle; the file is deleted on a clean finish |
| `docs/plans/.cpm-progress-*` | every CPM skill (shared **Progress File Management**) | rewritten at each step |
| `docs/plans/.cpm-compact-summary-*` | the PostCompact hook | written on compaction |

Do this before arming, not after:

1. Check whether the project ignores all three. A repository with no `.gitignore` at all ignores nothing.
2. If any is unignored, show the user the lines that would be added and get approval — this edits a file in their repository, so it is their call:
   ```
   # Session-scoped agent state, not part of the project's history
   /.claude/ralph-loop.local.md
   /docs/plans/.cpm-*
   ```
   Use AskUserQuestion with "Add them" / "Continue without" / "Stop". On approval, append them to the project's root `.gitignore`, creating it if absent.
3. If the user declines, continue — and say once that the loop's own state and CPM's progress files will appear in its commits.

**Why this is pre-flight and not a prompt clause.** The leak is caused by the first commit, so a run that discovers it later has already made it: adding the ignore afterwards untracks the files but leaves them in the commits already written, and history is not rewritten. Every other CPM skill is safe without this because a human stages their work and does not type these paths; `cpm:ralph` is the only skill that commits with no one looking at the file list, which is what makes the check its business rather than the shared convention's.

**`.claude/ralph-loop.local.md` is not CPM's file, and is included anyway.** It is the same class of mistake, this skill is what puts it on disk, and a user reading a commit full of loop churn will not care which plugin wrote it.

### Step 2: Prompt Assembly

Assemble the ralph-loop prompt as plain text — no markdown, code fences, backticks, or XML tags (the stop hook feeds the prompt back verbatim on each iteration). Interpolate these variables into the template:

- `{epic_count}`, `{epic_range}`, `{epic_glob}` — from Step 1a, which defines each; `{epic_glob}` is a space-separated path list, not a pattern
- `{rollup_script}` — the absolute path resolved in Step 1f
- `{max_iterations}` — from arguments or default (50)
- `{story_filter_clause}`, `{test_runner_clause}`, `{resume_clause}` — include when applicable, omit otherwise
- `{task_budget_clause}` — "Task budget: {N} tasks, estimate ~2000 tokens per task." Count `###` task headings in target epic docs.
- `{completion_promise}` — `ALL_EPICS_COMPLETE` in epic mode, `SPEC_DELIVERED` in spec mode. Taken from `{mode}` (Step 1a) and fixed for the run; it is written into the state file's frontmatter in Step 3 and is the same literal string the prompt's completion clause tells the model to emit.

#### One promise per mode, fixed at launch

**The tag differs by mode and nobody is asked which one to use.** `completion_promise` is per-run frontmatter, so the two modes can name different achievements without a choice existing at any point: `{mode}` is resolved once in Step 1a, and the promise follows from it. No choice exists at any point, which is the property that matters: an *available choice* is what lets the weaker path survive. `ALL_EPICS_COMPLETE` at the end of a spec-mode run names the wrong achievement in a log read by someone who was not there.

**Evidence goes beside the tag, never inside it.** The stop hook compares the `<promise>` tag's contents to `completion_promise` with literal string equality after whitespace normalisation, so a tag carrying counts, a summary or a file list never matches, and the loop runs to its iteration cap on finished work. Both completion clauses put their coverage line on its own line next to the promise for exactly this reason.

#### The phase predicate

**In spec mode the phase judgement is a reading of `coverage-rollup.sh`'s records, and of nothing else.** The loop runs `bash {rollup_script} --spec {spec_path} --verdict` and takes two things from that one run: its exit code, and the `SUMMARY` record's `untraced` field. Phase 1 — generating the epics — is over when that field reads `0`; phase 2 — working them — is over when the run exits `0`, which is the script's own statement that no row is unverified. There is no marker file and no phase written down anywhere: the records **are** the state, so a run that resumes mid-flight re-reads its position instead of remembering it.

**A phase that cannot make progress stops; it does not repeat.** Exit `4` is the only code that sends the loop into `/cpm:epics`, because it is the only one meaning *no matrix names this spec yet*. An untraced count above zero on any other code means `cpm:epics` has already run and what it wrote does not cover the spec — a second run cannot fix that, and would actively make it worse: sub-numbers are assigned `max + 1`, so each run writes a **fresh** set of epic docs rather than completing the set already there. Phase 2 carries the mirror rule: its exit-`3` branch keeps working only while an epic still has unfinished work, since another pass over completed epics cannot change the verdict.

This is a liveness rule, not a phase-semantics change: `untraced == 0` still ends phase 1. What changed is what happens when it does not — the loop reports what is missing and stops, rather than repeating a step whose output it has already seen.

**The loop relays; it does not compute.** It names the fields it read and repeats their values verbatim — it never counts rows, sums a column, or decides for itself that a requirement is traced or a row verified. Those judgements exist in exactly one place -- the roll-up -- and it is the same rule the epic-mode completion clause already states as *never work that verdict out yourself from the records*.

**Phase is never inferred from the epic files.** That `docs/epics/` holds four matching files, or none, says nothing about which phase the run is in: a partially-generated set looks exactly like a complete one on disk, and at iteration 1 spec mode's epic list is legitimately empty (Step 1a). The count of files is not consulted, and `{epic_count}` is a label for the user rather than an input to this decision.

**Template** (written into `.claude/ralph-loop.local.md` body; use `--` for dashes; `ALL_EPICS_COMPLETE` must match `completion_promise` frontmatter):

**Length: 3355 characters**, measured on the template line below before interpolation — the assembled prompt is longer, since the `{...}` placeholders expand at runtime. This is a *measurement*, not a target: every clause is an override without which the loop stalls or drifts, so the figure is not something to cut toward. `test-ralph-autonomous-wiring.sh` and `test-ralph-promise.sh` extract it and compare it against the line's actual length, so any edit to the template fails those suites until the figure is updated here — which is the point of stating a number. Keep new clauses to a sentence.

```
Run /cpm:do on epics {epic_range} sequentially ({epic_glob}). Continue to each next epic automatically. Make all decisions autonomously -- choose the most reasonable option for every AskUserQuestion. Use inline planning for all stories. Task complete means: all tagged criteria ([unit]/[integration]/[feature]) have passing test results, and all [manual] criteria have self-assessment lines in the progress file. A [target] criterion is checkable only against the real deployment target, so never self-assess one and never count it as met -- record it as target-only -- unverified in this environment, name it in the run summary, and let the other criteria decide completion. An unrecognised tag is reported the same way, never self-assessed. A failure (for the 3-strike skip rule) is a test command exit code != 0 after a code change attempt -- tool errors and permission denials are retries, not failures. If acceptance criteria are ambiguous and completion cannot be determined, mark the story Blocked -- criteria ambiguous and continue to the next story. At the do retro consumption gate, do not block -- branch by category: auto-apply safe categories (codebase discoveries, patterns worth reusing), recording Retro applied: {nn} {category} applied (autonomous, safe-category) -- {what it did} and carrying each as context; defer the rest (scope surprises, criteria gaps, complexity underestimates, testing gaps) as Retro applied: {nn} {category} deferred (autonomous run, unreviewed); smooth deliveries informational; never auto-retire. List both applied and deferred observations in the run summary. At the do Change Type Decision gate, do not block and do not pick one of its options -- take do's autonomous branch: inline edit, retro observation, or amend the open epic doc so later stories inherit the fix; never /cpm:pivot. Amend only on a citable contradiction, and record a Pivot deferred breadcrumb for each artefact left behind. Report amendments separately from the deferred observations. If a cpm:epics gate is reached, do not block -- take cpm:epics' Autonomous Mode branch, and never restate its rules here. Commit after each completed story. Keep all commits local.{story_filter_clause}{test_runner_clause}{task_budget_clause}{resume_clause} When the last specified epic completes, run bash {rollup_script} --epic {epic_glob} --verdict and let its exit code decide: on 0, print one line reading COVERAGE: N of M rows marked verified across K matrices -- aggregation, not verification, since every mark was placed by cpm:do on its own work, and it counts rows in these epics, not requirements in a spec, so it cannot say a spec is delivered -- then output ALL_EPICS_COMPLETE; on 3, do not output it, name the unverified rows the script emitted and keep working; on 5, do not output it, print TARGET-ONLY: N rows unverifiable in this environment followed by their labels, then stop the loop -- delete .claude/ralph-loop.local.md; on any other code, do not output it and say the check could not run. Never work that verdict out yourself from the records, and never output ALL_EPICS_COMPLETE without having run that command in the same turn. Put the counts on their own line beside the promise, never inside the promise tag the stop hook matches -- it compares that text exactly, so anything added inside it stops the loop from ever ending.
```

#### Spec mode's two phases

**Spec mode assembles the same template with two sentences swapped, not a second template.** Every autonomy rule in the line above applies unchanged in spec mode — they are about how `cpm:do` behaves without a human, which the mode does not alter — so they exist in one copy and are substituted into rather than restated. Assemble spec mode's prompt from the template above with exactly two replacements:

1. Replace the **opening sentence** — the first sentence of the template, the one naming `{epic_range}` and `{epic_glob}`, together with the "continue automatically" sentence after it — with the **phase clause** below.
2. Replace the **completion clause** — the final sentence group, the one gating the promise on the roll-up's exit code — with the spec-mode completion clause (Task 3.2).

Both boundaries are described rather than quoted. Quoting them here would put a second copy of the template's own opening in the file, and four suites locate the template by grepping for that sentence — a second copy is not a documentation flaw but a broken extractor.

**Phase clause** (spec mode; **1681 characters**, measured on the block below before interpolation and asserted by `test-ralph-two-phase-prompt.sh`):

```
Work spec {spec_path} to completion. This run has two phases and you re-check which one you are in at the start of every iteration: run bash {rollup_script} --spec {spec_path} --verdict, then read the SUMMARY record's untraced field and the exit code. Before branching on either, print one line reading COUNTS: R requirements, U untraced, D delivered, P in progress, taking all four numbers verbatim from that same SUMMARY record and working none of them out yourself; print it every iteration, including the ones that stop. Exit 1 or 2 means the check could not run: say so and stop, and never read either as phase 1 not started. Exit 4 means phase 1 and no epics exist for this spec yet: run /cpm:epics on {spec_path}, taking cpm:epics' Autonomous Mode branch, and end the iteration there. An untraced count of 0 means phase 2. An untraced count that is not 0 on any other code means /cpm:epics has already run and what it wrote does not cover the spec: report that partial set from the STATE records — the requirements it does cover as well as the untraced ones it does not — leave every epic doc already on disk exactly as it is, and stop; never run /cpm:epics twice in one run, since a second run writes a fresh set of epics instead of completing the set already there. Before the first /cpm:do of phase 2, strip [plan] tags from the epic docs this run generated, by the rule ralph pre-flight step 1b applies: remove the tag from any story heading carrying it and log one line per strip, touching no epic doc this run did not write. In phase 2, run /cpm:do on every epic doc naming {spec_path} as its source spec, in filename order, continuing to each next epic automatically.
```

**Completion clause** (spec mode; **1229 characters**, measured on the block below before interpolation and asserted by the same suite):

```
When phase 2 has no epic left to work, run bash {rollup_script} --spec {spec_path} --verdict and let its exit code decide: on 0, print one line reading COVERAGE: N of M rows marked verified across K matrices, R of R requirements traced -- aggregation of the marks cpm:do placed on its own work, not independent verification -- then output SPEC_DELIVERED; on 3, do not output it, name the untraced requirements and the unverified rows the script emitted, and keep working only while an epic still has unfinished work -- if none has, stop the loop, since another pass over epics that are already complete cannot change the verdict; on 5, do not output it, print TARGET-ONLY: N rows unverifiable in this environment followed by their labels, and stop the loop; on 4, do not output it and go back to phase 1, since no matrix names this spec yet; on any other code, do not output it and say the check could not run. Stop the loop means: delete .claude/ralph-loop.local.md. Never stop the loop for any other reason. Never work that verdict out yourself from the records, and never output SPEC_DELIVERED without having run that command in the same turn. Put the counts on their own line beside the promise, never inside the promise tag.
```

**Five codes, and the ones that must not collapse.** In the completion clause `3`, `4` and `5` all mean *do not promise yet*, and answering them the same way would be the easy edit — but they resume in three different places: `3` keeps working, `4` returns to phase 1, and `5` is terminal. `1` and `2` mean *stop*, and reading either as `4` would send a loop that cannot read its own inputs into generating epics against a spec it never parsed. It is written as explicit branches rather than "0 means done, anything else means continue" because a branch on a code the script never returns reads perfectly and never fires — so the codes named here must be the codes the script actually emits.

**Every branch that says *stop the loop* also says what stopping consists of.** Ending a turn is the one action a Stop hook intercepts, so an instruction to stop that names no action instructs nothing: the loop says it is stopping, ends its turn, and the hook feeds the same prompt back. The clause therefore defines the phrase once, as a file the loop removes — the one termination every plugin in the table at Step 3c honours, and the same one the hook performs on a matched promise. *Stopping without the promise* below is where the choice of mechanism is argued.

**The same code means different things in the two clauses, deliberately.** In the phase clause, exit `3` with untraced work means *`cpm:epics` has had its turn and fell short* — stop. In the completion clause it means *rows remain unverified* — keep working, while there is work left to do. Both readings are about what the next action could achieve, which is the only question a loop with no memory can usefully ask.

**The COUNTS line names all four SUMMARY fields, and takes them from one run.** The record carries `requirements`, `untraced`, `delivered` and `in-progress`; printing any *traced* or *verified* figure would mean subtracting or deciding which fields count, both forbidden by *The loop relays; it does not compute* above. The clause is emphatic about reading them *from that same SUMMARY record* for the reason the completion clause is: a second run of the script could return different numbers, and a line assembled from two runs is a reading of neither.

**Fail closed.** Every branch above except `0` leaves the promise unemitted, and the `any other code` catch-all makes that the default for codes that do not exist yet rather than a list to be kept current. An unreadable spec, a missing script, a permission error and a code added next year all reach the same place: no promise, and a line saying the check could not run.

**What spec mode costs.** Substituting both clauses gives an assembled spec-mode prompt of **5,068 characters** — the template's 3,355 less the 103-character opening and the 1,094-character completion clause it replaces, plus the two blocks above.

**None of those four figures has a test.** The `**Length:**` figure above is extracted and compared against the template line by two suites; these are prose, so an edit to the template or to either clause silently falsifies them. Re-measure them by hand when you change any of the three blocks — a stated figure whose only guard is the diligence of the next editor is the failure this file has already had once. They are stated at all because the epic-mode figure a suite asserts is a *different* number, and a reader who checks only that one would conclude the two-phase prompt was free.

**Why the phase is re-read every iteration rather than carried.** The loop has no memory between iterations beyond the state file, which the stop hook rewrites only to advance `iteration:`. Reading the phase from the records each time is therefore not a cost but the only honest option — and it is what makes a resumed run correct, since the records describe the epics that exist now rather than the ones that existed at launch.

**Phase 1 is never "done" on its own.** It ends when the *next* check reports 0 untraced, which is a fact about the epics `cpm:epics` just wrote — so the clause ends the iteration rather than declaring anything, and the completion tag is unreachable from inside it. A spec with no epics reports 0 untraced only when there are no requirements to be untraced; that case exits 4, which is why 4 routes to the generation step rather than to phase 2 or to the failure branch.

**What a non-zero untraced count is evidence of depends on whether epics exist.** Before `cpm:epics` runs there are no matrices, the script exits 4, and untraced is unmeasurable — nothing to compare rows against. After it runs, an untraced requirement is evidence about the *epics*, not about the phase: `cpm:epics` is not obliged to cover everything the spec lists — its own cross-epic gap check blocks on some requirements and merely warns on others — so a count that never reaches 0 is a possible and legitimate outcome of a phase 1 that finished properly. Treating it as "phase 1 unfinished" sends the loop back to generation forever, which is why exit 4 — not the count — is what routes into `/cpm:epics`.

**What the completion line measures, and what it cannot.** The loop runs `coverage-rollup.sh` in **epic scope**, so the number it prints is rows marked verified out of rows present, across the matrices for the epics it was given. Every one of those `✓` marks was placed by `cpm:do` on its own work, which is why the line says **aggregation, not verification**: it reports what this run claimed, counted up, and adds no independent evidence. A wall of green means every row was marked, not that anything works.

The measurement that would discriminate is the **untraced count** — requirements in a spec with no matrix row anywhere claiming them — and epic scope cannot produce it, because it has no requirement list to compare against. That is `--spec` scope's measurement, which `cpm:status` presents and which spec mode's phase predicate reads directly (see *The phase predicate* above); **epic mode has no spec-scope promise**, and gains none by counting its rows more carefully. So a passing completion line here means "the epics I was pointed at have no unverified rows left", never "the spec is delivered". A spec with a requirement no epic ever covered produces the same clean line.

#### Stopping without the promise

**A loop cannot stop by saying it is stopping.** Ending a turn is what the stop hook exists to intercept: it blocks the exit and feeds the prompt back. So an instruction to "stop" that names no action is not an instruction — the model writes *stopping*, the hook blocks, and the same iteration runs again until `max_iterations`. This is not hypothetical; it cost a field test 34 identical iterations over three hours on a spec whose work was already complete.

Every clause that tells the loop to stop must therefore name the action, and there is one:

```
Stop the loop: delete .claude/ralph-loop.local.md.
```

**The delete, not `active: false`.** Setting the field is the gentler edit — it is non-destructive, and on `ralph-loop@ninthspace-ralph` it leaves the prompt and iteration count in place for whoever finds the run. It is also wrong here, for two reasons that both come from the file *surviving*. The field is inert on the other two plugins (Step 3c), so the pause needs a second clause escalating to the delete anyway, and a stop mechanism with a retry is one the loop can get wrong once. Worse, `cleancheck-guard.sh` suppresses the shared **Stale-Progress Check** on that file's *existence*, so a run that ends by pausing leaves CPM's safety net silently off in that project, in every later session, for every skill — and on any spec naming a production-host requirement, that is the ordinary way runs end.

The delete has neither problem, and it is what the loop's own successful ending already does: the stop hook deletes this file when it matches the completion promise, and again when it reaches `max_iterations`. A run that stops here therefore leaves the project in the same state as a run that finished — which is the honest description, since nothing further in this environment can change the verdict. The state worth keeping was never in this file: the run summary names the rows, and the epic docs and coverage matrices hold the work.

**This does not weaken the shared rule against auto-executed deletes.** That rule (`skill-conventions.md`) governs *progress files*, which record human-reviewable state no other artefact holds. This file is the loop's own scratch state, owned and routinely deleted by the stop hook. Nothing in `docs/plans/` is touched here.

**This is the only sanctioned way to end a run without the completion promise**, and it stays that way: a loop that may end itself for any reason it finds persuasive is a loop whose completion means nothing.

#### Wrap the assembled prompt before it leaves this step

The template above is one line and stays one line — its stated length is measured on it. The **assembled** prompt is not: interpolation makes it longer still, and written as a single line it is what a human supervising an unattended run reads at every iteration, in a terminal that cannot render it. Wrap it here, once, so the dry-run in Step 3b and the file written in Step 3c cannot show different things:

```
fmt -s -w 100
```

**Use `fmt -s`, not `fold -s`.** They differ on exactly one case and it is the case this prompt contains: a token longer than the width. `fold` breaks it mid-token; `fmt` leaves it whole and lets the line run over. `{rollup_script}` interpolates to an absolute path inside the plugin cache — around 96 characters today — so the margin at width 100 is a few characters, and a version bump, a longer marketplace name or a longer home directory spends it. A hard break through that path writes the damage into the file, where the loop reads it every iteration; the display artifact this step exists to fix would become a real one.

**No wrapped line may be exactly `---`.** The hook's body parser is `awk '/^---$/{i++; next} i>=2'`, which skips *every* line matching `^---$`, not only the two frontmatter fences — so such a line is silently dropped from the prompt. Wrapping only ever breaks at existing spaces, so this is reachable only if the body already contains `---` as a standalone token; the template's "use `--` for dashes" rule is what keeps it out, and this is the second reason for that rule.

Wrapping is safe at every layer below: the parser above takes all lines after the frontmatter, and `jq --arg` escapes the newlines into the JSON it feeds back. The prompt is plain text with no markdown, so a line break is whitespace and nothing more — but it is *only* whitespace while no token is broken, which is what the tool choice above protects.

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

**What `active: true` does, and where.** `ralph-loop@ninthspace-ralph` reads the field: anything other than `true` lets the session exit and leaves the state file untouched, so setting it `false` pauses a run and setting it back resumes at the same iteration. On the other two plugins the field is inert — they test termination by the state file's existence alone, so a user who sets it `false` there sees no error and no change, and the loop continues to its iteration cap. **Tell the user which behaviour they have** when reporting the launch (step 1c has already established which hook is installed), because the failure mode is a kill switch that appears to work. On any plugin, deleting `.claude/ralph-loop.local.md` stops the loop — that is the one instruction that holds everywhere.
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

Follow the shared **Progress File Management** procedure, writing to `docs/plans/.cpm-progress-{session_id}.md` — or `docs/plans/.cpm-progress.md` when `CPM_SESSION_ID` is not in context. `/cpm:clean`, the Stale-Progress Check and compaction recovery all locate the file by globbing that exact stem, so one named anything else is invisible to every reader it exists for.

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


## Guidelines

- **Facilitate the setup, automate the execution.** The skill's interactive phase is pre-flight and launch confirmation. Once Ralph starts, everything is autonomous.
- **Deterministic prompts.** Same epics + same config = same prompt. No randomness.
- **Fail fast on pre-flight.** If prerequisites are missing, tell the user immediately — only generate a prompt that can succeed.
- **Dry-run is the default first step.** Always show the user what will run before running it.
- **The execution log is the audit trail.** It survives across Ralph iterations and is the primary post-run artifact for the user to review.
