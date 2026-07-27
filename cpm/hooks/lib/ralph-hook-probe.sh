#!/bin/bash
# ralph-hook-probe.sh — does the ralph-wiggum stop hook fail closed?
#
# cpm:ralph has exactly one external dependency: ralph-wiggum's Stop hook, which blocks
# session exit and feeds the prompt back. Pre-flight step 1c checks that hook is
# *registered*. That check passed throughout a live run in which the hook deleted the
# loop's state file at the first iteration boundary and exited 0 — so presence is not
# the property that matters. This probe asks the property that does.
#
# ralph-wiggum 1.0.0 selected the last transcript record matching "role":"assistant"
# and, finding no text block in it, treated that as "the model said nothing", removed
# .claude/ralph-loop.local.md and exited 0. Transcripts are full of thinking-only and
# tool_use-only records; every cpm:do story ends in tool calls and a commit, so a turn
# ending on a tool call is the normal shape, not a corrupt one. The loop died silently
# and looked exactly like a clean finish: no promise emitted, no error, no state file.
#
# The check is BEHAVIOURAL, not a grep of the hook's source. A grep would pin this to
# one vendor's wording and pass the moment upstream reworded it, while saying nothing
# about what the hook does. So: build a state file and a transcript whose last
# assistant record is tool_use-only, run the real hook against them in a scratch
# directory, and see whether the state file is still there afterwards.
#
# Exit codes (the convention coverage-rollup.sh uses):
#   0  hook fails closed — safe to arm the loop
#   1  could not run (missing jq, unwritable temp dir)
#   2  hook not found — nothing to probe
#   3  hook FAILS OPEN — it deleted the state file on a normal turn shape
#
# Override the hook location for testing:  CPM_RALPH_STOP_HOOK=/path/to/stop-hook.sh

set -uo pipefail

# Two plugins implement this loop and CPM works with either: `ralph-loop` (Anthropic,
# the maintained line) and `ralph-wiggum` (the original it forked from). Their hooks are
# installed at the same relative path under different plugin names, so both are probed
# rather than one being assumed -- naming only ralph-wiggum would report "not found" on a
# machine that had switched, turning a silent failure into a spurious one.
#
# EVERY candidate is probed, not the first match. Both plugins can be enabled at once,
# in which case both Stop hooks fire on the same session and the state file only has to
# be deleted by ONE of them for the loop to die. So a single fails-open hook decides the
# verdict for the machine, whatever else is installed alongside it.
PROBE_CANDIDATES=()
if [[ -n "${CPM_RALPH_STOP_HOOK:-}" ]]; then
  PROBE_CANDIDATES=("$CPM_RALPH_STOP_HOOK")
else
  for plugin in ralph-loop ralph-wiggum; do
    for candidate in "$HOME"/.claude/plugins/cache/*/"$plugin"/*/hooks/stop-hook.sh; do
      [[ -f "$candidate" ]] && PROBE_CANDIDATES+=("$candidate")
    done
  done
fi

if [[ ${#PROBE_CANDIDATES[@]} -eq 0 ]] || [[ ! -f "${PROBE_CANDIDATES[0]}" ]]; then
  printf 'PROBE\tnot-found\t%s\n' "${PROBE_CANDIDATES[0]:-<no ralph-loop or ralph-wiggum stop hook on disk>}"
  exit 2
fi

command -v jq >/dev/null 2>&1 || { printf 'PROBE\tcannot-run\t%s\n' "jq not on PATH"; exit 1; }

WORK=$(mktemp -d 2>/dev/null) || { printf 'PROBE\tcannot-run\t%s\n' "could not create a temp dir"; exit 1; }
trap 'rm -rf "$WORK"' EXIT

mkdir -p "$WORK/.claude" || { printf 'PROBE\tcannot-run\t%s\n' "could not write to $WORK"; exit 1; }

STATE="$WORK/.claude/ralph-loop.local.md"

# Two assistant records. The first carries the turn's text; the last is a bare tool
# call, which is how a cpm:do story ends -- with a commit. The promise string is
# absent from both, so a hook that fails closed must leave the state file in place.
#
# No session_id is written. ralph-loop skips foreign sessions by comparing that field
# against the hook input's, and treats an absent one as legacy -- so omitting it is what
# makes the probe reach the branch being tested rather than the isolation guard.
TRANSCRIPT="$WORK/transcript.jsonl"
{
  printf '%s\n' '{"type":"assistant","message":{"role":"assistant","content":[{"type":"text","text":"Story 1 complete, committed locally."}]}}'
  printf '%s\n' '{"type":"assistant","message":{"role":"assistant","content":[{"type":"tool_use","name":"Bash","id":"probe","input":{"command":"git commit -m x"}}]}}'
} > "$TRANSCRIPT"

VERDICT=0

for hook in "${PROBE_CANDIDATES[@]}"; do
  [[ -f "$hook" ]] || continue

  cat > "$STATE" <<'STATE_EOF'
---
active: true
iteration: 1
max_iterations: 50
completion_promise: "CPM_RALPH_HOOK_PROBE"
started_at: "2026-01-01T00:00:00Z"
---

Probe prompt. This run is a pre-flight check and does no work.
STATE_EOF

  ( cd "$WORK" && printf '{"transcript_path":"%s","session_id":""}' "$TRANSCRIPT" | bash "$hook" ) >/dev/null 2>&1

  if [[ -f "$STATE" ]]; then
    printf 'PROBE\tfails-closed\t%s\n' "$hook"
  else
    printf 'PROBE\tfails-open\t%s\n' "$hook"
    VERDICT=3
  fi
done

exit "$VERDICT"
