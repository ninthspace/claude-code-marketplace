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

The 49,704-byte figure this section used to quote was measured at `6088274` and was stale within the day: `41bc7a5` added 3,923 bytes and `ef2505c` a further 1,459, reaching 55,082 before anyone re-read the number. Recording a baseline does not slow the add path — worth knowing before trusting the figure below.

**Baseline at 2026-07-26**: 53,238 bytes. About 30% of it sits in sections referenced by three skills or fewer — `Subagent Delegation` (1), `Retro Synthesis` (2), `Retro Retirement` (2), `Implementation Guidelines` (3) — and `Effort Recommendations` is referenced by none, being guidance for a human choosing a session setting. Relocating these is deferred, not rejected; see `docs/quick/27-quick-shared-conventions-relevance-check-spec.md`.

`Change Type Decision` was the first of that set to move: spec 43 relocated it into `cpm/skills/do/SKILL.md`, its single consumer, for −1,844 bytes. **Before relocating the next one**, grep the test suites for assertions that reach into `cpm/shared/skill-conventions.md` by path while claiming to test a rule's *content*. One such assertion failed on that move even though the rule came across verbatim — a relocation and a mutation look identical to a location-pinned test. See `docs/retros/22-retro-convention-relocation.md`.

## A SKILL.md is not a change log

A skill file says what the skill does, and gives the rationale a maintainer needs in order not to break a rule. It does not record how it came to be: what a past spec decided, what used to be in this step, why an earlier design was wrong, or that a paragraph was worded a particular way after an incident. That history belongs in the spec, the epic, the retro, and the commit — all of which already hold it, and none of which are loaded at runtime.

The distinction is not "prose versus instructions". Rationale is welcome and often load-bearing: the `**Why**:` fields on `skill-conventions.md`'s Implementation Guidelines exist because an agent that doesn't know why a rule is there will route around it. The test is what the sentence is *about*. A sentence about the rule stays. A sentence about the rule's biography goes — including when it is true, well-written, and hard-won.

Reach is what makes it different from an ordinary documentation choice. A SKILL.md is loaded in full on every invocation of that skill, in every project the plugin is installed in. A note explaining a removal is paid for on every run, forever, by readers who never knew the removed thing existed.

**The generator is a false analogy with a rule that is correct.** Several skills instruct their *runtime output* to record a decided absence — `do/SKILL.md` records a skipped Step 5b refactoring pass and its reason in the progress file, has Step 8 log a retro auto-skip with its reason, and has the same step report "No criteria amended" rather than omitting the block. Those are right: each has a specific next reader who would otherwise misread silence as "did not happen". The failure is applying the same instinct to the skill file one directory over, usually in the same session, usually right after a spec has removed something. A coverage-matrix note is read once by the next person working that epic. A skill note is read by everyone, forever.

**Scanning does not find this — reading does.** The 2026-07-27 sweep tried two metrics before reading anything. Counting citations of numbered artefacts ranked `epics` top with 20 hits; `epics` was clean, and all 20 were template placeholders and cross-reference formats. Measuring bolded-commentary volume ranked `status` second at 27% of file bytes; all 25 of its commentary paragraphs were operational instructions. Both metrics missed all four passages that were actually construction. Treat this as one more instance of the general rule that a grep is a proxy for a quality judgement and not a substitute for one.

**Evidence.** The sweep removed 2,017 bytes from `ralph/SKILL.md` (12 passages) and 965 across `do`, `review` and `inspect` (4 passages). Every one of the sixteen traced to a commit in a single `git log -S` — mostly `6088274` (spec 40's Opus 5 alignment) and `177c61f` (spec 42's retirement), both of which were removing or overruling something and wrote the removal into the skill as it went. The clean skills are the ones no recent spec has cut anything out of, which is the same add-path dynamic the section above describes, in a different file.
