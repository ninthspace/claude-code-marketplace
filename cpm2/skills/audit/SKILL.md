---
name: cpm2:audit
description: Codebase audit skill. Produces a commit-pinned audit document with `file:line (symbol)` citations across nine dimensions of code health (architectural decay, consistency rot, type & contract debt, test debt, dependency & config debt, performance, error handling & observability, security, documentation drift), then offers pipeline handoffs to library / spec / quick. Triggers on "/cpm2:audit".
---

# Codebase Audit

Run a structured audit of the current codebase, producing a numbered audit document at `docs/audits/{nn}-audit-{slug}.md` with concrete findings, citations, and prioritised recommendations. The skill orients on the codebase, sweeps nine dimensions of code health, and ends by offering to pipe findings into `/cpm2:library`, `/cpm2:spec`, or `/cpm2:quick`.

## Input

The skill is invoked via `/cpm2:audit`. Parse `$ARGUMENTS` as an optional **scope hint**:

1. If `$ARGUMENTS` is empty, the audit covers all nine dimensions evenly across the whole codebase.
2. If `$ARGUMENTS` contains a hint (e.g. `/cpm2:audit auth` or `/cpm2:audit src/billing`), record it as the declared scope. The hint shapes which areas of the codebase receive deeper attention but does **not** cause any of the nine dimensions to be skipped.
3. If the scope hint matches multiple plausible interpretations within the project (e.g. `auth` matches both `src/auth/` and `tests/auth/`), use `AskUserQuestion` to disambiguate before proceeding.

The declared scope is recorded in the deliverable header as `**Scope**: <hint>` and the chosen interpretation seeds orient-phase reads. When no hint is provided, the header records `**Scope**: full sweep`.

## Process

**State tracking**: Create the progress file before Step 1 and update it as orient, sweep, and deliverable generation complete. See State Management below for the format. Delete the file once the deliverable has been saved and the pipeline handoff is resolved.

### Retro Check (Startup)

Follow the shared **Retro Awareness** procedure before the Library Check.

**Retro incorporation** (this skill):
- **Codebase discoveries**: Inform the orient phase — surfaced patterns, conventions, and limitations from past retros are treated as known context rather than rediscovered during the sweep.
- **Patterns worth reusing**: Inform finding-recommendation phrasing — when a past pattern is the right answer, the recommendation column points at it directly.
- **Testing gaps**: Inform the test-debt dimension — past testability observations are folded into evidence-gathering before the sweep produces findings.

### Library Check (Startup)

Follow the shared **Library Check** procedure with scope keyword `audit`. Deep-read selectively when a library document directly affects the current dimension being swept — e.g. coding standards before the consistency-rot dimension, security policies before the security-hygiene dimension.

### Step 1: Orient

Build a baseline understanding of the codebase before any sweep work begins. Orient is reads-only — no findings, no recommendations, no skipping. The output of orient is mental context for Step 2 (Sweep) plus a small set of header values for the deliverable.

#### 1a. Codebase reads

Read the project's surface artifacts so the sweep has a project-shaped baseline rather than starting from a blank slate.

- **README**: Read `README.md`, `README.rst`, or `README` (whichever is present at the project root). If multiple are present, prefer the markdown variant. If none is present, note "No README" and continue.
- **Package manifests**: Read each manifest detected during stack detection (Step 1d). For example, when `package.json` is present read it; when `composer.json` is present read it; same for `pyproject.toml` / `requirements.txt` / `setup.py`, `Cargo.toml`, `go.mod`. Multi-stack projects read every applicable manifest.
- **Top-level directory structure**: List the project root (`ls -la`) so the sweep knows which directories the project organises code into. Do not recursively descend — the sweep handles deep reads when a finding warrants them.

#### 1b. Git history

Capture two views of the project's history so dimensions like architectural decay, consistency rot, and documentation drift have temporal context. Run both invocations during orient:

- **Recent commit summary**: `git log --oneline -200` — gives the shape of activity over the last ~200 commits (cadence, recurring themes, refactor pulses).
- **File-change activity**: `git log --stat --since="6 months ago"` — surfaces which files have churned recently and by how much. This feeds the file ranking in 1c.

If `git` is unavailable or the project is not a git repository, record `Tool: git — not available` under "Open questions" in the deliverable and continue without git-derived signals (graceful degradation rule).

#### 1c. Top-20 file rankings

Identify two ranked lists from the codebase. The intersection is where debt usually hides — large files that change often are the prime suspects for architectural decay, consistency rot, and test debt.

- **Top-20 largest files (by line count)**: Walk the project tree, exclude vendored/generated directories that the project's stack-specific conventions identify (e.g. `node_modules/`, `vendor/`, `target/`, `dist/`, `build/`, `.venv/`, generated migration directories). Rank the remaining files by line count and take the top 20.
- **Top-20 most-modified files (past 6 months)**: From the `git log --stat --since="6 months ago"` output captured in 1b, count distinct file mentions per file and take the top 20.

Compute the intersection of the two lists explicitly. Files appearing in both rankings are noted as priority targets for the sweep.

#### 1d. Commit SHA capture

Pin the audit to a specific commit so findings are reproducible against a known state of the repository. Run `git rev-parse HEAD` during orient and record the resulting 40-character SHA.

The SHA appears in the deliverable header verbatim:

```
**Audited at**: 0123456789abcdef0123456789abcdef01234567
```

If git is unavailable, record `**Audited at**: not a git repository` in the header and add `Tool: git — not available` under "Open questions".

#### 1e. Passive cpm2 artifact read

If the project uses cpm2, read `docs/specifications/`, `docs/epics/`, `docs/briefs/`, and `docs/architecture/` (whichever exist) and surface them to the user as context — list the files found and brief descriptions where useful. The user should know the audit has seen the existing planning material.

> **Non-negotiable**: cpm2 artifact contents must NOT be used to skip any of the nine dimensions, shortcut a finding, or otherwise bias the independent sweep. The audit's value is independent observation. Existing artifacts are read for context only — never to deduce that a dimension "is already covered" or that a finding "has already been planned for". Every dimension is swept on its own merits.

#### 1f. Stack detection

Detect the project's stack(s) from the presence of well-known manifest files at the project root. Detection is cheap, deterministic, and runs before any tooling is invoked.

| Manifest present | Stack detected |
|---|---|
| `package.json` | TS/JS |
| `composer.json` | PHP |
| `composer.json` **and** `artisan` | Laravel (overlay — PHP detection remains active) |
| `pyproject.toml` *or* `requirements.txt` *or* `setup.py` | Python |
| `Cargo.toml` | Rust |
| `go.mod` | Go |

**Multi-stack projects**: every applicable stack is detected and contributes its tooling to Step 2 (Sweep). A polyglot repo with `package.json` + `composer.json` + `artisan` runs the TS/JS, PHP, and Laravel toolchains during the sweep.

**Laravel overlay rule**: when `composer.json` and `artisan` are both present, Laravel is detected **in addition to** PHP — never instead of. Laravel-specific tools (e.g. `larastan`, `pint`, `php artisan about`) run alongside the PHP toolchain (e.g. `composer audit`, `phpstan`/`psalm`). The overlay never replaces; it adds.

Stack detection results are recorded in the progress file under `**Stacks detected**:`.

#### 1g. User-shaping question

After orient is complete and before Step 2 (Sweep) begins, present a single `AskUserQuestion` to give the user one chance to shape where the sweep spends its attention:

> **Question**: "Specific areas to focus on, or sweep all 9 dimensions evenly?"
> **Options**: "Focus on a specific area (provide hint)" / "Sweep all 9 dimensions evenly (Recommended)"

