#!/bin/bash
# test-ralph-hook-probe.sh — Tests for the ralph loop stop-hook liveness probe.
#
# --- Why this suite exists ---------------------------------------------------------------
#
# Pre-flight step 1c used to check that the ralph Stop hook was *registered*. A live
# spec-mode run passed that check and then died at the first iteration boundary: the hook
# read a tool_use-only assistant record as "the model said nothing", deleted the loop's
# state file and exited 0. Presence was true the whole time. The property that matters is
# which DIRECTION the hook fails in, and only running it answers that.
#
# --- What has an oracle here --------------------------------------------------------------
#
#   * **The probe is behavioural, so the fixtures are hooks, not strings.** Each fixture is a
#     tiny stop-hook stand-in with one interesting behaviour. Asserting on the probe's exit
#     code against a hook that deletes, and against one that does not, is what shows the
#     probe discriminates. A suite that only ran it against the real installed hook would
#     pass identically whether the probe worked or always returned 0.
#   * **Every verdict has its opposite.** `fails-open` is only meaningful if `fails-closed`
#     is reachable by the same code path, so the two fixtures differ in exactly one line.
#   * **The probe must not report on a hook it never ran.** A hook that is missing, or an
#     environment without jq, has to be distinguishable from a hook that passed — otherwise
#     an install problem reads as a safety guarantee. Those are separate exit codes and are
#     asserted as such.
#
# --- What this suite does not test ----------------------------------------------------------
#
# The real installed hook. That lives outside the repo, is a third-party file, and differs
# per machine and per plugin version — which is the entire reason the probe runs it at
# pre-flight rather than the suite asserting anything about it here.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

PROBE="$SCRIPT_DIR/../lib/ralph-hook-probe.sh"

echo "Testing: ralph loop stop-hook liveness probe (ralph-loop / ralph-wiggum)"
echo "========================================================================"

FIXTURES=$(mktemp -d)
trap 'rm -rf "$FIXTURES"' EXIT

# A hook that deletes the state file whenever it cannot find text in the last assistant
# record — ralph-wiggum 1.0.0's behaviour, reduced to the one line that matters.
cat > "$FIXTURES/fails-open.sh" <<'EOF'
#!/bin/bash
set -euo pipefail
cat > /dev/null
rm -f .claude/ralph-loop.local.md
exit 0
EOF

# The same hook with the deletion removed: it declines to promise and lets the loop run.
cat > "$FIXTURES/fails-closed.sh" <<'EOF'
#!/bin/bash
set -euo pipefail
cat > /dev/null
exit 0
EOF

# A hook that deletes only when the promise is genuinely present. The probe's transcript
# never contains the promise, so this must read as safe — this is the fixture that catches
# a probe which calls every hook unsafe.
cat > "$FIXTURES/deletes-only-on-promise.sh" <<'EOF'
#!/bin/bash
set -euo pipefail
IN=$(cat)
T=$(echo "$IN" | jq -r '.transcript_path')
if grep -q 'CPM_RALPH_HOOK_PROBE' "$T" 2>/dev/null; then
  rm -f .claude/ralph-loop.local.md
fi
exit 0
EOF

