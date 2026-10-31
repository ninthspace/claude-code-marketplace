# Commit guard

**Source spec**: docs/specifications/49-spec-cheaper-red-first-evidence.md  
**Date**: 2026-10-31  
**Status**: Complete  
**Blocked by**: —  
**Lessons**: docs/library/01-library-lessons-learned.md → "A check that passes may be passing for a reason other than the one you want" (Story 1), docs/library/01-library-lessons-learned.md → "A control is only a control once you have watched it fail, and read why" (Story 1)  
**Amended**: 2026-10-31 — the guard refuses only commits in a checkout a pass directory's `tree` names (spec FR5 amended after review 07, docs/reviews/07-review-red-passes.md)

## cpm-next refuses a commit while a red pass is open
**Story**: 1  
**Status**: Complete  
**Audit**: pass (2026-10-31), 3 findings fixed — the last fix was not audited, at the user's decision
**Blocked by**: —  
**Satisfies**: FR5, NFR3, NFR4  
**Effort**: high  
**Signal**: fix-introduced-defect — project — a fix for quoted commit options (`ARG`) made the commit pattern backtrack exponentially on about 20 quoted options (`cpm-next/hooks/guard.ts:14`, second audit, Warning)  
**Signal**: unprovable-in-session — project — the guard takes the checkout from `$.session.cwd()`, and the engine documents no directory per subagent loop, so a worktree subagent's own commit is not shown to be checked (`cpm-next/hooks/register.ts`, audit round 1 of this story)  
**Pivot deferred**: FR5's "by the main session or a subagent" holds only if the engine reports a worktree subagent's directory, which nothing in the declarations shows; word it as the main session's checkout, with a worktree subagent covered by `worktree.md`'s rule to commit only after its pass directory is gone → docs/specifications/49-spec-cheaper-red-first-evidence.md (Story 1, 2026-10-31) — cited: `cpm-next-progress/.claude-plugin/types/claude-code/index.d.ts:2548-2551` (`cwd` is "the directory the session runs in") and `:313-316`, `AgentInfo` (`:121-160`) with no directory

**Acceptance Criteria**:

- cpm-next has `hooks/hooks.json` naming one module, the module, a test file, a `tsconfig.json`, and a root `.gitignore` entry for `cpm-next/.claude-plugin/types/`; `claude plugin validate cpm-next` passes `[manual]`
  - Evidence: `cpm-next/hooks/hooks.json` names `./register.ts`; `cpm-next/hooks/register.ts`, `guard.ts`, `guard.test.ts` and `cpm-next/tsconfig.json` exist; `.gitignore` ends with `cpm-next/.claude-plugin/types/`; `claude plugin validate cpm-next` — Validation passed — red: n/a — manual
- A `git commit` run through the Bash tool is refused while `{common dir}/cpm-next/scratch/` holds a directory whose `tree` file names the checkout the commit runs in, and the refusal names each such directory and tells the user to resume `/cpm-next:do` on it or copy its files back `[unit]`
  - Evidence: a commit is refused while a pass directory names this checkout, naming the directory (`cpm-next/hooks/guard.test.ts:86`, `claude plugin test cpm-next`); a cwd reached through a symlink still matches (`:135`); only a file in the scratch folder is no pass (`:152`) — red: Expected: containing "49-01-epic-red-passes-2", Received: undefined with mutation of `guard.ts` `openPasses`: `if (!(await fs.exists(scratch)) || scratch !== '') return []`; and Expected: containing "red pass", Received: undefined (`:135`) with mutation of `checkoutOf`: `const top = dir` in place of `fs.real(dir)`; and Expected: undefined, Received: "A red pass is open in this checkout: .keep …" (`:152`) with mutation of `openPasses`: the `entry.kind !== 'dir'` line removed and the unreadable `tree` read as this checkout