The user's response is recorded as a **focus hint** in the progress file. The hint shapes which files, modules, or dimensions receive deeper attention during the sweep — it does not change which dimensions are run.

> **Non-negotiable**: the user response must NOT be used as license to skip any of the nine dimensions. Every dimension is swept on every run. A focus hint changes weight, not membership. If the user says "just focus on auth", the sweep still runs all nine dimensions across the whole codebase, but pays extra attention to authentication code while doing so.

If a scope hint was supplied via `$ARGUMENTS`, the question is still asked — the hint can be confirmed or refined, but never used to skip dimensions.

### Step 2: Sweep

Sweep the codebase across nine dimensions of code health, in the documented order below. The order is fixed — each dimension builds on signals surfaced by earlier dimensions, and progress signalling depends on the sequence. Every run sweeps every dimension; the focus hint from Step 1g changes weight, never membership.

**Dimension order**:

1. Architectural decay
2. Consistency rot
3. Type & contract debt
4. Test debt
5. Dependency & config debt
6. Performance & resource hygiene
7. Error handling & observability
8. Security hygiene
9. Documentation drift

#### 2a. Architectural decay

- **Scope**: Module boundaries, layering rules, dependency direction, abstraction leaks. Look at the directory structure captured in 1a and the top-20 file rankings from 1c.
- **Signals**: God modules, circular dependencies, layer violations (e.g. UI calling DB directly), shared utility files that have become a graveyard, "coordinator" or "manager" classes with sprawling responsibilities, modules that import from every other module.
- **Evidence**: `file:line (symbol)` citations of boundary violations, dependency-graph cycles (when a tool surfaces them), and structural metrics drawn from manifest/config inspection. The intersection of "largest" and "most-modified" from 1c is a high-yield starting point.

#### 2b. Consistency rot

- **Scope**: Patterns that drift between files — naming conventions, error-handling shapes, return types, parameter ordering, formatting, idiomatic vs. ad-hoc usage of language features.
- **Signals**: Two ways of doing the same thing within the same module, ad-hoc `if/else` where the rest of the code uses pattern matching / strategy / lookup tables, mixed naming (camelCase vs snake_case in the same language), inconsistent error envelopes, "ported" modules retaining their old idioms.
- **Evidence**: Cite both the canonical pattern and the drifted instance, e.g. `src/users/handlers.ts:42 (createUser)` vs `src/billing/handlers.ts:118 (createInvoice)`, with a recommendation to align on the canonical shape.

#### 2c. Type & contract debt

- **Scope**: Type holes (`any`/`unknown`/missing annotations), unchecked casts, weak interfaces, stringly-typed APIs, runtime validators that don't match declared types, contract drift between producer and consumer (DB → ORM, API → client).
- **Signals**: `any`/`mixed` peppered through hot paths, duplicate type definitions that have diverged, parsers that hide errors, optional fields that should be required (or vice versa), DTOs that don't match wire format.
- **Evidence**: Cite each offender with `file:line (symbol)` and reference the contract on the other side (e.g. JSON schema, OpenAPI doc, ORM model) to prove the drift.

#### 2d. Test debt

- **Scope**: Coverage gaps, brittle tests, mocked-too-much tests, slow suites, flaky tests, test-only code paths in production, tests that re-implement the function under test.
- **Signals**: Modules with no tests at all, integration tests that mock everything below the entry point, "TODO: test this" comments, suites that take >5 minutes for trivial change, tests that pass when the implementation is empty.
- **Evidence**: Cite the test file (or the absence of one), the SUT it targets (or fails to), and the specific anti-pattern. Pull stack-tooling output (e.g. coverage reports) into "Open questions" if the tool is missing.

#### 2e. Dependency & config debt

