# DPM hook pointer and sweep

Status: the pointer and the sweep exist as zsh functions in `~/.zshrc` (2026-09-22). This
document records the design, and specifies how to move the same behaviour into the DPM plugin
so the zsh functions can be withdrawn.

## The problem

A repo installs DPM's guard by symlinking `.git/hooks/pre-commit` at the plugin's copy of the
hook. The plugin lives at a versioned path:

```
~/.claude/plugins/cache/ninthspace-marketplace/dpm/0.8.0/hooks/pre-commit
```

An upgrade installs 0.9.0 beside 0.8.0 and re-points nothing, so every repo's link keeps running
the release it was made from. The guard detects the mismatch and refuses to commit, which is
correct but is not a fix. The fix — `dpm-relink` — had to be run in each repo, from each repo.

At the time of writing, ten repos were actually using DPM and every one of them was stale: eight
on 0.7.7, one on 0.6.0 and one on 0.5.1.

## The design

Put one level of indirection between the repo and the version:

```
<repo>/.git/hooks/pre-commit
  -> ~/.claude/plugins/dpm-current/hooks/pre-commit
       -> ~/.claude/plugins/cache/ninthspace-marketplace/dpm/<version>/
```

An upgrade re-points `dpm-current` and every repo follows. Per-repo relinking disappears as an
obligation; a repo is linked once, when it first gets a DPM database.

This is supported by the hook rather than tolerated by it. `hooks/pre-commit` resolves its own
symlink chain in a `while` loop before locating `../bin/dpm-guard.js`, and the comment in that
loop names exactly this case: "a plugin cache symlinked into place, then symlinked again into
`.git/hooks`". Verified end to end on 2026-09-22: a repo linked through the pointer ran the
0.8.0 guard and reported a real divergence, not a resolution error.

The pointer is a symlink rather than a copy so that `..` from `hooks/` resolves through it to the
version directory, which is what puts `bin/dpm-guard.js` in reach.

## What exists now (to be withdrawn)

`~/.zshrc` defines:

| Name | Purpose |
| --- | --- |
| `DPM_PLUGIN_ID`, `DPM_POINTER`, `DPM_HOOK`, `DPM_ROOTS` | configuration |
| `_dpm_installed_path` | reads `installPath` for `dpm@ninthspace-marketplace` out of `~/.claude/plugins/installed_plugins.json` |
| `_dpm_repoint` | points `dpm-current` at that path |
| `_dpm_link_repo` | classifies one repo's `pre-commit` and links it when safe |
| `dpm-link` (and `dpm-relink`, kept as an alias) | link the current repo |
| `dpm-sweep [-n\|--dry-run] [--no-update]` | update the plugin, re-point, sweep every repo |

The old `dpm-relink` body — `ln -sf` at a `sort -V | tail -1` glob of the cache — is gone. Its
`-f` was there to force past a stale link, which is the thing the pointer removes.

### Classification rules

The sweep changes only what it is sure about. Per repo:

| State of `pre-commit` | Action |
| --- | --- |
| Missing | link to the pointer (the repo already qualifies — see Discovery) |
| Symlink to the pointer | leave, report `ok` |
| Symlink into `…/dpm/<version>/hooks/pre-commit` | re-point to the pointer |
| Symlink anywhere else | leave, report the target |
| Regular file | leave, report it |
| `core.hooksPath` set to something other than the repo's own hooks directory | leave, report the path |

The rules follow the README's "When something else owns the hook": only DPM's own stale link is
safe to overwrite.

### Version source

The installed version comes from `installed_plugins.json`, not from a `sort -V` glob of the cache
directory. The cache keeps old versions, and the highest version present is not necessarily the
one Claude Code has installed — an install record is authoritative where a directory listing is a
guess.

### Discovery

Roots are `~/Work/git` and `~/Work/castle/git`, searched to depth 4 for a `.dpm` directory,
skipping `node_modules/` and `vendor/`. Each hit resolves to its repository root via
`git rev-parse --show-toplevel` and is de-duplicated, so a `.dpm` in a subdirectory of a repo
(`claude-code-marketplace/dpm/.dpm`) does not produce a second entry for its parent.

**A `.dpm` directory is not enough.** A repo qualifies only when `.dpm/dpm.sql` is present. A
session that touches DPM creates `.dpm/dpm.db` whether or not the repo goes on to use it, so the
bare database appears in repos with no planning data and no interest in the guard — five of them
in this layout (`ice`, `ice-services`, `ice-analytics`, `claude-skills`, `research`). The
committed dump is written by publishing, which is the point at which a repo starts depending on
the guard, and it is also the artefact the guard checks. Anything wanting a hook without a dump
can be linked by hand with `dpm link`.

### Two things that bit during implementation

