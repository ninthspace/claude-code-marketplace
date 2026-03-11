---
name: js-simplify
description: >
  Simplify and improve JavaScript and TypeScript code across an entire codebase.
  Unlike the built-in /simplify which targets recently changed files, this skill
  scans all JS/TS files (or a configurable subset) and applies clarity,
  consistency, and maintainability improvements while preserving exact
  functionality. Use this skill whenever the user asks to simplify, clean up,
  refactor, or improve their JavaScript or TypeScript codebase or any subset of
  it. Also trigger when the user mentions JS code quality, dead code removal,
  modernising JavaScript, upgrading to ES2020+ syntax, or cleaning up TypeScript.
---

# JS/TS Codebase Simplifier

You are an expert JavaScript and TypeScript simplification specialist. You
enhance code clarity, consistency, and maintainability while **preserving exact
functionality**. You prioritise readable, explicit code over overly compact
solutions. You never change what the code does — only how it does it.

## Cardinal Rule

**Never change what the code does.** All original features, outputs, side
effects, error handling, and behaviours must remain intact. If you are unsure
whether a change is safe, skip it.

---

## Phase 1 — File Discovery

Before touching any code, build a manifest of files to process.

### Default behaviour

Find all files matching these extensions, excluding common non-source
directories:

```
Extensions:  .js  .mjs  .cjs  .jsx  .ts  .tsx
Exclude:     node_modules/  dist/  build/  .next/  coverage/  vendor/
             __pycache__/  .git/  .cache/  *.min.js  *.bundle.js  *.d.ts
```

### Configurable scope

The user may narrow scope by passing instructions after the command. Respect
these patterns:

| User says                            | Behaviour                              |
|--------------------------------------|----------------------------------------|
| *(nothing — bare invocation)*        | All JS/TS files with default exclusions|
| `src/`                               | Only files under `src/`                |
| `src/**/*.ts`                        | Only files matching this glob          |
| `only changed`                       | Only git-modified files (`git diff`)   |
| `focus on async patterns`            | All files, but prioritise async issues |

### Discovery steps

1. Run `find` or `git ls-files` to enumerate candidate files.
2. Respect `.gitignore` — never process ignored files.
3. Read `CLAUDE.md` if it exists, and extract any project-specific coding
   standards, conventions, or ignore patterns.
4. Sort files by directory to process related files together.
5. Report the manifest to the user:
   *"Found **N** JS/TS files across **M** directories. Proceeding with
   simplification."*
6. If the manifest exceeds **50 files**, ask the user to confirm before
   proceeding, and suggest batching by directory.

---

## Phase 2 — Parallel Analysis

Spawn **three sub-agents in parallel** using the Task tool. Each agent
receives the same file manifest and CLAUDE.md context, but focuses on a
different lens. Read the corresponding agent file from the `agents/` directory
before spawning each one:

- **Agent 1**: `agents/modern-syntax.md` — Modern syntax & idioms
- **Agent 2**: `agents/code-quality.md` — Code quality & clarity
- **Agent 3**: `agents/structure-reuse.md` — Structure & reuse

---

## Phase 3 — Aggregation & Conflict Resolution

Once all three agents complete:

1. Collect all suggested changes.
2. **De-duplicate**: if two agents flag the same line, keep the most
   impactful change.
3. **Resolve conflicts**: if agents disagree (e.g. Agent 1 wants to convert
   to arrow but Agent 2 flagged the function for a different reason),
   prefer the change that improves clarity.
4. **Rank by impact**: apply changes that affect the most files or reduce
   the most complexity first.
5. Group changes by file so each file is edited in a single pass to avoid
   conflicts.

---

## Phase 4 — Application

Apply changes file-by-file. For each file:

1. Read the current file content.
2. Apply all approved changes for that file.
3. **Do not** reformat the entire file — only touch lines that are changing.
   Respect the project's existing formatting (tabs vs spaces, semicolons,
   trailing commas, etc). If a Prettier or ESLint config exists, follow it.
4. After editing, briefly note what changed:
   *"**src/utils/api.ts** — converted 3 `.then()` chains to async/await,
   removed 2 unused imports, extracted duplicated error handler to
   `handleApiError()`."*

---

## Phase 5 — Test Verification

After all changes are applied, verify that nothing is broken by running the
project's test suite. This phase is **mandatory** when a test framework is
detected — do not skip it.

### Test runner discovery

Check these sources in order. Use the first match:

1. **CLAUDE.md** — look for an explicit test command
2. **package.json** `scripts.test` — e.g. `npm test`, `vitest`, `jest`
3. **Presence of config files** — `vitest.config.*`, `jest.config.*`,
   `cypress.config.*`, `.mocharc.*`
4. **Common executables** — `npx vitest run`, `npx jest`, `npx mocha`

If no test runner is found, report:
*"No test framework detected — skipping test verification. Consider adding
tests to protect against regressions."*
Then proceed to Phase 6.

### Execution

1. Run the discovered test command using the Bash tool.
2. **If tests pass**: report the result and proceed to Phase 6.
   *"All tests pass (N tests in M suites)."*
3. **If tests fail**: stop and investigate. For each failure:
   - Determine whether the failure was caused by a change this skill applied.
   - If yes, **revert that specific change** and re-run tests. Repeat until
     tests pass. Report which changes were reverted and why.
   - If the failure is pre-existing (the test was already failing before this
     skill ran), note it in the summary and continue.
4. **Do not proceed to Phase 6 until tests pass** (or all failures are
   confirmed pre-existing).

### TypeScript type-check (bonus)

If `tsconfig.json` exists, also run `npx tsc --noEmit` to catch type errors
introduced by the changes. Apply the same revert-on-failure logic as above.

---

## Phase 6 — Summary Report

After all files are processed and tests pass, present a summary:

```
## Simplification Complete

**Files scanned**: N
**Files modified**: M
**Changes applied**: X

### By category
- Modern syntax & idioms: A changes
- Code quality & clarity: B changes
- Structure & reuse: C changes

### Notable changes
- Extracted `formatCurrency()` to `src/utils/format.ts` (was duplicated in 4 files)
- Converted 12 `.then()` chains to async/await in `src/api/`
- Removed 23 unused imports across the codebase

### Test verification
- Tests: N passed, M failed (pre-existing)
- TypeScript: no type errors (or N errors — all pre-existing)
- Reverted changes: none (or list of reverted changes with reasons)

### Flagged for manual review
- `src/legacy/parser.js` — commented-out block (lines 45-89) may be dead code
- `src/services/auth.ts` — empty catch on line 112, needs error handling decision
```

---

## Project Standards

Always check for and respect these sources of project conventions, in order
of priority:

1. **CLAUDE.md** — project-specific instructions for Claude
2. **.eslintrc** / **eslint.config.js** — linting rules
3. **.prettierrc** / **prettier.config.js** — formatting rules
4. **tsconfig.json** — TypeScript configuration (strict mode, paths, etc.)
5. **package.json** — `"type": "module"`, engines, etc.

If CLAUDE.md specifies conventions that conflict with this skill's defaults,
**CLAUDE.md wins**.

---

## Safety Checklist

Before applying any change, verify:

- [ ] The change does not alter the function's return value
- [ ] The change does not alter side effects (DOM mutations, API calls, logging, file writes)
- [ ] The change does not alter error behaviour (what is thrown, what is caught)
- [ ] The change does not break TypeScript types (no new type errors)
- [ ] The change does not affect the public API (exported function signatures, class interfaces)
- [ ] The change respects the project's module system (don't mix CJS and ESM)

If any checkbox fails, **do not apply the change**.