- **Scope**: Outdated dependencies, transitive vulnerabilities, abandoned packages, conflicting version constraints, environment-specific config that's checked into the repo, secrets-in-config, missing config validation.
- **Signals**: `npm audit` / `composer audit` / `pip-audit` / `cargo audit` / `govulncheck` advisories, packages last published >2 years ago and not flagged as "stable", multiple semver-incompatible versions of the same lib in the lockfile, `.env`-shaped files in git.
- **Evidence**: Cite the manifest and lockfile entries; for advisories, cite the tool output verbatim under the finding's recommendation column. **Never quote actual secret values** — citation is the location only.

#### 2f. Performance & resource hygiene

- **Scope**: N+1 queries, sync work in async paths, unbounded loops, leaks (file handles, sockets, listeners), wasteful allocations, missing indexes, blocking the event loop.
- **Signals**: Loops that fire DB queries inside, synchronous file I/O on hot paths, big-O complexity hidden behind innocuous-looking helpers, missing pagination, unbounded recursion.
- **Evidence**: Cite the offending line and identify the pattern. Where stack tooling provides hot-path information (profiler output, slow-query logs), include the tool output as supplementary evidence.

#### 2g. Error handling & observability

- **Scope**: Swallowed exceptions, generic catch-alls, lack of logging, log spam, missing trace context, panic-paths in production, silent failures, error envelopes that lose information.
- **Signals**: `catch { /* ignore */ }`, `except: pass`, log statements with no level/context, error-returns that callers don't check, `panic`/`die` in library code, missing structured logs around external calls.
- **Evidence**: Cite each occurrence; group by class of failure (swallowed vs. logged-and-ignored vs. unhandled).

#### 2h. Security hygiene

- **Scope**: Authentication and authorisation gaps, input validation, SQL/command/template injection surfaces, secrets management, transport security, dependency vulnerabilities (overlap with 2e), CORS, rate limiting, audit logging.
- **Signals**: Hand-rolled crypto, `eval` / `exec` / shell-out with user input, missing CSRF on state-changing routes, secrets read from env without validation, permissive CORS in production code, raw SQL string concatenation.
- **Evidence**: Cite the location only. **Never paste actual secret values, tokens, or credentials into the deliverable, even if you find them in the codebase**. The finding describes the class of issue and points at the file:line; it does not echo the value.

#### 2i. Documentation drift

- **Scope**: README claims that no longer hold, code comments that contradict the code, API docs that describe deleted endpoints, internal docs (`docs/`) that reference old architecture, missing docs for newly added subsystems.
- **Signals**: README setup steps that fail, comments saying "this returns X" when the code returns Y, OpenAPI/Swagger files diverging from handlers, architecture diagrams citing deleted services.
- **Evidence**: Cite both sides of the drift — the doc location and the contradicting code location.

For each dimension, capture findings with `file:line (symbol)` citations. The capture format feeds directly into the findings table in Step 3.

#### 2j. Stack-specific tool execution

For each stack detected in 1f, invoke at least one tool from the list below and feed its output into the relevant dimensions. The toolset is recommended, not exhaustive — projects with stronger linting setups can add their own.

| Stack | Tools (invoke at least one) | Feeds dimensions |
|---|---|---|
| TS/JS | `npm audit`, `npx knip`, `npx madge --circular`, `npx depcheck`, `tsc --noEmit` | 2a, 2c, 2e |
| PHP | `composer audit`, `composer outdated`, `phpstan` *or* `psalm` | 2c, 2e |
| Laravel (overlay) | `larastan`, `pint`, `php artisan about` | 2a, 2b, 2c |
| Python | `pip-audit`, `ruff check`, `vulture`, `pydeps --show-cycles`, `mypy --strict` | 2a, 2b, 2c, 2e |
| Rust | `cargo audit`, `cargo udeps`, `cargo machete`, `cargo clippy -- -W clippy::pedantic` | 2b, 2c, 2e |
| Go | `govulncheck`, `go vet`, `staticcheck`, `golangci-lint run` | 2b, 2c, 2e |

Multi-stack projects invoke tooling from every detected stack. Laravel runs **in addition to** PHP — its tools layer onto the PHP toolset, never replace it.

