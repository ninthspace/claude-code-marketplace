#!/bin/bash
# test-environmental-integration.sh — Epic 46-01 Story 4: cross-story integration.
#
# The three [integration] criteria of "Verify cross-story integration for Environmental
# Constraint Traceability", covering NFR1 (existing specs parse identically), NFR4 (the
# partition still holds) and NFR5 (no new runtime dependencies).
#
# Where Stories 2 and 3 build fixtures to construct the interesting cases, this suite runs
# against the repository's own 46 specification documents. That is Bella's constraint from
# spec 46's Section 5 perspectives, carried into the epic: a fixture proves the parser does
# what the fixture was built to elicit, and it was a real-spec assertion that caught the
# spec 45 regression.
#
# --- Why the baseline holds only two record types --------------------------------
#
# `REQ` and `EXCLUDED` are functions of the spec **document** alone: which requirements it
# carries, and which it ruled out. `STATE`, `SUMMARY`, `ROW`, `MATRIX` and `CRITERION`
# depend on **matrix contents**, which move as work proceeds -- ticking one box in a
# coverage matrix takes a requirement from in-progress to delivered and rewrites that
# spec's SUMMARY line.
#
# A committed fixture holding the second group would measure this repository's work in
# progress as well as the parser, and every epic worked here would break it in a way
# indistinguishable from a regression. Epic 46-01 hit this on itself: by Story 3 the
# baseline no longer matched, entirely because the epic had ticked rows in its own coverage
# matrix. So the durable half is asserted here, permanently, and the volatile half is a
# before/after diff taken at the moment of a change -- `make-coverage-baseline.sh --all`,
# which Task 3.1 used to show 45 of the 46 specs byte-identical across every record type.
#
# --- Two halves to the partition criterion, and why ------------------------------
#
# The criterion asks for the partition "with ENV/ENVX in play, asserted against the repo's
# real specs and not only fixtures". No specification in this repository carries an ENVn
# label yet: teaching cpm:spec to write them is epic 46-02, and spec 46 is *about* the class
# rather than an instance of it. One document cannot satisfy both halves today, so both are
# asserted:
#
#   * the partition holds across all 46 real specs as they actually are; and
#   * it holds with ENV1 and ENVX1 in play, against a real spec -- spec 46 itself, copied
#     and given two bullets under its existing non-functional heading, so every other
#     feature of a real document is still present and only the labels are added.
#
# When 46-02 lands and a spec in this repo carries a real ENVn, the second half stops
# needing the augmentation. It is written to keep working either way.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"
source "$SCRIPT_DIR/coverage-fixture-helpers.sh"

REPO_ROOT="$(cd "$SCRIPT_DIR" && git rev-parse --show-toplevel 2>/dev/null)"
BASELINE="$SCRIPT_DIR/fixtures/coverage-baseline-46.tsv"
GENERATOR="$SCRIPT_DIR/make-coverage-baseline.sh"

echo "Testing cross-story integration for environmental constraints (Epic 46-01 Story 4)"

test_start "control: the repository root resolves, so the assertions below have a subject"
assert_contains "$REPO_ROOT" "/"

# --- Criterion 1: the durable records are byte-identical before and after ---------------
#
# The baseline was regenerated once since it was taken, and the reason belongs beside it
# because a regenerated baseline is indistinguishable from a defeated one. `rollup_spec_scope`
# now emits its records on the no-matrix path as well as the matching one, so the archived
# specs — which no matrix names — went from `<no records>` to their own `REQ` and `EXCLUDED`
# lines. Nothing that already emitted records changed, and no exit code moved: the diff was
# 82 `REQ` and 7 `EXCLUDED` additions against 82 removed `<no records>` markers, which is the
# whole of it. A future diff that touches a spec already carrying records is a regression.

REGENERATED=$(cd "$REPO_ROOT" && bash "$GENERATOR" 2>/dev/null)

test_start "control: regenerating the baseline produced something to compare"
assert_contains "$REGENERATED" "REQ"

BASELINE_TEXT=$(cat "$BASELINE")