**`cd` is wrapped.** `~/.zshrc` redefines `cd` to run `nvm use` when a `.nvmrc` is present. That
wrapper prints to stdout, so `$(cd "$dir" && git rev-parse --show-toplevel)` captured two lines of
nvm chatter along with the path, and the repo was silently skipped with a stray `fatal: not a git
repository` on the terminal. Both call sites now use `builtin cd -q`. Any port of this logic to a
shell script needs the same guard; a Node port sidesteps it entirely.

**`git rev-parse --git-path hooks` honours `core.hooksPath`.** It returns the effective hooks
directory, not `.git/hooks`. That is the behaviour the sweep wants — it means a repo whose
`core.hooksPath` merely points at its own `.git/hooks` is treated as the ordinary case rather than
being set aside, and a repo using `.githooks` is reported against the directory git will actually
read.

## Moving it into the plugin

### Shape

Ship `bin/dpm-sweep.js` alongside the existing `dpm-guard.js`, `dpm-publish.js`, `dpm-import.js`
and `dpm-merge.js`. Node is already the plugin's runtime, so this costs no new dependency, and it
avoids the shell-wrapper problem above.

```
dpm sweep [--dry-run] [--no-update] [--roots <path>[,<path>…]]
dpm link  [<repo>]        # single repo; default cwd
```

Invocation from the shell stays one line, so `~/.zshrc` keeps a wrapper rather than an
implementation:

```zsh
dpm-sweep() { node "$HOME/.claude/plugins/dpm-current/bin/dpm-sweep.js" "$@" }
```

### Resolving its own target

The script must re-point the pointer at the *installed* version, which is not necessarily the
version the script itself is running from — if it is invoked through `dpm-current`, `__dirname`
is the old release. Read `installPath` from `~/.claude/plugins/installed_plugins.json` for
`dpm@ninthspace-marketplace`, and fall back to `path.resolve(__dirname, '..')` only when that
file has no record (a plugin run from a checkout rather than an install).

### Creating the pointer

The script owns `~/.claude/plugins/dpm-current`: creates it if absent, re-points it otherwise,
with `fs.symlink`/`fs.rename` rather than an unlink-then-create, so a concurrent hook invocation
never sees the path missing. The location sits beside `cache/` in a directory Claude Code manages
but does not enumerate, so a stray entry there is inert.

### Configuration

Roots should not be hard-coded to one machine's layout. In order of precedence:

1. `--roots` on the command line.
2. `DPM_ROOTS`, colon-separated.
3. `~/.config/dpm/roots`, one path per line, comments with `#`.
4. Fall back to `$HOME` with a depth limit and the same `node_modules`/`vendor` exclusions, and  
   say in the output that it is scanning everything because nothing was configured.

### Updating the plugin

`claude plugin update dpm@ninthspace-marketplace` stays a shell-out; there is no API for it. Treat
a non-zero exit as fatal and stop before re-pointing — re-pointing at a version that failed to
install is worse than leaving the previous one in place. Keep `--no-update` for the case where the
update has already happened through `/plugin`.

The update needs a Claude Code restart to take effect for the MCP server. The hook does not: it is
resolved per commit, so the sweep's work is live immediately. The output should keep saying so.

### Documentation to change

- `README.md`: the install instruction becomes a link to the pointer, and the section that tells  
  the reader to re-link after every upgrade ("Re-make that symlink after every DPM upgrade")  
  becomes a note that the pointer removes the obligation, with the manual recipe kept for a repo  
  that is deliberately pinned to one version.
- The stale-link diagnosis in the troubleshooting section stays — a repo linked before this change  
  still presents exactly that way, and `dpm sweep` is its fix.
- `MIGRATION.md`: one entry saying an existing repo is migrated by `dpm sweep`, and that a link  
  made by hand into a versioned path keeps working until it goes stale.

### Withdrawing the zsh functions

Once `dpm sweep` ships and has been run once:

1. Replace the block in `~/.zshrc` between `# --- DPM plugin hooks ---` and the end of  
   `dpm-sweep` with the two-line wrapper above.
2. Keep `dpm-relink` as an alias of `dpm-link` for muscle memory, or drop it and let the shell  
   report it as not found — the name no longer describes anything the workflow needs.
3. Delete this file's "What exists now" section, or mark it done.

## Testing

The sweep is mostly classification, so the tests worth writing are per-state fixtures: a repo with
no hook, one with a link to a versioned path, one with a link to the pointer, one with a link to
something else, one with a regular-file hook, one with `core.hooksPath` set elsewhere, one with
`core.hooksPath` set to its own hooks directory, a linked worktree, and a `.dpm` directory that is
not inside a git repository at all. Assert the reported classification and, for the two mutating
cases, the resulting link target. `--dry-run` must produce the same classification with no change
on disk, which is worth asserting directly rather than by inspection.

Discovery needs its own fixtures: a repo with `.dpm/dpm.sql`, one with only `.dpm/dpm.db`, and one
with neither. Only the first is swept.
