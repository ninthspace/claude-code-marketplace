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

PROBE_HOOK="${CPM_RALPH_STOP_HOOK:-}"

if [[ -z "$PROBE_HOOK" ]]; then
  # Newest installed version wins; the cache holds one directory per version.
  for candidate in "$HOME"/.claude/plugins/cache/*/ralph-wiggum/*/hooks/stop-hook.sh; do
    [[ -f "$candidate" ]] && PROBE_HOOK="$candidate"
  done
fi

if [[ -z "$PROBE_HOOK" || ! -f "$PROBE_HOOK" ]]; then
  printf 'PROBE\tnot-found\t%s\n' "${PROBE_HOOK:-<no ralph-wiggum stop hook on disk>}"
  exit 2
fi

command -v jq >/dev/null 2>&1 || { printf 'PROBE\tcannot-run\t%s\n' "jq not on PATH"; exit 1; }

WORK=$(mktemp -d 2>/dev/null) || { printf 'PROBE\tcannot-run\t%s\n' "could not create a temp dir"; exit 1; }
trap 'rm -rf "$WORK"' EXIT

mkdir -p "$WORK/.claude" || { printf 'PROBE\tcannot-run\t%s\n' "could not write to $WORK"; exit 1; }

STATE="$WORK/.claude/ralph-loop.local.md"
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

# Two assistant records. The first carries the turn's text; the last is a bare tool
# call, which is how a cpm:do story ends -- with a commit. The promise string is
# absent from both, so a hook that fails closed must leave the state file in place.
TRANSCRIPT="$WORK/transcript.jsonl"
{
  printf '%s\n' '{"type":"assistant","message":{"role":"assistant","content":[{"type":"text","text":"Story 1 complete, committed locally."}]}}'
  printf '%s\n' '{"type":"assistant","message":{"role":"assistant","content":[{"type":"tool_use","name":"Bash","id":"probe","input":{"command":"git commit -m x"}}]}}'
} > "$TRANSCRIPT"

( cd "$WORK" && printf '{"transcript_path":"%s"}' "$TRANSCRIPT" | bash "$PROBE_HOOK" ) >/dev/null 2>&1

if [[ -f "$STATE" ]]; then
  printf 'PROBE\tfails-closed\t%s\n' "$PROBE_HOOK"
  exit 0
fi

printf 'PROBE\tfails-open\t%s\n' "$PROBE_HOOK"
exit 3