Tool output is parsed structurally where possible: vulnerability counts, circular-dependency lists, type-error counts, lint-rule violations. Each parsed output feeds the dimension(s) it most naturally matches and contributes to findings table rows in Step 3 with `file:line (symbol)` citations where the tool surfaces them.

#### 2k. Graceful tool degradation

Stack tools are best-effort. Any of these outcomes count as a failure:

- The binary is missing (e.g. `composer` not installed).
- The tool exits non-zero in a way that's not "found findings" (e.g. parse error, internal crash).
- The tool times out (target: 60s per tool, project-tunable).
- The output is unparseable.

For each failure, add a single line to the deliverable's "Open questions" section in the form:

```
Tool: <name> — <reason>
```

For example: `Tool: phpstan — binary not found`, `Tool: cargo audit — exited 124 (timeout)`.

> **Non-negotiable**: a tool failure must NOT abort the audit. The sweep continues to the next dimension. The audit always produces a complete deliverable; tool gaps live in "Open questions", not in the absence of an audit.

#### 2l. Run-time progress signalling

At the start of each of the nine dimensions, emit a single transition message in the form:

```
Sweeping dimension N/9: <name>...
```

For example: `Sweeping dimension 1/9: architectural decay...`, `Sweeping dimension 5/9: dependency & config debt...`. This gives the user a visible heartbeat across what can be a multi-minute sweep. The message is a status line, not a finding — it does not appear in the deliverable.

#### 2m. Re-orientation on failure

When a stack tool surfaces a finding that invalidates a recommendation already drafted earlier in the same run — for example `composer audit` flagging a CVE in a package the architectural-decay dimension was about to recommend extracting a helper into — re-orient on the spot:

1. **Update the earlier recommendation** to reflect the new evidence. The drafted finding's recommendation column is rewritten so the deliverable doesn't ship contradictory advice.
2. **Note the conflict** in the deliverable's "Open questions" section in the form: `Conflict: <dimension X recommendation> superseded by <dimension Y finding>`. This makes the change transparent to the reader.

Re-orientation runs once per conflict; do not loop. If a third dimension surfaces evidence that conflicts with both the original and the revised recommendation, the open-question entry is amended, not duplicated.

### Step 3: Deliverable Generation

The deliverable is a numbered markdown document at `docs/audits/{nn}-audit-{slug}.md`. Follow the shared **Numbering** procedure to assign `{nn}` — integer comparison across active and archived audits in `docs/audits/`, retired numbers stay retired, growth past 99 is transparent. The slug is derived from the scope hint (when supplied) or "full-sweep" otherwise, lowercase-hyphenated.

If `docs/audits/` does not exist, create it before writing the deliverable.

#### 3a. Deliverable structure

The deliverable opens with a header, then proceeds through eight sections in fixed order. Use exactly the section headings shown — downstream skills key off them.

**Header**:

```markdown
# Audit: <project name>

**Date**: YYYY-MM-DD
**Audited at**: <40-char-sha>
**Scope**: <hint or "full sweep">
```

**Sections** (in order):

1. **`## Executive Summary`** — Maximum 10 bullets, ranked by impact. Each bullet summarises a finding or theme with severity. The last bullet line is the effort aggregate (Step 3g): `Effort: S×<n>, M×<n>, L×<n>`.
2. **`## Architectural Mental Model`** — One or two paragraphs. Plain prose describing how the codebase is organised — entry points, dominant patterns, where logic lives. This is the audit's compressed understanding of the system, useful for any reader who comes to the deliverable cold.
3. **`## Findings`** — Markdown table with the columns documented in 3b. Target 30–80 rows for typical projects.
4. **`## Top 5 Priorities`** — Five concrete refactor outlines, drawn from the findings table. Each priority is a 2–4 sentence outline: what to change, where, and the expected outcome. References the finding ID(s) that motivate it.
5. **`## Quick Wins`** — Checklist (`- [ ] ...`) of small, low-risk changes drawn from the findings table. Each item should be doable in under an hour.
6. **`## Things that look bad but are actually fine`** — Bullet list of patterns or signals an inexperienced reader might flag, with a one-line justification per item explaining why they are correct as-is. **Required, non-negotiable**: this section must always appear, even if it has only one entry. Its presence makes clear the audit considered counter-evidence.
7. **`## Open Questions`** — Bullet list. Tool failures (`Tool: <name> — <reason>`), conflicts surfaced by re-orientation (`Conflict: <X> superseded by <Y>`), and items the audit could not resolve without more information.

