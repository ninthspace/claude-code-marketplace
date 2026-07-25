# Claude Code Marketplace — Development Guidelines

## Critical: Source vs. Cache Paths

This repository contains the source code for multiple plugins: `cpm`, `noteplan`, `php-lsp`, `js-simplifier`, `filament-mockup`.

**NEVER read or write files in the plugin cache directory** (`~/.claude/plugins/cache/ninthspace-marketplace/`). That directory contains installed copies of plugins and is overwritten on updates. Changes made there are lost and not tracked by git.

**ALWAYS use the source files in this repository.** Each plugin has its own top-level directory:

| Plugin | Source directory |
|--------|----------------|
| CPM | `cpm/` |
| NotePlan | `noteplan/` |
| PHP LSP | `php-lsp/` |
| JS Simplifier | `js-simplifier/` |
| Filament Mockup | `filament-mockup/` |

Common source locations (using CPM as an example — same pattern applies to all plugins):

| What | Source (use this) | Cache (never touch) |
|------|-------------------|---------------------|
| Hook scripts | `cpm/hooks/` | `~/.claude/plugins/cache/.../hooks/` |
| Skill files | `cpm/skills/` | `~/.claude/plugins/cache/.../skills/` |
| Config files | `cpm/hooks/hooks.json` | `~/.claude/plugins/cache/.../hooks/hooks.json` |
| Test suites | `cpm/hooks/tests/` | `~/.claude/plugins/cache/.../hooks/tests/` |

When a skill file references relative paths (e.g. `../../agents/roster.yaml`), translate that to the equivalent path under the plugin's source directory in this repo.

If you catch yourself reading from or writing to `~/.claude/plugins/cache/`, **stop and redirect to the repo source**.

**Exception**: When a skill is actively running (e.g. `/cpm:spec`, `/cpm:do`), it reads its own SKILL.md instructions from the cache — that's normal runtime behaviour. The rule above applies to **development work**: editing hook scripts, skill files, test suites, agent rosters, or any other plugin source code.

## What belongs in `cpm/shared/skill-conventions.md`

CPM's SessionStart hook injects this file **in full, into every session in this repo** — before any skill is invoked, and whether or not one ever is. It is the only CPM file with unconditional reach, which makes adding to it different in kind from adding to a SKILL.md.

A section earns its place there by being referenced by **several** skills. Before adding one, or when reviewing what is already there:

```sh
grep -rl "Section Name" cpm/skills/*/SKILL.md | wc -l
```

- **Referenced by several skills** — it belongs in the shared file. That is what the file is for.
- **Referenced by one or two** — put it in those skills. A shared section with two consumers costs every other session nothing but attention.
- **Referenced by none** — it is documentation, not context. It belongs in `docs/`, not in the session preamble.

**Why a relevance check and not a size budget**: the file grew 3.4k → 49.7k bytes between 2026-03-28 and 2026-07-25 across ten revisions, none of which reduced it — the propagation pattern gives the process an add path and no remove path. A byte target is the wrong corrective: it can be met by deleting rules, which is why spec 40's token NFR needed the guard clause *"attributable to rewritten prose rather than removed rules."* The relevance check can only be satisfied by moving content to where it is used.

**Baseline at 2026-07-25**: 49,704 bytes, ~12.4k tokens. Roughly 36% of it sits in sections referenced by three skills or fewer — `Subagent Delegation` (1), `Change Type Decision` (1), `Retro Synthesis` (2), `Retro Retirement` (2), `Implementation Guidelines` (3) — and `Effort Recommendations` is referenced by none, being guidance for a human choosing a session setting. Relocating these is deferred, not rejected; see `docs/quick/27-quick-shared-conventions-relevance-check-spec.md`.
