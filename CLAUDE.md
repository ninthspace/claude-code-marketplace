# Claude Code Marketplace — Development Guidelines

## Critical: `docs/` is generated output, and CPM's history is under `docs/cpm/`

This repository migrated from CPM to DPM on 2026-08-16. Two rules follow, and both are permanent.

**Never hand-write into the folders DPM generates.** `plans`, `briefs`, `specifications`, `epics`, `reviews`, `retros`, `quick`, `discussions`, `communications`, `audits`, `runbooks` and `library` under `docs/` are regenerated from `.dpm/dpm.db` whenever DPM publishes. Anything written there by hand is competing with a generator and is lost at the next regeneration. The pre-commit guard (`.git/hooks/pre-commit`, symlinked into the DPM plugin) refuses the commit and names what diverged; it deliberately fixes nothing, because a hook that regenerated and staged the result would silently overwrite the edit. Move the content into the database instead — that is what the guard is asking for.

**The CPM-era corpus lives under `docs/cpm/` and never moves back.** 140 planning documents across nine folders. It stays readable, greppable and in git exactly as it was, and DPM cannot see it: DPM only looks one folder deep, so `docs/cpm/` is permanently out of reach. Cite it by that path.

Three directories under `docs/` are neither generated nor parked, and stay where they are: `docs/maintenance/` (see below), `docs/stories/` and `docs/artifacts/`. `docs/archive/` also stays — it is work archived *during* the CPM era, which is a different thing from the CPM era itself.

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

CPM's SessionStart hooks inject **a bounded extract** of this file into every session in this repo — the sections named in `CORE_SECTIONS` (`cpm/hooks/lib/conventions-core.sh`) in full, every other section as one line of index, and the file's path with an instruction to read it. The hooks used to `cat` the whole file; they stopped on 2026-07-28 because at 45 KB it exceeded the size past which the harness stops inlining hook output, so the sections after the first one and a half were reaching no session at all. The measurements are in `docs/maintenance/README.md`.

So there are now **two** questions, not one, and they are decided separately.

**1. Does it belong in the shared file?** A section earns its place by being referenced by **several** skills:

```sh
grep -rl "Section Name" cpm/skills/*/SKILL.md | wc -l
```

- **Referenced by several skills** — it belongs in the shared file. That is what the file is for.
- **Referenced by one or two** — put it in those skills. A shared section with two consumers earns its keep in neither.
- **Referenced by none** — it is documentation, not context. It belongs in `docs/`, not in the session preamble.

**2. Does it belong in `CORE_SECTIONS`?** Only if it must hold in a session where **no skill is ever invoked**. That is a much smaller set, and reference count does not decide it: `Stale-Progress Check` is referenced by all 20 skills and is still not core, because every one of those references is a skill that can read it. `Conversational Output` is core because it governs a reply that no skill was involved in.

The bar for core is high and should stay high — it is the only part with unconditional reach, and it is the part that has to stay small for any of it to arrive. **Adding a section to `CORE_SECTIONS` is a change to what every session pays for; adding one to the file is not.**

**A relevance check rather than a byte budget**, because a byte target can be met by deleting rules. Moving content to where it is used is the only way to satisfy this one. Growth history, per-section reference counts, and the deferred relocation inventory: `docs/cpm/quick/27-quick-shared-conventions-relevance-check-spec.md`.

Note that the file's own growth is now much cheaper than it was, which is a reason to keep applying the check rather than to relax it: a section nothing references costs one index line instead of its length, so the pressure that used to enforce this rule automatically is gone.

**Before relocating a section**, grep the suites for assertions that reach into `cpm/shared/skill-conventions.md` by path while claiming to test a rule's *content*. A relocation and a mutation look identical to a location-pinned test.

## A SKILL.md is not a change log

A skill file says what the skill does, and gives the rationale a maintainer needs in order not to break a rule. It does not record how it came to be: what a past spec decided, what used to be in this step, why an earlier design was wrong, or that a paragraph was worded a particular way after an incident. That history belongs in the spec, the epic, the retro, and the commit — all of which already hold it, and none of which are loaded at runtime.

The distinction is not "prose versus instructions". Rationale is welcome and often load-bearing: the `**Why**:` fields on `skill-conventions.md`'s Implementation Guidelines exist because an agent that doesn't know why a rule is there will route around it. The test is what the sentence is *about*. A sentence about the rule stays. A sentence about the rule's biography goes — including when it is true, well-written, and hard-won.

Reach is what makes it different from an ordinary documentation choice. A SKILL.md is loaded in full on every invocation of that skill, in every project the plugin is installed in. A note explaining a removal is paid for on every run, forever, by readers who never knew the removed thing existed.

Two things make it hard to catch. Skills already instruct their *runtime output* to record a decided absence — and those rules are correct, so the instinct is right one directory over and wrong here. And no metric finds it: citation counts and commentary-density both rank clean files top. Read the file. Evidence, and the passages removed in the 2026-07-28 sweep: `docs/cpm/quick/29-quick-skill-construction-prose-sweep-spec.md`.

**The same rule covers maintenance records, and they have one home.** Coupling to external components, formats CPM writes that something else parses, tables kept so a maintainer notices when a dependency moves — none of it belongs in a skill, and a pointer from a skill is still a line every invocation pays for. It all lives in **`docs/maintenance/README.md`**, which this file is the only thing that references. When a record there documents a behaviour, its operative counterpart stays in the skill and the suites assert the pair; nothing in `cpm/skills/` should name that path.
