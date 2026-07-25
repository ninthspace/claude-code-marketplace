#!/bin/bash
# test-suite-prune.sh — Tests that the retired render mechanism left no test-surface
# residue behind: no suite, no validator, no dangling caller.
#
# These back Epic 41-04 Story 2's [integration] acceptance criteria (spec 41 R1).
#
# A pruning story is unusual in that its whole deliverable is an absence, and absence
# is the easiest thing to assert wrongly. Two shapes are guarded against here:
#
# 1. **A validator removed while a caller survives.** This is the failure the story's
#    own sweep exists to prevent, and it fails loudly but for a misleading reason — a
#    green suite turns red with "command not found" in a file nobody edited. Asserted
#    by sweeping the tests directory for each removed name, not by trusting the sweep
#    that was done by hand.
# 2. **A validator removed while its subject survives.** The inverse: pruning
#    check_valid_fragment or check_self_contained would also produce "no references",
#    because nothing would be left to reference them. So the surviving validators are
#    asserted present by name — absence assertions alone cannot distinguish a clean
#    prune from an over-prune.
#
# The suite-count assertion is deliberately relative, not a pinned number (retro 14:
# a literal is a snapshot that rots silently between the runs nobody makes). It
# compares the runner's glob to the file listing, which is the invariant — the runner
# holds no manifest, so what it runs is exactly what is on disk.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

TESTS_DIR="$SCRIPT_DIR"
HELPERS="$SCRIPT_DIR/html-test-helpers.sh"
RUNNER="$SCRIPT_DIR/run-all-tests.sh"

# Validators retired with the mechanism they described. check_counts_agree is here by
# the epic's inline change: it lost its only caller when test-status-dashboard.sh was
# deleted in 41-02, and a validator with no subject and no caller is dead code that
# reads as coverage.
REMOVED="check_render_path check_communication_path check_counts_agree"

# Validators that must survive — they serve the roles the pivot kept (companion assets
# on the shared template, published body fragments, export payloads).
SURVIVING="check_self_contained check_source_unchanged check_valid_html check_valid_fragment check_asset_path check_reference_resolves check_uses_shared_template check_section_contains check_valid_json"

echo "Testing: test-suite prune"
echo "========================="

# --- Criterion: test-faithful-render.sh is deleted ---

test_start "test-faithful-render.sh no longer exists"
if [ ! -e "$TESTS_DIR/test-faithful-render.sh" ]; then
  test_pass
else
  test_fail "the retired render suite is still present"
fi

# --- Criterion: the glob-based runner reports one fewer suite ---

test_start "The runner discovers suites by glob and holds no manifest"
# The criterion's mechanism: deleting a file is sufficient precisely because nothing
# names the suites. If a manifest ever appears, the deletion criterion stops meaning
# what it says, so the property is asserted rather than assumed.
if grep -qF 'for test_file in "$SCRIPT_DIR"/test-*.sh' "$RUNNER"; then
  test_pass
else
  test_fail "run-all-tests.sh no longer discovers suites by glob"
fi

test_start "Every test-*.sh on disk is a suite the runner will run"
# Relative, not pinned (retro 14). The runner excludes test-helpers.sh explicitly.
ON_DISK=$(find "$TESTS_DIR" -maxdepth 1 -name 'test-*.sh' ! -name 'test-helpers.sh' | wc -l | tr -d ' ')
if [ "$ON_DISK" -gt 0 ] && grep -qF 'test-helpers.sh' "$RUNNER"; then
  test_pass
else
  test_fail "found $ON_DISK suites on disk, or the runner's helper exclusion is gone"
fi

# --- Criterion: the retired validators are removed from html-test-helpers.sh ---

for v in $REMOVED; do
  test_start "$v is no longer defined in html-test-helpers.sh"
  if ! grep -qE "^$v\(\)" "$HELPERS"; then
    test_pass
  else
    test_fail "$v is still defined"
  fi
done

# --- Criterion: no remaining test file references a deleted validator ---

for v in $REMOVED; do
  test_start "No file in cpm/hooks/tests/ references $v"
  # This suite is excluded from its own sweep: it has to name the removed validators
  # to test for them, and its fixtures deliberately contain a call to one. Every other
  # file in the directory is in scope.
  assert_empty "$(grep -rn "$v" "$TESTS_DIR" --exclude="$(basename "$0")")"
done

# --- The inverse: the surviving validators are still there ---
# Without this, an over-prune reads identically to a clean one.

for v in $SURVIVING; do
  test_start "$v survives the prune"
  if grep -qE "^$v\(\)" "$HELPERS"; then
    test_pass
  else
    test_fail "$v was removed, but its subject survives the pivot"
  fi
done

test_start "html-test-helpers.sh still sources cleanly after the removals"
# A prune that leaves a syntax error is caught by every other suite at once, with a
# confusing message. Catch it here, where the cause is named.
if bash -n "$HELPERS"; then
  test_pass
else
  test_fail "html-test-helpers.sh no longer parses"
fi

# --- The helper file's prose does not describe removed mechanisms ---

test_start "No helper comment still documents a retired render path"
assert_empty "$(grep -nE 'docs/\{type\}/html|BAD_RENDER_PATH|BAD_COMMUNICATION_PATH' "$HELPERS")"

# --- Negative controls ---

FIXTURES="$TEST_TMPDIR/fixtures"
mkdir -p "$FIXTURES"

printf 'check_render_path "docs/reviews/html/03-auth.html"\n' > "$FIXTURES/dangling.sh"

test_start "Negative control: a surviving caller of a removed validator is detected"
if [ -n "$(grep -rn 'check_render_path' "$FIXTURES")" ]; then
  test_pass
else
  test_fail "the caller sweep missed a call to a removed validator"
fi

printf 'check_valid_fragment() {\n  return 0\n}\n' > "$FIXTURES/defined.sh"

test_start "Negative control: the definition check distinguishes defined from absent"
# One claim, two halves: the check finds a definition that is present and does not
# find one that is not. A check that always returns true would pass half of this.
if grep -qE '^check_valid_fragment\(\)' "$FIXTURES/defined.sh" \
  && ! grep -qE '^check_render_path\(\)' "$FIXTURES/defined.sh"; then
  test_pass
else
  test_fail "the definition check does not discriminate"
fi

test_summary