- A commit passes when the scratch folder is absent, when it exists but is empty, and when its only directory's `tree` names another checkout, each in a fixture that otherwise holds a repository with a `.git` directory; the last uses the same directory as the refused case with only `tree` changed `[unit]`
  - Evidence: a commit passes when there is no scratch folder, when it is empty (a directory with no entry), and when the pass names another checkout (`guard.test.ts:101`, `claude plugin test cpm-next`; the last assertion uses the refused case's fixture with only `tree` changed) — red: Expected: undefined, Received: "A red pass is open in this checkout: 49-01-epic-red-passes-2 …" with mutation of `guard.ts` `openPasses`: `if (tree === checkout.top)` → `if (tree !== undefined)`
- `git commit` reached through `cd {dir} && git commit` and through `git -C . commit` is refused while a scratch directory names this checkout `[unit]`
  - Evidence: commits reached through cd and git -C are refused (`guard.test.ts:96`), and git commit is recognised through quoted and space-separated global options (`:55`), in the earlier forms (`:42`), a run of 26 quoted options ending in another subcommand and an unterminated quote are judged in under 250 ms (`:74`), and an option argument that is only partly quoted is recognised (`:64`) (`claude plugin test cpm-next`) — red: Expected: containing "red pass", Received: undefined (`:96`) with mutation of the `COMMIT` pattern in `guard.ts`: leading `(^|[\s;&|()])` → `(^)` and `-C\s+\S+` removed; and Expected: true, Received: false (`:55`) with mutation of `ARG`: the quoted alternatives removed; and Expected: < 250, Received: 2084 (`:74`) with mutation of `ARG` back to `("[^"]*"|'[^']*'|\S+)`, the pattern that backtracks exponentially; and Expected: true, Received: false (`:64`) with mutation of `ARG` to `("[^"]*"|'[^']*'|[^\s"']\S*)`, the form that no longer sees a partly quoted word such as `-C "$HOME"/wt`
- In a worktree whose `.git` file points to the main repository's directory (`commondir`), a commit is refused while a directory in the main repository's scratch folder names that worktree, and passes while the only directory names the main checkout `[unit]`
  - Evidence: a worktree finds the main repository's scratch folder through commondir (`guard.test.ts:117`) and a pass in a worktree does not block the main checkout, nor the reverse (`:123`) (`claude plugin test cpm-next`) — red: Expected: { top: "/work/app-wt", common: "/work/app/.git" } (`:117`) with mutation of `guard.ts` `checkoutOf`: `common = gitDir` in place of the `commondir` lookup; and Expected: undefined (`:123`) with the `tree` check ignored as above
- A Bash command that is not a `git commit` passes, in a fixture that holds a scratch directory, without the module reading any file `[unit]`
  - Evidence: a command that is not a commit reads nothing, even with a pass open (`guard.test.ts:139`, `claude plugin test cpm-next`; `register.ts` also returns before asking for the working directory) — red: Expected: undefined, Received: "A red pass is open in this checkout: …" with mutation of `guard.ts` `decide`: the `if (!isCommit(command)) return undefined` line removed
- Control: with the scratch check removed from the module, the refused-commit tests fail; the failure is recorded in the `Evidence` line `[unit]`
  - Evidence: the reds above are this control: with `openPasses` returning nothing the refused-commit tests `guard.test.ts:86`, `:92`, `:96`, `:117` fail — red: Expected: containing "49-01-epic-red-passes-2", Received: undefined with mutation of `guard.ts` `openPasses` as above
- `claude plugin test cpm-next` passes, and `tsc -p cpm-next` passes once the types are laid `[manual]`
  - Evidence: `claude plugin test cpm-next` — 15 pass, 0 fail; `tsc` over `cpm-next/hooks` against the types laid for `cpm-next-progress` (cpm-next has none laid, a headless `--plugin-dir` load did not lay them) printed no errors; the other mods still pass: cpm-next-models 18, cpm-next-progress 46, whats-next 18 — red: n/a — manual

### Package the module and write the tests
**Task**: 1.1  
**Description**: Add the hooks module, its manifest, tests and tsconfig under `cpm-next/`, and the `.gitignore` entry.  
**Status**: Complete

---
