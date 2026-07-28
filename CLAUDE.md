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

**A relevance check rather than a byte budget**, because a byte target can be met by deleting rules. Moving content to where it is used is the only way to satisfy this one. Growth history, per-section reference counts, and the deferred relocation inventory: `docs/quick/27-quick-shared-conventions-relevance-check-spec.md`.

**Before relocating a section**, grep the suites for assertions that reach into `cpm/shared/skill-conventions.md` by path while claiming to test a rule's *content*. A relocation and a mutation look identical to a location-pinned test.

## A SKILL.md is not a change log

A skill file says what the skill does, and gives the rationale a maintainer needs in order not to break a rule. It does not record how it came to be: what a past spec decided, what used to be in this step, why an earlier design was wrong, or that a paragraph was worded a particular way after an incident. That history belongs in the spec, the epic, the retro, and the commit — all of which already hold it, and none of which are loaded at runtime.

The distinction is not "prose versus instructions". Rationale is welcome and often load-bearing: the `**Why**:` fields on `skill-conventions.md`'s Implementation Guidelines exist because an agent that doesn't know why a rule is there will route around it. The test is what the sentence is *about*. A sentence about the rule stays. A sentence about the rule's biography goes — including when it is true, well-written, and hard-won.

Reach is what makes it different from an ordinary documentation choice. A SKILL.md is loaded in full on every invocation of that skill, in every project the plugin is installed in. A note explaining a removal is paid for on every run, forever, by readers who never knew the removed thing existed.

Two things make it hard to catch. Skills already instruct their *runtime output* to record a decided absence — and those rules are correct, so the instinct is right one directory over and wrong here. And no metric finds it: citation counts and commentary-density both rank clean files top. Read the file. Evidence, and the passages removed in the 2026-07-28 sweep: `docs/quick/29-quick-skill-construction-prose-sweep-spec.md`.

**The same rule covers maintenance records, and they have one home.** Coupling to external components, formats CPM writes that something else parses, tables kept so a maintainer notices when a dependency moves — none of it belongs in a skill, and a pointer from a skill is still a line every invocation pays for. It all lives in **`docs/maintenance/README.md`**, which this file is the only thing that references. When a record there documents a behaviour, its operative counterpart stays in the skill and the suites assert the pair; nothing in `cpm/skills/` should name that path.