> **Non-negotiable**: section 6 ("Things that look bad but are actually fine") is required on every audit. Omission is not allowed even when the audit found nothing in this category — pick the most counter-intuitive accept-as-is observation and write the one-liner.

#### 3b. Findings table columns

The findings table uses exactly these column headers, in this order:

| ID | Category | Citation | Severity | Effort | Description | Recommendation |
|---|---|---|---|---|---|---|
| F-001 | Architectural decay | `src/auth/login.ts:42 (authenticate)` | High | M | One-sentence problem description. | Scoped recommendation. |

- **ID**: sequential, prefixed `F-` (e.g. `F-001`, `F-002`), zero-padded to 3 digits.
- **Category**: one of the nine dimension names from Step 2.
- **Citation**: `file:line (symbol)` exactly. See 3c.
- **Severity**: Critical / High / Medium / Low. See 3d.
- **Effort**: S / M / L. See 3d.
- **Description**: one sentence describing the problem.
- **Recommendation**: one to three sentences scoping the change (no rewrites — see 3e).

#### 3c. Citation format

Every concrete finding cites a location in `file:line (symbol)` format. The `(symbol)` portion is optional when the location does not correspond to a named symbol (e.g. config files, top-level imports). Examples across stacks:

| Stack | Citation example |
|---|---|
| TS/JS | `src/auth/login.ts:42 (authenticate)` |
| PHP | `app/Http/Controllers/UserController.php:87 (store)` |
| Python | `app/services/billing.py:124 (calculate_invoice)` |
| Rust | `src/parser/lexer.rs:201 (Lexer::next_token)` |
| Go | `internal/server/handlers.go:53 (HandleLogin)` |
| Config | `composer.json:14` (no symbol) |

> **Non-negotiable**: citations must NOT quote actual secret values, tokens, or credentials, even when the finding is about a hard-coded secret in the codebase. The citation is the location only. A finding like "API key checked into source" has the citation `src/config/keys.ts:11` and a description that says a hard-coded secret was found — it does not include the secret's value. This rule is absolute.

#### 3d. Severity and effort scales

Severity uses **Critical / High / Medium / Low** — exactly these four values, exactly this casing.

- **Critical**: actively harmful in production (data loss, security exposure, runtime crashes). Block the next deploy.
- **High**: notable risk or developer-velocity drag. Address in current cycle.
- **Medium**: legitimate debt with bounded impact. Address opportunistically.
- **Low**: tidy-up. Doesn't materially affect anyone today, but the citation captures it for the record.

Effort uses **S / M / L** — exactly these three values, exactly this casing.

- **S** (Small): under an hour for one engineer who knows the area. Quick-wins material.
- **M** (Medium): one to a few days. Within a single sprint.
- **L** (Large): more than a sprint, or touches multiple modules / requires coordinated changes.

Pick the value that fits the **specific recommendation** as written, not the size of the original problem. A High-severity issue can have an S-effort recommendation if the fix is a one-line change.

#### 3e. No-rewrites rule

Recommendations describe **scoped changes**: which file, which symbol, what to change, and what to change it to. Acceptable phrasing patterns:

