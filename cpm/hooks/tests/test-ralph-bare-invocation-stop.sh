#!/bin/bash
# test-ralph-bare-invocation-stop.sh — the epic-mode stop is actionable, and still a stop.
#
# --- The failure this covers --------------------------------------------------------
#
# A bare `/cpm:ralph` in a repository holding a specification and no epics reaches Step
# 1a.3's epic-mode branch, which said only "No incomplete epics found. Nothing to run." In
# a field test the agent did not stop: it ran an `AskUserQuestion` offering spec mode with
# "Spec mode on the settler spec (Recommended)" first, and the whole five-hour run executed
# on that improvised branch.
#
# Two things were wrong and only one of them was the agent. The stop reported nothing to run
# in a repository that plainly had something to run, and named no way forward — a dead end
# is worth routing around. But offering spec mode moves the mode decision out of the
# argument, where the skill puts it deliberately, and into a prompt; and spec mode commits a
# loop to generating an entire epic set and delivering it, which is a far larger thing than
# a bare invocation asked for.
#
# So the branch names the specs and the command, and still stops.
#
# --- Which assertions are oracles ---------------------------------------------------
#
# **The glob correspondence is.** The pattern the branch globs is read out of ralph, the
# path `cpm:spec` writes is read out of its own output-target line, and the two are matched
# with the shell's own pattern matching. Neither side is pinned to the other, so renaming
# the specifications directory in both places stays green while renaming it in one fails —
# and a branch globbing a directory nothing writes to would find nothing at runtime and say
# nothing, which is the failure that looks exactly like "no specs exist".
#
# **The must-NOT is scoped and paired.** `AskUserQuestion` is legitimate three lines below,
# in Step 1a.4, so the prohibition is over the epic-mode bullet alone. It is paired with
# controls that the bullet still stops and still names a way forward, because a prohibition
# on its own is satisfied by deleting the branch.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

RALPH_SKILL="$SCRIPT_DIR/../../skills/ralph/SKILL.md"
SPEC_SKILL="$SCRIPT_DIR/../../skills/spec/SKILL.md"

echo "Testing ralph's bare-invocation stop in a spec-only repository"

# The epic-mode bullet alone. The spec-mode bullet follows it and Step 1a.4 follows that;
# both legitimately do things this bullet must not, so the slice stops at the next bullet.
epic_mode_branch() {
  awk '/^   - \*\*Epic mode\*\*/ { found = 1; print; next }
       found && /^   - / { exit }
       found { print }' "$RALPH_SKILL"
}

spec_mode_branch() {
  awk '/^   - \*\*Spec mode\*\*/ { found = 1; print; next }
       found && /^[0-9]+\. / { exit }
       found { print }' "$RALPH_SKILL"
}

test_start "control: the epic-mode branch was found and is one bullet, not the section"
BRANCH=$(epic_mode_branch)
BRANCH_LINES=$(printf '%s\n' "$BRANCH" | grep -c .)
if [ -n "$BRANCH" ] && [ "$BRANCH_LINES" -le 3 ]; then
  test_pass
else
  test_fail "the epic-mode slice is $BRANCH_LINES lines, so it has swallowed its neighbours"
fi

test_start "control: the spec-mode branch is a separate slice"
assert_contains "$(spec_mode_branch)" "Spec mode"

# --- The must-NOT: the branch does not offer spec mode ---------------------------------

test_start "the epic-mode branch must NOT gate on an AskUserQuestion"
assert_not_contains "$BRANCH" "AskUserQuestion"

# The control that makes the scoping honest. The prohibition is over one bullet, and Step
# 1a.4's gate is the legitimate use it must not reach.
test_start "control: the confirmation gate three lines below is untouched"
assert_contains "$(cat "$RALPH_SKILL")" "Present the discovered epics and confirm with AskUserQuestion"

test_start "the branch still stops"
assert_contains "$BRANCH" "stop"

test_start "and still carries the message it always did"
assert_contains "$BRANCH" "No incomplete epics found. Nothing to run."

# --- The remedy: it names a way forward ------------------------------------------------

test_start "the branch names the spec-mode invocation form"
assert_contains "$BRANCH" '/cpm:ralph {path}'

# --- The oracle: the glob matches what cpm:spec writes ----------------------------------

# The first backticked token in the branch that looks like a path pattern — a `/` and a `*`.
# Spelling `docs/specifications/` here would pin this suite to a directory named in exactly
# two places, so renaming it in both would fail here while both sides still agreed; that is
# the mutation this extraction was rewritten to survive. The branch's other backticked token
# is the invocation form, which has no `*`.
SPEC_GLOB=$(printf '%s' "$BRANCH" | grep -o '`[^`]*`' | tr -d '`' | grep '/' | grep '\*' | head -1)
SPEC_OUTPUT=$(grep -o '^\*\*Output target\*\*: .*' "$SPEC_SKILL" | sed 's/^\*\*Output target\*\*: //')

test_start "control: a glob was read out of the epic-mode branch"
assert_equals "non-empty" "$( [ -n "$SPEC_GLOB" ] && echo non-empty || echo empty )"

test_start "control: an output path was read out of cpm:spec"
assert_equals "non-empty" "$( [ -n "$SPEC_OUTPUT" ] && echo non-empty || echo empty )"

# Fill cpm:spec's placeholders the way a run would, then ask whether ralph's glob would find
# the result — using the shell's own matcher, which is what a Glob call resolves to.
FILLED="${SPEC_OUTPUT/\{nn\}/07}"
FILLED="${FILLED/\{slug\}/expense-settler}"

matches_glob() {
  # shellcheck disable=SC2254
  case "$1" in
    $SPEC_GLOB) return 0 ;;
    *)          return 1 ;;
  esac
}

test_start "the glob the branch uses finds the path cpm:spec writes"
if matches_glob "$FILLED"; then
  test_pass
else
  test_fail "glob $SPEC_GLOB does not match $FILLED, so the branch would report no specs in a repo that has one"
fi

# The discriminating control. A glob ending `/*` matches the assertion above and also matches
# every companion asset, plan and stray file in that directory — so the check has to show it
# can tell a spec from a neighbour. The sibling is built from the real path's own directory
# rather than written out, so a renamed directory keeps this control pointed at the right one.
SPEC_DIR="${FILLED%/*}"

test_start "must NOT match a file in the same directory that is not a spec"
if matches_glob "$SPEC_DIR/07-spec-expense-settler-mockup.html"; then
  test_fail "the glob matched an HTML companion asset in $SPEC_DIR, so it is not selecting specs"
else
  test_pass
fi

test_start "must NOT match a path outside the spec directory"
if matches_glob "docs/epics/07-01-epic-expense-settler.md"; then
  test_fail "the glob reaches outside $SPEC_DIR"
else
  test_pass
fi

test_summary
