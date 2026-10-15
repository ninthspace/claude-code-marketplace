# Plugin Maintenance Reference

Development-facing records for the plugins in this repository: dependencies on external components,
formats one component writes that another parses, and coupling between parts that a change to one of
them can break.

**Nothing here is loaded at runtime, and nothing here is referenced from a skill.** That is
the point of the file. A `SKILL.md` is read in full on every invocation of that skill, in
every project the plugin is installed in, so a record aimed at a maintainer is paid for by
every run that will never consult it. This file is the single home for that material, and
`CLAUDE.md` is the only thing that points here — see *A SKILL.md is not a change log* there
for the rule.

**Each record below is a record, not an instruction.** Where a behaviour is recorded here,
its operative counterpart lives in the plugin's source.

The records for CPM and DPM went with their source on 2026-10-08; both are in git history.

---

## `cpm-next-progress` ↔ the harness — tool output it parses, and older engines

**The record.** The mod never writes an artifact; it reads them and parses what the harness prints.
Three formats are load-bearing, all in `cpm-next-progress/hooks/progress.ts`:

- **`ArtifactData` list output.** `parseDocs` takes each line that starts with `{"id"` between the
  `BEGIN`/`END` database markers as one document, `{id, version, data}`. A change to that line shape
  reads as an empty collection: every row is then offered again as new, without `if_version`, and the
  writes are refused as unpinned.
- **A deleted artifact.** `isMissingArtifact` matches `no such artifact` or `HTTP 404` in the error a
  read raises. Missed, a deleted tracker or overview page fails its check on every write instead of
  being settled once.
- **The publish result.** `artifactUrlIn` takes the first `https://claude.ai/[code/]artifact/<id>` in the
  `Artifact` tool's result. Missed, a published tracker's link is never saved to its build-order file,
  nor the overview's to the store.

**Older engines.** `claude plugin validate` and `claude plugin test` run on the newest Claude Code
installed, but open sessions keep the version they started on (`~/.local/share/claude/versions/`), and
`/reload-plugins` loads the mod into that one. On 2026-10-15 Claude Code 2.1.296 refused 0.4.0 for
passing `$` into a function imported from `overview.tsx` ("$ is followed only into a function declared
in this same file, never across an import"), which 2.1.300 accepts, and `/progress-tracker` vanished
from every open session. Load the mod headless under each installed version before releasing:

```sh
~/.local/share/claude/versions/<v> -p "reply ok" --debug-file /tmp/d.txt --plugin-dir cpm-next-progress
grep -i 'hooks module cpm-next-progress@inline' /tmp/d.txt   # "loaded", or "failed to load: <reason>"
```

**What asserts it.** `cpm-next-progress/hooks/progress.test.ts` covers `parseDocs`, `isMissingArtifact` and
`artifactUrlIn` against the formats above; nothing asserts the harness still prints them. Nothing
automated covers older engines.