chmod +x "$FIXTURES"/*.sh

probe_with() { CPM_RALPH_STOP_HOOK="$1" bash "$PROBE" 2>/dev/null; }
probe_code() { CPM_RALPH_STOP_HOOK="$1" bash "$PROBE" >/dev/null 2>&1; echo $?; }

test_start "a hook that deletes the state file on a tool_use-only turn is reported fails-open"
assert_equals "3" "$(probe_code "$FIXTURES/fails-open.sh")"

test_start "control: the same probe reports fails-closed for a hook that keeps the file"
assert_equals "0" "$(probe_code "$FIXTURES/fails-closed.sh")"

test_start "the verdict word matches the exit code, so a log reader sees the same answer"
assert_contains "$(probe_with "$FIXTURES/fails-open.sh")" "fails-open"

test_start "control: and the safe hook's verdict word is the opposite one"
assert_contains "$(probe_with "$FIXTURES/fails-closed.sh")" "fails-closed"

test_start "a hook that deletes only on a real promise is safe, not fails-open"
assert_equals "0" "$(probe_code "$FIXTURES/deletes-only-on-promise.sh")"

test_start "a missing hook is its own code, never reported as safe"
assert_equals "2" "$(probe_code "$FIXTURES/no-such-hook.sh")"

test_start "control: the missing-hook verdict says not-found rather than a pass"
assert_contains "$(probe_with "$FIXTURES/no-such-hook.sh")" "not-found"

test_start "the not-found line is tab-separated like every other record CPM emits"
assert_not_contains "$(probe_with "$FIXTURES/no-such-hook.sh")" '\t'

test_start "the probe names the hook it ran, so a wrong path is visible in the log"
assert_contains "$(probe_with "$FIXTURES/fails-closed.sh")" "$FIXTURES/fails-closed.sh"

# Both ralph-loop and ralph-wiggum can be enabled at once -- they install the same hook
# at the same relative path under different plugin names, so both Stop hooks fire on the
# same session. The state file only has to be deleted by ONE of them for the loop to die,
# so a safe hook alongside a dangerous one is not a safe machine. These use the discovery
# path rather than CPM_RALPH_STOP_HOOK, since the override deliberately probes one hook.
FAKE_HOME=$(mktemp -d)
install_fake() { # <plugin-name> <fixture>
  local d="$FAKE_HOME/.claude/plugins/cache/some-marketplace/$1/1.0.0/hooks"
  mkdir -p "$d" && cp "$2" "$d/stop-hook.sh"
}
discover_code() { HOME="$FAKE_HOME" bash "$PROBE" >/dev/null 2>&1; echo $?; }

test_start "discovery finds a hook installed under the ralph-loop plugin name"
install_fake ralph-loop "$FIXTURES/fails-closed.sh"
assert_equals "0" "$(discover_code)"

test_start "a fails-open ralph-wiggum alongside a safe ralph-loop still condemns the machine"
install_fake ralph-wiggum "$FIXTURES/fails-open.sh"
assert_equals "3" "$(discover_code)"

test_start "control: with the dangerous one replaced, the same two installs pass"
install_fake ralph-wiggum "$FIXTURES/fails-closed.sh"
assert_equals "0" "$(discover_code)"

test_start "both hooks are named in the output, not just the one that decided the code"
install_fake ralph-wiggum "$FIXTURES/fails-open.sh"
assert_contains "$(HOME="$FAKE_HOME" bash "$PROBE" 2>/dev/null)" "ralph-loop"

test_start "control: and the wiggum install is named in that same output"
assert_contains "$(HOME="$FAKE_HOME" bash "$PROBE" 2>/dev/null)" "ralph-wiggum"

present_after() { [[ -f "$1" ]] && echo "present" || echo "gone"; }

# The probe runs a third-party script. If it ran that script against the real project
# directory rather than a scratch copy, a fails-open hook would delete the user's live loop
# as a side effect of checking whether it would.
test_start "the probe leaves any state file in the working directory untouched"
GUARD=$(mktemp -d)
mkdir -p "$GUARD/.claude"
echo "live loop state" > "$GUARD/.claude/ralph-loop.local.md"
( cd "$GUARD" && CPM_RALPH_STOP_HOOK="$FIXTURES/fails-open.sh" bash "$PROBE" >/dev/null 2>&1 )
assert_equals "present" "$(present_after "$GUARD/.claude/ralph-loop.local.md")"

test_start "control: the fixture used above really does delete a state file when run directly"
( cd "$GUARD" && cat /dev/null | bash "$FIXTURES/fails-open.sh" >/dev/null 2>&1 )
assert_equals "gone" "$(present_after "$GUARD/.claude/ralph-loop.local.md")"

test_summary
