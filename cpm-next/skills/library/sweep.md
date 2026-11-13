# Library: sweep

Read this file when the argument is `sweep`, `sweep add {path}`, `sweep remove {path}` or `sweep list`, and read it again whenever it is not in context. The contract (`shared/artifacts.md`, two levels above this file's directory) defines the signal forms and marks; `SKILL.md` beside this file defines the legacy retro observation.

## The repository list

- The repository list is `~/.claude/cpm-next/repos.txt`, one absolute path per line.
- `sweep add {path}` appends the symlink-resolved absolute path (for a path that doesn't exist yet, its existing parent resolved with the rest appended, which is not refused), creating the directory and file on the first add, and refuses one already listed; `sweep remove {path}` resolves its argument the same way and removes it; `sweep list` shows the list and whether each path exists.
- A missing or empty list is reported with how to add a repository.
- A listed path that no longer exists or holds none of `docs/epics/`, `docs/archive/epics/`, `docs/quick/` and `docs/retros/` is reported with `sweep remove {path}` or a corrected path, and skipped; one that can't be read is reported with the advice to allow the read; the sweep carries on with the rest.
- Read each distinct resolved path once, and count distinct resolved paths when applying the two-repository threshold.

## Collecting, placing and grouping

- `sweep` reads each listed repository's `docs/epics/`, `docs/archive/epics/` and `docs/quick/` and collects every `process` signal, counting only a `**Signal**:` field line at the start of a line, not a template quoted in prose or code.
- It also collects unretired legacy retro observations that name a cpm-next skill or rule (a v3 skill counts as its cpm-next counterpart).
- It places each at the cpm-next file and step it involves, reading that file as it now stands when a signal's parenthesis or an observation names no step, and lists one it can't place as unplaced rather than dropping it.
- **Moved places.** A signal or observation that names a place in the table below is placed before grouping and before `shared/fixed.md` is read. At a wholly moved place it is placed at the new one, the new file being its place, which a row naming that file covers. At a partly moved place (only some of its text moved) it is placed by its text, as one that names no step is: at the new place when what failed is in the part that moved, at the old place otherwise.

  | Old place | New place | Moved |
  |---|---|---|
  | `cpm-next/skills/do/SKILL.md` Independent tests | `cpm-next/skills/do/independent-tests.md` | wholly |
  | `cpm-next/skills/do/SKILL.md` Before the first story, step 3, Finishing (their `[browser]` parts) | `cpm-next/skills/do/browser.md` | partly |
  | `cpm-next/skills/library/SKILL.md` Sweep | `cpm-next/skills/library/sweep.md` | wholly |
  | `cpm-next/skills/library/SKILL.md` Back-fill, Consolidate | `cpm-next/skills/library/consolidate.md` | wholly |
  | `cpm-next/agents/auditor.md` check 5 (its independent-test checks) | `cpm-next/shared/auditor-independent-tests.md` | partly |

- It groups by that file and step, using the slug as a hint and reading to confirm, and reports each group found in two or more repositories with its signals (repository, signal reference, version, what failed) and the versions its signals were seen under.
- A group found in one repository only is named as not reported.

## Fixed rows

- It reads `shared/fixed.md` at the plugin root (two levels above this skill's directory).
- A row covers a signal when it names the signal's cpm-next file and the step the signal was placed at (whatever the formatting; a row naming several steps matches each), names the signal's class or has Class `any`, and its version is higher than the signal's, comparing the numbers of `major.minor.patch`.
- A version that is not plain `major.minor.patch`, a missing version, and a retro observation all count as no version, which no row covers.
- A group is left out only when every signal in it is covered by some row (not necessarily the same row); a group with any signal no row covers is not left out, and neither is one no row matches, and it goes on the list its repository count puts it on.
- Each group left out is named as fixed, with the version of the earliest row covering each signal (the highest of them when they differ), and a group left out is listed apart from the groups not reported.

## What it writes

It writes nothing in any scanned repository and never marks or edits a signal. It then tests whether the current repository is the plugin's own source: the git top level holds `cpm-next/.claude-plugin/plugin.json` whose `name` is `cpm-next`.

In the plugin's own repository, on the user's choice it writes one discussion record in the current repository, `docs/discussions/{nn}-discussion-sweep-{YYYY-MM-DD}.md` (numbered by the contract), for `/cpm-next:plan`, even when the current repository is also listed. The record lists the reported groups with their signals, the groups not reported, the groups left out as fixed, the unplaced items and the skipped paths, and carries `**Status**: Concluded`; end with `/cpm-next:plan {record path}`.

Anywhere else it writes no discussion record and offers an issue draft instead, since the signals can name the scanned repositories' files, code and terms. With no reported group it offers nothing.

- **The draft.** The draft is one issue. Each reported group is an entry headed by its cpm-next file and step, holding its class slugs, a one-line description of the failure, the versions its signals were seen under and how many repositories showed it. An entry holds each of its group's slugs that the contract's seed list or `shared/fixed.md` names, and none that they don't.
- **Its title.** With one reported group the title names its file and step, and its class when its entry holds exactly one slug; with several it names the number of groups.
- **What it may say.** The description is generic: written afresh from the signals, never copied from them, and naming nothing of the project or its domain, only what cpm-next did or failed to do. The draft holds no repository name or path, no file, symbol or term from those repositories, no code and no signal text quoted from them, and none of the groups not reported, left out as fixed, or the unplaced items.
- **Showing it.** It shows the draft in full and asks the user to read it for anything of their project.
- **Filing it.** It then checks that `gh` is installed and signed in and that the installed plugin's `.claude-plugin/plugin.json` (at the plugin root) has a GitHub `repository` field; if either fails it gives what keeping the draft as text gives, with the reason, and asks nothing. Otherwise it asks in one AskUserQuestion call: file it, keep it as text, or change it. Change it takes the user's edits, shows the revised draft in full and asks again. Only the file-it answer files anything. Filing runs `gh issue create --repo {owner/name} --title … --body-file …` with the owner and name from that field, the body written to a temporary file outside every repository. Keeping it as text gives the draft and `{repository}/issues/new`, the field without a trailing `/` or `.git`, or only the draft when there is no field.
