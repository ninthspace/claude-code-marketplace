#!/bin/bash
# test-ralph-prompt-wrapping.sh — the assembled ralph prompt is wrapped before it is written,
# and with the one tool that cannot damage it (review 02, OBS-14).
#
# The prompt was written as a single 5,246-character line. A supervising operator stopped a
# live run over it, reading `ninths/hooks` and `coverage-rollup.sh--spec` as corruption; they
# were terminal overwrite at wrap boundaries on a line no terminal can render. Nothing was
# wrong with the file — but the prompt is the one artefact a human watching an unattended run
# actually sees, at every iteration, and it was unreadable.
#
# --- What has an oracle here ------------------------------------------------------------
#
# Two things, both executed rather than grepped:
#
#   1. **The tool choice is load-bearing.** `fold -s` and `fmt -s` differ on exactly one
#      input — a token longer than the width — and the assembled prompt contains one: the
#      interpolated absolute path to `coverage-rollup.sh` inside the plugin cache. This suite
#      runs both against that shape and requires them to disagree. If they ever stop
#      disagreeing the rule is free, and the prose arguing for it is misleading.
#
#      This is not hypothetical margin. The path is ~96 characters against a 100-column
#      target; a version bump, a longer marketplace name or a longer home directory spends
#      the difference, and `fold` then writes the break into the file the loop re-reads every
#      iteration — turning a display artifact into a persisted one.
#
#   2. **The `---` rule is real.** The stop hook's body parser skips *every* line matching
#      `^---$`, not only the frontmatter fences, so such a line is silently dropped from the
#      prompt. The awk program is extracted from the skill's own prose and run against a
#      fixture, so a claim about an external parser is demonstrated rather than asserted —
#      and rewriting the quoted program to something that does not behave this way fails here.
#
# --- Regression nets over prose -----------------------------------------------------------
#
# That the wrap is stated at all, that it names `fmt`, that it does not name `fold` as the
# tool to use, and that it sits before Step 3 so the dry-run and the written file cannot
# diverge. Plus the must-NOT that the template itself is still one line: its stated length is
# measured on it, and a well-meaning reflow of the template would break that measurement
# while looking like the fix this suite is about.
#
# Usage: bash cpm/hooks/tests/test-ralph-prompt-wrapping.sh

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

RALPH_SKILL="$SCRIPT_DIR/../../skills/ralph/SKILL.md"

echo "Testing: the assembled ralph prompt is wrapped, and with a token-safe tool"
echo "========================================================================="

test_start "control: the ralph skill is readable"
assert_equals "yes" "$( [ -r "$RALPH_SKILL" ] && echo yes || echo no )"

test_start "slice: the wrapping section spans its own section and no more"
assert_slice_bounded "$RALPH_SKILL" '^#### Wrap the assembled prompt' '^### Step 3' 5 20

WRAP=$(sed -n '/^#### Wrap the assembled prompt/,/^### Step 3/p' "$RALPH_SKILL")

# --- Regression nets: the rule is stated where assembly can act on it --------------------

test_start "the skill states the wrap command"
assert_contains "$WRAP" "fmt -s -w 100"

# The must-NOT that matters. `fold` is the obvious tool, it is what the review originally
# proposed, and substituting it back would look like a simplification.
test_start "and does not prescribe fold as the tool to use"
assert_not_contains "$WRAP" "Use \`fold -s\`"

test_start "the skill says why fold is rejected, not merely that it is"
assert_contains "$WRAP" "longer than the width"

test_start "the wrap happens before the dry-run and the write can diverge"
ln_wrap=$(grep -n '^#### Wrap the assembled prompt' "$RALPH_SKILL" | cut -d: -f1)
ln_step3=$(grep -n '^### Step 3: State File Write and Launch' "$RALPH_SKILL" | cut -d: -f1)
if [ -n "$ln_wrap" ] && [ -n "$ln_step3" ] && [ "$ln_wrap" -lt "$ln_step3" ]; then
  test_pass
else
  test_fail "expected the wrap section before Step 3, got wrap=$ln_wrap step3=$ln_step3"
fi

# --- Oracle 1: fold and fmt must actually disagree on this prompt's shape ----------------

command -v fmt >/dev/null && command -v fold >/dev/null || {
  echo "  SKIP: fmt or fold unavailable; the executable half cannot run"
}

