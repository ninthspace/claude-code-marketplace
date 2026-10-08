# Claude Code Marketplace — Development Guidelines

## `docs/` holds this repository's planning history

CPM and DPM were withdrawn from this marketplace on 2026-10-08, and their source was removed. `docs/` was generated from DPM's database until then; it is now plain files in git. Nothing regenerates it and no commit guard checks it. The CPM-era corpus stays under `docs/cpm/`; cite it by that path. Both plugins' source is in git history before the withdrawal commit.

## A push to main updates this machine's plugin installs

`.git/hooks/pre-push` is a link to `bin/pre-push`. On a push to `main` it starts `bin/update-installed-plugins.sh` in the background, which waits until `origin/main` holds the pushed commit, updates the marketplace, and runs `claude plugin update --scope user` for each installed plugin whose version differs from `marketplace.json`. The `plugin-sync` mod then reloads open sessions. Output goes to `.git/plugin-update.log`; the hook never blocks or fails the push. A plugin only updates when its version was bumped. Re-make the link if it is ever lost:

```sh
ln -sf "$(git rev-parse --show-toplevel)/bin/pre-push" .git/hooks/pre-push
```

## Critical: Source vs. Cache Paths

This repository contains the source code for multiple plugins: `cpm-next`, `cpm-next-models`, `cpm-next-progress`, `plugin-sync`, `noteplan`, `php-lsp`, `js-simplifier`, `filament-mockup`, `whats-next`, `generated-files`, `weather`.

**NEVER read or write files in the plugin cache directory** (`~/.claude/plugins/cache/ninthspace-marketplace/`). That directory contains installed copies of plugins and is overwritten on updates. Changes made there are lost and not tracked by git.

**ALWAYS use the source files in this repository.** Each plugin has its own top-level directory:

| Plugin | Source directory |
|--------|----------------|
| CPM Next | `cpm-next/` |
| CPM Next Models | `cpm-next-models/` |
| CPM Next Progress | `cpm-next-progress/` |
| Plugin Sync | `plugin-sync/` |
| NotePlan | `noteplan/` |
| PHP LSP | `php-lsp/` |
| JS Simplifier | `js-simplifier/` |
| Filament Mockup | `filament-mockup/` |
| What's Next | `whats-next/` |
| Generated Files | `generated-files/` |
| Weather | `weather/` |

Common source locations (using cpm-next and its mods as examples — the same pattern applies to all plugins):

| What | Source (use this) | Cache (never touch) |
|------|-------------------|---------------------|
| Skill files | `cpm-next/skills/` | `~/.claude/plugins/cache/.../skills/` |
| Agent definitions | `cpm-next/agents/` | `~/.claude/plugins/cache/.../agents/` |
| Mod hooks | `cpm-next-models/hooks/` | `~/.claude/plugins/cache/.../hooks/` |
| Mod tests | `cpm-next-models/hooks/*.test.ts` | `~/.claude/plugins/cache/.../hooks/` |

When a skill file references relative paths (e.g. `../../agents/roster.yaml`), translate that to the equivalent path under the plugin's source directory in this repo.

If you catch yourself reading from or writing to `~/.claude/plugins/cache/`, **stop and redirect to the repo source**.

**Exception**: When a skill is actively running (e.g. `/cpm-next:plan`, `/cpm-next:do`), it reads its own SKILL.md instructions from the cache — that's normal runtime behaviour. The rule above applies to **development work**: editing skill files, mod hooks, test suites, agent definitions, or any other plugin source code.

## A SKILL.md is not a change log

A skill file says what the skill does, and gives the rationale a maintainer needs in order not to break a rule. It does not record how it came to be: what a past spec decided, what used to be in this step, why an earlier design was wrong, or that a paragraph was worded a particular way after an incident. That history belongs in the plugin's README log, the retro, and the commit — none of which are loaded at runtime.

The distinction is not "prose versus instructions". Rationale is welcome and often load-bearing, because an agent that doesn't know why a rule is there will route around it. The test is what the sentence is *about*. A sentence about the rule stays. A sentence about the rule's biography goes — including when it is true, well-written, and hard-won.

Reach is what makes it different from an ordinary documentation choice. A SKILL.md is loaded in full on every invocation of that skill, in every project the plugin is installed in. A note explaining a removal is paid for on every run, forever, by readers who never knew the removed thing existed.

Two things make it hard to catch. Skills already instruct their *runtime output* to record a decided absence — and those rules are correct, so the instinct is right one directory over and wrong here. And no metric finds it: citation counts and commentary-density both rank clean files top. Read the file. Evidence, and the passages removed in the 2026-07-28 sweep: `docs/cpm/quick/29-quick-skill-construction-prose-sweep-spec.md`.

**The same rule covers maintenance records, and they have one home.** Coupling to external components, formats a plugin writes that something else parses, tables kept so a maintainer notices when a dependency moves — none of it belongs in a skill, and a pointer from a skill is still a line every invocation pays for. It all lives in **`docs/maintenance/README.md`**, which this file is the only thing that references.
