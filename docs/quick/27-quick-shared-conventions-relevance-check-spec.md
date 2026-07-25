# Shared-Conventions Relevance Check

**Date**: 2026-07-25
**Status**: Complete

## Context

Spec 40 carried a Token Efficiency NFR — "this pass should **reduce** net token count across `cpm/skills/*/SKILL.md` and `shared/`". It was discharged at a net *increase* of 1.9% and retro 14 recorded why: five of eleven requirements added text against one that removed. Reviewing whether the measurement was worth keeping at all showed the problem was not the target but the subject — the NFR measured a quantity nothing loads. This record retires that intent and replaces it with a relevance check on the one file that does load unconditionally.

## What the NFR measured vs. what loads

| | Tokens (bytes ÷ 4) |
|---|---:|
| Full corpus — the NFR's subject | ~119,000 |
| `shared/skill-conventions.md` — injected into every session | ~12,400 |
| + the single SKILL.md that runs (worst case, `do`) | ~28,000 — 2.8% of a 1M window |

The 20 skill files are mutually exclusive at runtime, so their sum has no consumer. The corpus figure is roughly 4× the largest real session load.

## Growth of the always-loaded file

Following renames through the cpm2 → cpm promotion:

| Date | Bytes | ~Tokens | Commit |
|---|---:|---:|---|
| 2026-03-28 | 3,370 | 842 | Extract shared skill conventions |
| 2026-04-11 | 6,921 | 1,730 | + parent-scoped numbering |
| 2026-04-17 | 8,684 | 2,171 | + implementation guidelines |
| 2026-06-07 | 37,071 | 9,267 | cpm2 → cpm promotion |
| 2026-06-17 | 41,240 | 10,310 | + cross-retro awareness |
| 2026-07-08 | 44,588 | 11,147 | + stale-progress safety-net |
| 2026-07-25 | 49,704 | 12,426 | spec 40 + quick 26 |

14.8× in four months across ten revisions, **none of which reduced it**. The growth is structural rather than incidental: spec 40's own Consistency NFR directs load-bearing changes into this file, and the retro 11/12 propagation pattern does the same. The process has an add path and no remove path.

## Reference counts at 2026-07-25

`grep -rl "{section}" cpm/skills/*/SKILL.md | wc -l`:

| Section | Bytes | Skills |
|---|---:|---:|
| Stale-Progress Check | 3,247 | 20 |
| Progress File Management | 3,193 | 17 |
| Numbering | 3,367 | 12 |
| Retro Awareness | 2,956 | 11 |
| HTML Output | 8,798 | 7 |
| Implementation Guidelines | 2,715 | 3 |
| Retro Synthesis | 4,835 | 2 |
| Retro Retirement | 2,031 | 2 |
| Subagent Delegation | 3,207 | 1 |
| Change Type Decision | 1,820 | 1 |
| Effort Recommendations | 3,119 | 0 |

About 17,700 bytes (~4,400 tokens, ~36% of the file) sits in sections referenced by three skills or fewer. `Effort Recommendations` is referenced by none — it is guidance for a human choosing a session setting, and says so itself ("nothing here applies itself"), yet is injected into every model context.

## Changes Made

- `CLAUDE.md` — added "What belongs in `cpm/shared/skill-conventions.md`": the relevance check, its one-line grep, the three dispositions (several / one-or-two / none), why a relevance check rather than a byte budget, and the 2026-07-25 baseline.

No plugin source changed. The relocation this analysis argues for is **deferred, not rejected** — see below.

## Verification

Growth table produced by walking `git log --follow` and reading each commit's tree at the file's path in that commit (the path moved during the cpm2 → cpm promotion, so a fixed-path read returns empty for early commits). Reference counts are exact greps over `cpm/skills/*/SKILL.md`. Section sizes are exact byte counts between `##` headings.

Token figures throughout are bytes ÷ 4 and are accurate to roughly ±15% on prose. The 14.8× trend, the byte counts, and the reference counts do not depend on that approximation.

## Deferred work

Relocating the ≤3-reference sections into their consuming skills, and moving `Effort Recommendations` out of the injected file into `docs/`, would take ~4,400 tokens out of every session in this repo. It touches many files and cuts against the propagation pattern that put the content there, so it warrants `/cpm:spec` rather than a quick fix. The tables above are the starting inventory.

## Retro

**Criteria gap**: The NFR's flaw was not its target but its subject — it constrained a corpus total that nothing loads, when the quantity with unconditional reach was a single file that had grown 14.8× without one reduction. An NFR naming a global quantity should first have to state who reads that quantity; had spec 40 answered that, the measurement would have pointed at `skill-conventions.md` from the start.