- "Extract `<symbol>` from `<file>` into `<new-file>` and inject it into `<consumer>`."
- "Replace the manual loop in `<file>:<line>` with a `Map.entries()` walk to remove the index bookkeeping."
- "Add a JSON schema validator at the boundary in `<file>:<line>`; let the existing branches handle invalid shapes."

> **Non-negotiable**: recommendations must NOT use the phrases "rewrite", "replace entirely", "rebuild", "ground-up rewrite", or any equivalent language that implies wholesale module/file/system replacement. The audit's job is to surface fixable debt, not to license large rewrites. If a finding genuinely warrants a rewrite, that's a discussion for `/cpm2:spec` and `/cpm2:architect` — the audit document records the symptom, not the rewrite recommendation.

#### 3f. No-padding rule

Empty dimension sections are **omitted entirely** from the deliverable. Do not insert "Nothing material", "N/A — no findings", "Empty section", or any other placeholder content for dimensions that produced no findings. The findings table simply contains no rows for that category, and no narrative is added.

> **Non-negotiable**: the deliverable must NOT contain "Nothing material" placeholders or filler content for empty categories. Padding signals to the reader that the audit was box-ticking; absence signals confidence. Trust the reader to notice an absent category.

This rule applies whether the absence is because nothing was found (full-sweep audit, dimension came up clean) or because the dimension was scope-shaped out (Step 3g). The deliverable shape is the same — empty categories simply don't appear.

#### 3g. Scoped audit consistency

When a scope hint is provided (via `$ARGUMENTS` or the post-orient question in 1g), the deliverable's structural shape stays identical to a full-sweep deliverable: same header section, same seven body sections, same findings table columns. Only two things differ:

1. The header records `**Scope**: <hint>` (e.g. `**Scope**: src/auth`) instead of `**Scope**: full sweep`.
2. Dimensions outside the hint that produced no findings are omitted from the findings table under the no-padding rule (3f).

The "Things that look bad but are actually fine" section (3a §6) and the "Open questions" section remain present even on scoped audits — the non-negotiable on §6 applies regardless of scope.

A scoped audit and a full-sweep audit on the same project at the same SHA must be readable side-by-side without structural reformatting. A reader who diffs them sees the same outline; the difference is in row count and section length, not in section shape.

#### 3h. Effort aggregates

The executive summary's last bulleted line summarises the total effort across all findings, in the form:

```
Effort: S×<count>, M×<count>, L×<count>
```

For example: `Effort: S×12, M×7, L×3`. The `×` is a multiplication sign (U+00D7), not a lowercase `x`. Each count equals the number of findings table rows whose Effort cell equals the corresponding scale value.

When a count is zero, omit that scale value from the line — `Effort: S×4, M×2` rather than `Effort: S×4, M×2, L×0`.

### Step 4: Pipeline Handoffs

After the deliverable is saved, present a single `AskUserQuestion` offering four ways to flow the findings into the rest of the cpm2 pipeline:

> **Question**: "Audit complete. What next?"
> **Options**:
> - "Send findings to `/cpm2:library`" — wrap the audit as a library reference document so other cpm2 skills can pick it up via Library Check.
> - "Promote priorities to `/cpm2:spec`" — invoke the spec skill on the audit document path so the Top 5 Priorities can become a structured spec.
> - "Run quick wins through `/cpm2:quick`" — invoke the quick skill on the audit document path so the checklist can be processed item-by-item.
> - "Done" — end the session; no downstream invocation.

#### 4a. Library handoff

When the user selects the library option:

1. Use `AskUserQuestion` to collect **scope keywords** for the library entry. Offer the nine dimension names (architectural-decay, consistency-rot, type-debt, test-debt, dependency-debt, performance, error-observability, security, documentation-drift) plus a freeform option, with `multiSelect: true` so the user can pick the dimensions the audit's findings touch most heavily. The keyword `audit` is always added automatically.
2. Compute the next library number using the shared **Numbering** procedure (active + archive across `docs/library/`).
3. Write a wrapper entry at `docs/library/{nn}-library-audit-{slug}.md` where `{slug}` matches the source audit document's slug. The file's body references the audit document by relative path; the frontmatter records the scope keywords and a one-line description.

