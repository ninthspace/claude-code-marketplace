---
name: cpm:clean
description: On-demand cleanup of CPM session state files. Exhaustively lists every progress file and its compact-summary companion with age and session label, then deletes only the files you name — no staleness filter, no sentinel, always confirmed first. Triggers on "/cpm:clean".
---

# Clean Session State

Delete leftover CPM session-state files on demand. This is the **exhaustive, user-driven** counterpart to the passive once-per-session Stale-Progress Check: where the safety-net surfaces only *stale* other-session files at most once per session, `/cpm:clean` lists **every** progress file and compact-summary companion **every time it runs** — regardless of age, session, or whether the safety-net has already fired — and removes exactly the ones you choose.

**Interactive-only.** `/cpm:clean` is always user-initiated and is **never** part of autonomous execution (`cpm:ralph` and other autonomous loops never invoke it). It deletes nothing without showing you the file first and getting your confirmation.

This skill is **stateless**: it creates no progress file of its own (it is the tool that removes them).

## Input

Parse `$ARGUMENTS`:

- **No arguments** (the common case): run the full interactive flow below — list, then ask what to remove.
- **File names / session IDs given**: treat them as the user's selection, but still list everything first (Step 1) and confirm the concrete paths (Step 3) before deleting. Arguments are a convenience, never a licence to skip the confirmation.

## Process

### Step 1: List every session-state file (exhaustive)

Call the shared classifier in **list-all mode** — it is the single source of truth for the file inventory and labels, so this skill never globs or `stat`s files itself:

```
CPM_SESSION_ID="$CPM_SESSION_ID" bash "${CLAUDE_PLUGIN_ROOT}/hooks/lib/progress-classify.sh" "$CLAUDE_PROJECT_DIR/docs/plans" list-all
```

It emits one tab-delimited record per file — `CLASSIFICATION<TAB>PATH<TAB>SKILL<TAB>PHASE<TAB>AGE_SECONDS<TAB>AGE_LABEL` — for **both** `.cpm-progress-*.md` files and `.cpm-compact-summary-*.md` companions. Apply **no** staleness filter and consult **no** sentinel: `CURRENT`, `FRESH`, and `STALE` files are all listed and all eligible for deletion. The classification is shown only as context, not as a gate.

**If there are no records** (no files exist): report "No CPM session-state files found in `docs/plans/` — nothing to clean." and **stop**. Do nothing else — an empty inventory means there is nothing to act on, never a reason to touch anything.

Otherwise, present a numbered inventory. **Group each compact-summary companion with its progress file** by shared session ID (`.cpm-progress-{id}.md` and `.cpm-compact-summary-{id}.md` belong to session `{id}`). Show, per entry: the session ID, skill + phase (progress files; companions read "compact summary"), the age label, and the path. List any compact-summary with no matching progress file as an orphan on its own. Mark the current session's own files (`CURRENT`) with a note — "this session's active state" — so the user does not remove them by accident.

### Step 2: Ask what to remove

Ask which files (or session groups) to delete — by number, session ID, or "none". Everything listed is eligible; nothing is pre-selected. If the user names a session/progress file that has a compact-summary companion, that companion is part of the same unit and will be removed with it (shown explicitly in Step 3). If the user chooses "none" (or names nothing), stop without deleting anything.

### Step 3: Confirm the exact paths, then delete only those

Expand the user's selection into the concrete list of file paths to remove — each chosen progress file **plus its compact-summary companion** (FR8: companions are cleaned together), and any orphan companions named directly. **Show the user this exact list of paths** and get explicit confirmation before removing anything (FR6). On confirmation, delete **only** those paths:

```
rm -f -- "<path>"   # for each confirmed path
```

Delete nothing the user did not name and confirm. After removal, report which files were deleted (and that any others listed were left untouched).

## Guidelines

- **Exhaustive, every time.** No sentinel, no once-per-session gate, no age threshold — `/cpm:clean` always lists the full inventory. That is the difference between it and the passive safety-net.
- **Delete only named, confirmed files.** The user always sees the exact paths before anything is removed; no path in this skill auto-executes a delete.
- **Companions travel with their progress file.** Removing a session's progress file also removes its `.cpm-compact-summary-{id}.md`, surfaced in the confirmation so it is never a surprise.
- **Thin consumer of the classifier.** File discovery, age, and labelling come from `progress-classify.sh` in list-all mode — do not re-implement globbing or `stat` here, so the rules never drift from the hooks and the safety-net.
- **Interactive-only.** Never invoked by autonomous loops; always user-driven.