test_start "REQ and EXCLUDED records and exit codes are unchanged across every spec"
assert_equals "$BASELINE_TEXT" "$REGENERATED"

# --- Criterion 1b (control): the baseline still covers every spec on disk ---------------
#
# Retro 27, applied as this epic's plan asked: the count is read out of the artefact rather
# than pinned at 46, so a spec added tomorrow cannot silently narrow the check. Pinning the
# number would make the assertion above pass over a shrinking subset -- the exact failure
# NFR1's own wording had, naming a directory that holds 7 of the 46.

SPECS_ON_DISK=$(
  cd "$REPO_ROOT" && {
    ls docs/specifications/*.md 2>/dev/null
    ls docs/archive/specifications/*.md 2>/dev/null
  } | sed 's#.*/##' | LC_ALL=C sort
)

SPECS_IN_BASELINE=$(cut -f1 "$BASELINE" | LC_ALL=C sort -u)

test_start "control: there are specs on disk to have covered"
assert_contains "$SPECS_ON_DISK" "46-spec-environmental-requirements.md"

test_start "the baseline covers exactly the specs on disk, no more and no fewer"
assert_equals "$SPECS_ON_DISK" "$SPECS_IN_BASELINE"

# Both directories, stated separately. The set equality above would still hold if the
# generator and this assertion had made the same mistake about where specs live, since both
# read the same two paths -- so the count each directory contributes is asserted to be
# non-zero, which is what "a baseline over the live directory alone" would fail.
LIVE_COUNT=$(cd "$REPO_ROOT" && ls docs/specifications/*.md 2>/dev/null | wc -l | tr -d ' ')
ARCHIVE_COUNT=$(cd "$REPO_ROOT" && ls docs/archive/specifications/*.md 2>/dev/null | wc -l | tr -d ' ')

test_start "control: the live specification directory contributes specs"
assert_equals "yes" "$([ "$LIVE_COUNT" -gt 0 ] && echo yes || echo no)"

test_start "control: the archive directory contributes specs too"
assert_equals "yes" "$([ "$ARCHIVE_COUNT" -gt 0 ] && echo yes || echo no)"

test_start "and the baseline covers as many specs as both directories hold"
assert_equals "$((LIVE_COUNT + ARCHIVE_COUNT))" "$(printf '%s\n' "$SPECS_IN_BASELINE" | grep -c .)"

# --- Criterion 2: REQ = STATE ∪ EXCLUDED is an exact partition --------------------------
#
# Read from the records themselves rather than from the parser's intent (NFR4). A label in
# neither set is the silent-drop failure; a label in both is a double count.

REAL_ERRORS=""
REAL_CHECKED=0
REAL_WITH_RECORDS=0

while IFS= read -r spec; do
  [ -n "$spec" ] || continue
  REAL_CHECKED=$((REAL_CHECKED + 1))
  out=$(cd "$REPO_ROOT" && coverage_rollup_run --spec "$spec")
  [ -n "$out" ] || continue
  REAL_WITH_RECORDS=$((REAL_WITH_RECORDS + 1))
  errs=$(coverage_partition_errors "$out" "${spec##*/}")
  [ -n "$errs" ] && REAL_ERRORS="$REAL_ERRORS$errs"$'\n'
done <<EOF
$(cd "$REPO_ROOT" && { ls docs/specifications/*.md 2>/dev/null; ls docs/archive/specifications/*.md 2>/dev/null; })
EOF

test_start "control: every spec on disk was actually run, not skipped"
assert_equals "$((LIVE_COUNT + ARCHIVE_COUNT))" "$REAL_CHECKED"

# Without this the partition assertion is satisfied by 46 empty outputs. The archived specs
# legitimately emit nothing -- no matrix names them -- so the count that matters is how many
# produced records at all.
test_start "control: at least one real spec produced records to partition"
assert_equals "yes" "$([ "$REAL_WITH_RECORDS" -gt 0 ] && echo yes || echo no)"

test_start "REQ = STATE ∪ EXCLUDED holds for every real spec in the repository"
assert_empty "$REAL_ERRORS"

# The same property with the new class in play, against a real document rather than a built
# one. Spec 46 is copied under its own basename so the coverage matrices that name it still
# match -- matching compares basenames (AD2 of spec 44) -- and two bullets are inserted
# under the heading it already has.

AUG_DIR=$(coverage_fixture_dir env-augmented-real)
AUG_SPEC="$AUG_DIR/46-spec-environmental-requirements.md"

awk '{ print }
     /^## Non-Functional Requirements$/ {
       print ""
       print "- **ENV1 — PHP 8.2 or later available on the target host**"
       print "- **ENVX1 — must not require a queue worker**"
     }' "$REPO_ROOT/docs/specifications/46-spec-environmental-requirements.md" > "$AUG_SPEC"

AUG_OUT=$(cd "$REPO_ROOT" && coverage_rollup_run --spec "$AUG_SPEC")

test_start "control: the augmented real spec carries ENV1 and ENVX1 as requirements"
assert_equals "$(printf 'ENV1\nENVX1')" "$(
  printf '%s\n' "$AUG_OUT" | awk -F'\t' '$1 == "REQ" && ($2 == "ENV1" || $2 == "ENVX1") { print $2 }' | LC_ALL=C sort
)"

# And that the augmentation changed something: a spec whose ENV labels were silently dropped
# would give an identical requirement count to the unaugmented original, and the assertion
# above would be the only thing standing between that and a green run.
ORIG_OUT=$(cd "$REPO_ROOT" && coverage_rollup_run --spec docs/specifications/46-spec-environmental-requirements.md)
ORIG_REQS=$(coverage_count_type "$ORIG_OUT" REQ)
AUG_REQS=$(coverage_count_type "$AUG_OUT" REQ)

test_start "control: the augmentation added exactly the two requirements"
assert_equals "$((ORIG_REQS + 2))" "$AUG_REQS"

test_start "REQ = STATE ∪ EXCLUDED holds with ENV and ENVX in play on a real spec"
assert_empty "$(coverage_partition_errors "$AUG_OUT" "46-spec (augmented)")"

# --- Criterion 3: no new runtime dependencies (NFR5) -------------------------------------
#
# Shadow jq, python and python3 with stubs that refuse to run, then run this epic's suites
# under them. Behavioural rather than a grep of the sources for the word jq, which would
# pass for a script that reached for it under another name.

STUB_DIR="$TEST_TMPDIR/stubs"
mkdir -p "$STUB_DIR"
for tool in jq python python3; do
  printf '#!/bin/sh\necho "%s: not available" >&2\nexit 127\n' "$tool" > "$STUB_DIR/$tool"
  chmod +x "$STUB_DIR/$tool"
done

test_start "control: the stubs really do shadow the real tools"
STUB_RC=0
PATH="$STUB_DIR:$PATH" jq --version >/dev/null 2>&1 || STUB_RC=$?
assert_equals "127" "$STUB_RC"

# Named explicitly rather than globbed. A glob would sweep in this suite and recurse.
EPIC_SUITES="test-environmental-class.sh test-environmental-untraced.sh test-environmental-deferral.sh"

for suite in $EPIC_SUITES; do
  test_start "control: $suite exists to be run"
  assert_equals "yes" "$([ -f "$SCRIPT_DIR/$suite" ] && echo yes || echo no)"
done

for suite in $EPIC_SUITES; do
  SUITE_RC=0
  PATH="$STUB_DIR:$PATH" bash "$SCRIPT_DIR/$suite" >/dev/null 2>&1 || SUITE_RC=$?
  test_start "$suite passes with jq and python unavailable"
  assert_equals "0" "$SUITE_RC"
done

# The baseline generator drives coverage-rollup.sh across all 46 specs, so running it under
# the stubs is the broadest single exercise of the parser there is -- and its output being
# unchanged proves the tools were not merely unreached but unneeded.
STUBBED_BASELINE=$(cd "$REPO_ROOT" && PATH="$STUB_DIR:$PATH" bash "$GENERATOR" 2>/dev/null)

test_start "the whole-repository baseline is unchanged with jq and python unavailable"
assert_equals "$BASELINE_TEXT" "$STUBBED_BASELINE"

test_summary