# The shape the prompt actually contains: a plugin-cache path long enough to matter, set in a
# sentence. Built here rather than read from the template, because the template holds the
# uninterpolated `{rollup_script}` placeholder — the long token only exists after assembly.
# The version segment is deliberately not this plugin's real version: a version literal in a
# test is a thing to update on every release, and `test-version-agreement.sh` fails the suite
# for exactly that. Any plausible segment exercises the length; none of this reads the cache.
LONG_PATH="/Users/someone/.claude/plugins/cache/ninthspace-marketplace/cpm/0.0.0/hooks/lib/coverage-rollup.sh"
FIXTURE=$(mktemp)
printf 'run bash %s --spec docs/specifications/01-spec-thing.md --verdict and read its exit code\n' \
  "$LONG_PATH" > "$FIXTURE"

test_start "control: the interpolated path is long enough for the tools to differ"
if [ "${#LONG_PATH}" -gt 80 ]; then
  test_pass
else
  test_fail "fixture path is ${#LONG_PATH} chars — too short to exercise the difference"
fi

# Width 80 rather than the skill's 100: the point is to demonstrate the failure mode the tool
# choice guards against, and at 100 today's path fits with a few characters to spare. That
# margin is the thing that is not durable, so the test must not depend on it.
test_start "fold splits a token longer than the width — the failure mode"
if fold -s -w 80 "$FIXTURE" | grep -qF "$LONG_PATH"; then
  test_fail "fold -s -w 80 left the path intact; the stated reason for choosing fmt no longer holds"
else
  test_pass
fi

test_start "fmt leaves it whole — which is why the skill names fmt"
if fmt -s -w 80 "$FIXTURE" | grep -qF "$LONG_PATH"; then
  test_pass
else
  test_fail "fmt -s -w 80 split the path; the skill's tool choice does not achieve what it claims"
fi

# Wrapping must not change the words, only where the lines end. Checked on the tool the skill
# actually names, at the width it actually names.
test_start "and fmt at the stated width is word-for-word lossless"
SRC_WORDS=$(tr -s '[:space:]' '\n' < "$FIXTURE" | sed '/^$/d')
FMT_WORDS=$(fmt -s -w 100 "$FIXTURE" | tr -s '[:space:]' '\n' | sed '/^$/d')
assert_equals "$SRC_WORDS" "$FMT_WORDS"

rm -f "$FIXTURE"

# --- Oracle 2: the `---` rule, demonstrated with the skill's own quoted parser ------------

test_start "the skill states that no wrapped line may be a bare ---"
assert_contains "$WRAP" '`---`'

# Pull the awk program out of the skill's prose. The skill is making a claim about a parser
# it does not own; extracting and running it is the difference between recording the claim
# and showing it.
BODY_AWK=$(printf '%s' "$WRAP" | grep -oE "awk '[^']+'" | head -1 | sed "s/^awk '//; s/'$//")

test_start "control: the body parser could be extracted from the skill"
assert_equals "non-empty" "$( [ -n "$BODY_AWK" ] && echo non-empty || echo empty )"

STATE=$(mktemp)
printf -- '---\niteration: 1\n---\n\nfirst line\n---\nsecond line\n' > "$STATE"

test_start "the quoted parser drops a bare --- line from the body, as the skill claims"
PARSED=$(awk "$BODY_AWK" "$STATE")
if printf '%s' "$PARSED" | grep -qF 'first line' \
  && printf '%s' "$PARSED" | grep -qF 'second line' \
  && ! printf '%s\n' "$PARSED" | grep -qE '^---$'; then
  test_pass
else
  test_fail "expected both prose lines and no --- separator, got: $(printf '%s' "$PARSED" | tr '\n' '|')"
fi

# The control the assertion above needs: an ordinary line is not dropped, so "no --- in the
# output" is not being satisfied by a parser that emits nothing.
test_start "control: the same parser passes ordinary lines through"
assert_equals "2" "$(awk "$BODY_AWK" "$STATE" | grep -c 'line')"

rm -f "$STATE"

# --- The must-NOT: the template itself is still one line ---------------------------------

test_start "the prompt template is still a single line"
# The template is the fenced block's one content line — the longest line in the file by a
# wide margin, and the only one carrying the completion-promise literal alongside /cpm:do.
TEMPLATE_LINES=$(grep -c '^Run /cpm:do on epics ' "$RALPH_SKILL")
assert_equals "1" "$TEMPLATE_LINES"

test_summary
