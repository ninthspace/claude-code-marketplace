# cpm-next (experimental)

Three skills for Opus 5.5, in place of CPM's twenty-one. They read and write the CPM v3 artefact formats, so the board, `/cpm:status` and the v3 skills all keep working on the same `docs/` tree.

| Skill | Absorbs from v3 | Finish line |
|---|---|---|
| `/cpm-next:party` | party, consult | Record concluded, next step named |
| `/cpm-next:plan` | discover, brief, architect, spec, epics, pivot | Artefacts down to the target exist and trace upward |
| `/cpm-next:do` | do, ralph, quick | Stories in scope Complete, suite no worse than baseline |

## What changed, and why

- **Outcomes over procedure.** Each skill states what "done" means and when to stop. How to get there is left to the model.
- **State lives in the artefacts.** The discussion record and the epic doc are the state. No progress files, stale-progress checks, compaction hooks or `/cpm:clean`.
- **plan works from inventory.** It takes stock of what exists, asks its questions in one batch, records its own decisions as Assumptions, and writes only what's missing. It covers greenfield and brownfield from any starting state.
- **do stops only when it has to.** Its stop rules follow the Opus 5.5 guidance: keep going when the user isn't needed, and stop for unexplained failures, scope changes and destructive actions. An unattended (`all`) run marks blocked stories instead of stopping.
- **Kept on purpose:** the "unmet isn't wrong" rule from the Change Type Decision, citation-backed amendments, and `**Pivot deferred**` breadcrumbs. This is the one failure mode that is known to be expensive.
- **Dropped:** coverage matrices (`**Satisfies**` carries the traceability), the retro disposition gate, template hints, and the `AskUserQuestion` handoff menus.

## Running the experiment

1. Pick three real starting states: nothing but an idea; an existing brief; existing epics in a brownfield Laravel repo.
2. For each, run v3 and cpm-next on separate branches from the same commit.
3. Run every session, v3 and cpm-next alike, at `medium` effort (`/effort medium` in Claude Code), so effort isn't a variable in the comparison. If an `all` run is driven headless (`claude -p` in a loop, as ralph did), treat a turn that ends with text as a progress report, not completion. Continue it by naming the open stories, and give up after two or three continuations on the same story.
4. Compare wall-clock time, how often the user had to intervene, spec and epic quality (blind if possible), and whether `do` finished with the suite green.
5. When cpm-next fails in a way v3 guarded against, add back the smallest rule that prevents it. Log each addition here, so the growth stays deliberate.