**Frontmatter shape**:

```yaml
---
title: Audit findings — <project name> (<YYYY-MM-DD>)
description: Codebase audit findings with file:line citations across <N> dimensions.
scope:
  - audit
  - <scope keyword>
  - <scope keyword>
source: docs/audits/{nn}-audit-{slug}.md
---
```

This is the **single library wrapper entry per audit** approach (per Architecture Decision 6). One wrapper, one number, one entry — fragmentation by dimension is deferred.

#### 4b. Spec handoff

When the user selects the spec option, invoke the spec skill via the Skill tool, passing the audit document path as args:

```
Skill(skill: "cpm2:spec", args: "docs/audits/{nn}-audit-{slug}.md")
```

`/cpm2:spec` already accepts file-path `$ARGUMENTS` — the audit document is the contract.

#### 4c. Quick handoff

When the user selects the quick option, invoke the quick skill via the Skill tool, passing the audit document path as args:

```
Skill(skill: "cpm2:quick", args: "docs/audits/{nn}-audit-{slug}.md")
```

`/cpm2:quick` will read the audit, classify the request, and walk the quick wins checklist as the change description.

#### 4d. Done

When the user selects Done, end the session with no further skill invocation. The progress file (see State Management) is deleted.

#### 4e. Scope hint disambiguation

If the original `$ARGUMENTS` scope hint matches multiple plausible interpretations within the project, the disambiguation runs **before** orient — not at handoff time. Detect the ambiguity by globbing for matches across the project root:

- `auth` matches both `src/auth/` and `tests/auth/` → ambiguous.
- `billing` matches `app/billing/`, `lib/billing.ts`, and `docs/billing/` → ambiguous.

When ambiguity is detected, present an `AskUserQuestion` listing the candidate interpretations (top 3 by file count) with a "Sweep all matches" fallback option. The chosen interpretation seeds orient-phase reads; "Sweep all matches" treats the union as the focus area.

Disambiguation runs at most once per audit run. After the user picks, the resolved scope is recorded in the progress file under `**Scope (resolved)**:`.

## State Management

Follow the shared **Progress File Management** procedure.

**Lifecycle**:
- **Create**: before Step 1 (Orient).
- **Update**: at each step transition (orient complete, sweep dimension N/9 complete, deliverable saved, handoff resolved).
- **Delete**: only after the deliverable is saved and the pipeline handoff has been resolved.

**Format**:

```markdown
# CPM Session State

**Skill**: cpm2:audit
**Current step**: {orient | sweep N/9 | deliverable | handoff}
**Scope**: {hint or "full sweep"}
**Commit SHA**: {40-char SHA captured during orient}
**Stacks detected**: {list, e.g. "TS/JS, PHP, Laravel"}

## Notes
{Running notes — surfaced findings, tool failures, dimensions completed.}

## Next Action
{What to do next}
```

## Guidelines

- **Cite, don't quote.** Every concrete finding cites a `file:line (symbol)` location. Never paste actual secret values into the deliverable, even for security-hygiene findings — the citation is the location only.
- **No rewrites.** Recommendations describe scoped changes only. Phrases like "rewrite", "replace entirely", or full-module replacement guidance are forbidden.
- **No padding.** Empty dimension sections are removed from the deliverable. Never insert "Nothing material" placeholders or filler content.
- **Independence from cpm2 artifacts.** `docs/specifications/`, `docs/epics/`, `docs/briefs/`, `docs/architecture/` are read as passive context only. They must not bias or shortcut the independent sweep.
- **Tool failures never abort.** Missing/failing/timed-out stack tools are recorded as `Tool: <name> — <reason>` under "Open questions" and the audit continues.
