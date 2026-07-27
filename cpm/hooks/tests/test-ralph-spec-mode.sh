#!/bin/bash
# test-ralph-spec-mode.sh — Tests for `cpm:ralph`'s fourth input shape
# (Epic 45-02 Story 1, spec 45 FR1 and its must-NOT).
#
# --- What has an oracle here ------------------------------------------------------------
#
# The criterion is a mapping — four argument shapes onto two modes — so the assertions that
# mean something are the ones that can disagree with something else:
#
#   * **Arithmetic.** The shapes are counted out of the Input list and the modes out of the
#     resolution table, from opposite ends. A fifth shape added without a row, or a row
#     removed, changes one count and not the other. This is retro 25's shape, and it is the
#     only form that makes "every shape is classified" checkable rather than asserted.
#   * **Correspondence with the repository.** The table classifies by directory, and the
#     directories it names are real ones. So the spec row's directory is globbed for specs
#     and the epic row's for epics: a table naming `docs/specs/` reads perfectly, classifies
#     nothing, and no amount of grepping its prose would notice. This is the assertion with
#     an oracle outside the document.
#   * **Correspondence between two sites in the file.** The variables the mode resolution
#     says it stores are read out of that sentence and looked up in the variable table, so
#     renaming either side fails.
#
# The must-NOT is the retro-21 shape yet again: the rule is *"no flag selects the mode"* and
# the prose that states it has to write `--spec` to deny it. A file-wide ban would fail on
# the skill's own disclaimer. So the negative is scoped to the two sites where a flag would
# be operative rather than explanatory — the Input list's own argument items, and the mode
# resolution table's argument-shape column.
#
# --- What this suite does not test --------------------------------------------------------
#
# That a spec path actually launches a loop. Nothing here launches one, and spec mode's
# prompt does not exist yet (epic 45-03). What is checkable is that the mode is resolved from
# the path, that every shape has a mode, and that the directories the rule names exist.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

RALPH_SKILL="$SCRIPT_DIR/../../skills/ralph/SKILL.md"
REPO_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"

echo "Testing: ralph's spec-path input shape (Epic 45-02 Story 1)"
echo "==========================================================="

# --- Slices ------------------------------------------------------------------------------
#
# Named once, bounded once. An unbounded sed range that matches too much passes assertions on
# text belonging to a neighbouring section (retro 24).

INPUT_START='^## Input'
INPUT_END='^## Process'
TABLE_START='^\*\*Resolve the mode first'
TABLE_END='^If explicit epic paths were provided'

input_section() { sed -n "/$INPUT_START/,/$INPUT_END/p" "$1"; }
mode_table()    { sed -n "/$TABLE_START/,/$TABLE_END/p" "$1"; }

test_start "slice: the Input section spans its own section and no more"
assert_slice_bounded "$RALPH_SKILL" "$INPUT_START" "$INPUT_END" 6 16

test_start "slice: the mode resolution block spans its own block and no more"
assert_slice_bounded "$RALPH_SKILL" "$TABLE_START" "$TABLE_END" 5 12

test_start "control: the mode resolution block was actually found"
if [ -n "$(mode_table "$RALPH_SKILL")" ]; then
  test_pass
else
  test_fail "no mode resolution block in $RALPH_SKILL — every assertion below reads an empty slice"
fi

# --- The mode table's rows ---------------------------------------------------------------
#
# A data row is one whose mode cell is exactly `epic` or `spec`. The header's cell reads
# `{mode}` and the separator's reads `---`, so both fall out without being named; the
# variable table further down the section is excluded for the same reason, its third column
# being prose rather than a bare mode.

mode_rows() {
  mode_table "$1" | awk -F'|' '
    { c = $3; gsub(/^[ \t]+|[ \t]+$/, "", c) }
    c == "`epic`" || c == "`spec`" { print }'
}

# The two things a row says, read the same way everywhere. Both were open-coded twice, and
# the copies disagreed: one took only the first directory a row names and the other took all
# of them, which is how a two-directory row could be ambiguous to one reader and unambiguous
# to the next. One definition, so they cannot drift apart again.
row_dirs() { printf '%s\n' "$1" | awk -F'|' '{ print $2 }' | grep -oE 'docs/[a-z]+/'; }
row_mode() { printf '%s\n' "$1" | awk -F'|' '{ c = $3; gsub(/^[ \t]+|[ \t]+$/, "", c); print c }'; }

# The mode for a shape, looked up by a token in the shape column rather than by row number,
# so reordering the table does not silently reassign a mode.
mode_for() {
  local file="$1"
  export SHAPE="$2"
  mode_rows "$file" | awk -F'|' '
    index($2, ENVIRON["SHAPE"]) { c = $3; gsub(/^[ \t]+|[ \t]+$/, "", c); print c; exit }'
}

test_start "a path under docs/specifications/ resolves spec mode"
assert_equals '`spec`' "$(mode_for "$RALPH_SKILL" 'docs/specifications/')"

test_start "epic paths — and a range, in the same row — resolve epic mode"
assert_equals '`epic`' "$(mode_for "$RALPH_SKILL" 'docs/epics/')"

test_start "and that row is the one naming a range, not a second epic row"
assert_contains "$(mode_rows "$RALPH_SKILL" | grep -F 'docs/epics/')" "range"

test_start "no path at all resolves epic mode over every incomplete epic"
assert_equals '`epic`' "$(mode_for "$RALPH_SKILL" 'No path at all')"

test_start "and that row resolves to every incomplete epic, which is auto-discovery"
assert_contains "$(mode_rows "$RALPH_SKILL" | grep -F 'No path at all')" "every incomplete epic"

# Controls. Each mutates exactly one cell and re-runs the identical predicate: without them,
# the four assertions above prove only that the file contains some words in some cells.
sed 's/| `spec` | the incomplete epics/| `epic` | the incomplete epics/' \
  "$RALPH_SKILL" > "$TEST_TMPDIR/spec-row-flipped.md"

test_start "control: a spec row classified as epic mode is detected"
if [ "$(mode_for "$TEST_TMPDIR/spec-row-flipped.md" 'docs/specifications/')" = '`spec`' ]; then
  test_fail "the lookup returned spec for a row that now reads epic"
else
  test_pass
fi

test_start "control: that mutated copy still has the same number of rows"
assert_equals "$(mode_rows "$RALPH_SKILL" | grep -c .)" \
  "$(mode_rows "$TEST_TMPDIR/spec-row-flipped.md" | grep -c .)"

# --- Arithmetic: every shape the Input section documents has a mode ------------------------
#
# Counted from opposite ends. The Input list's *path* shapes are its numbered items whose
# label is not a flag — flags start their label with a backticked double dash — and the
# fourth shape is the fallback sentence, which is a shape without an argument. A fifth shape
# added to either end without the other fails this.

input_path_shapes() {
  input_section "$1" | grep -E '^[0-9]+\. \*\*' | grep -vE '^[0-9]+\. \*\*`--'
}

fallback_present() {
  input_section "$1" | grep -cF 'If no path of any kind is provided, auto-discover all incomplete epics'
}

expected_modes() {
  echo $(( $(input_path_shapes "$1" | grep -c .) + $(fallback_present "$1") ))
}

test_start "every argument shape the Input section documents has a row in the mode table"
assert_equals "$(expected_modes "$RALPH_SKILL")" "$(mode_rows "$RALPH_SKILL" | grep -c .)"

test_start "control: both sides of that comparison are non-zero"
if [ "$(expected_modes "$RALPH_SKILL")" -gt 0 ] && [ "$(mode_rows "$RALPH_SKILL" | grep -c .)" -gt 0 ]; then
  test_pass
else
  test_fail "counted $(expected_modes "$RALPH_SKILL") shapes against $(mode_rows "$RALPH_SKILL" | grep -c .) rows"
fi

# A fifth input shape with no row in the table — the drift the arithmetic exists to catch.
awk '/^5\. \*\*`--dry-run`\*\*/ { print; print "6. **A brief path** — a single path under `docs/briefs/`."; next } { print }' \
  "$RALPH_SKILL" > "$TEST_TMPDIR/fifth-shape.md"

test_start "control: an input shape added without a mode row is detected"
if [ "$(expected_modes "$TEST_TMPDIR/fifth-shape.md")" = "$(mode_rows "$TEST_TMPDIR/fifth-shape.md" | grep -c .)" ]; then
  test_fail "the counts still agree after a shape was added with no row"
else
  test_pass
fi

test_start "control: that mutated copy really gained a shape"
assert_equals "$(( $(expected_modes "$RALPH_SKILL") + 1 ))" "$(expected_modes "$TEST_TMPDIR/fifth-shape.md")"

# --- Correspondence with the repository: the directories the rule names are real ------------
#
# The classification is *"which directory does the path point into"*, so a table naming a
# directory that holds nothing classifies nothing — and reads perfectly while doing it. This
# is the one assertion here whose oracle is outside the document.

dir_named_by() {
  local file="$1" want="$2" row
  while IFS= read -r row; do
    [ "$(row_mode "$row")" = "$want" ] || continue
    [ -n "$(row_dirs "$row")" ] || continue
    row_dirs "$row" | head -1
    return
  done < <(mode_rows "$file")
}

SPEC_DIR=$(dir_named_by "$RALPH_SKILL" '`spec`')
EPIC_DIR=$(dir_named_by "$RALPH_SKILL" '`epic`')

test_start "control: a directory was extracted from each of the two path rows"
if [ -n "$SPEC_DIR" ] && [ -n "$EPIC_DIR" ]; then
  test_pass
else
  test_fail "extracted spec='$SPEC_DIR' epic='$EPIC_DIR' — an empty one globs the whole repo"
fi

test_start "the directory the spec row names is where this repo's specs live"
assert_contains "$(ls "$REPO_ROOT/$SPEC_DIR" 2>/dev/null | grep -- '-spec-')" "-spec-"

test_start "the directory the epic row names is where this repo's epics live"
assert_contains "$(ls "$REPO_ROOT/$EPIC_DIR" 2>/dev/null | grep -- '-epic-')" "-epic-"

test_start "and the two rows name different directories, so the rule discriminates"
if [ "$SPEC_DIR" != "$EPIC_DIR" ]; then
  test_pass
else
  test_fail "both rows name $SPEC_DIR — every path classifies the same way"
fi

# Scoped to the table row. A file-wide substitution would also rewrite the Input list and the
# prose, so a passing control would not say which of them the predicate had read.
sed 's@^| A single path under `docs/specifications/` @| A single path under `docs/specs/` @' \
  "$RALPH_SKILL" > "$TEST_TMPDIR/bad-dir.md"

test_start "control: a table naming a directory that does not exist is detected"
BAD_DIR=$(dir_named_by "$TEST_TMPDIR/bad-dir.md" '`spec`')
if [ -d "$REPO_ROOT/$BAD_DIR" ]; then
  test_fail "the mutated table names $BAD_DIR, which exists — the control proves nothing"
else
  test_pass
fi

# --- Correspondence between two sites: what the resolution stores, the table lists ---------

stored_variables() {
  mode_table "$1" | grep -F 'Store the result as' | grep -oE '\{[a-z_]+\}'
}

VAR_TABLE_START='^| Variable | Value |'
VAR_TABLE_END='^$'

variable_table() { sed -n "/$VAR_TABLE_START/,/$VAR_TABLE_END/p" "$1"; }

test_start "slice: the variable table spans its own table and no more"
assert_slice_bounded "$RALPH_SKILL" "$VAR_TABLE_START" "$VAR_TABLE_END" 4 10

test_start "control: the storage sentence names at least two variables"
if [ "$(stored_variables "$RALPH_SKILL" | grep -c .)" -ge 2 ]; then
  test_pass
else
  test_fail "found $(stored_variables "$RALPH_SKILL" | grep -c .) — the loop below would assert nothing"
fi

for var in $(stored_variables "$RALPH_SKILL"); do
  test_start "the variable table lists $var, which mode resolution says it stores"
  assert_contains "$(variable_table "$RALPH_SKILL")" "\`$var\`"
done

test_start "control: a variable stored but not listed is detected"
sed 's/^| `{spec_path}` |/| `{spec_target}` |/' "$RALPH_SKILL" > "$TEST_TMPDIR/var-renamed.md"
MISSING=0
for var in $(stored_variables "$TEST_TMPDIR/var-renamed.md"); do
  variable_table "$TEST_TMPDIR/var-renamed.md" | grep -qF "\`$var\`" || MISSING=1
done
assert_equals "1" "$MISSING"

# --- The must-NOT: no flag selects the mode ------------------------------------------------
#
# Scoped, not file-wide. The skill has to write `--spec` in order to say there is no `--spec`
# flag, so a ban on the token bans the caution as well (retro 21). The two sites where the
# token would be operative rather than explanatory are the Input list's own argument items
# and the mode table's argument-shape column.

# One flag per Input item, taken from the item's own bold label — not one per mention. The
# `--story-filter` item names itself three times in its own examples, so a match-every-
# occurrence extraction counted five flags where three are documented, and every count built
# on it agreed with itself while being wrong. The label is the definition; the examples are
# prose. A trailing argument in the label (`--max-iterations N`) is not part of the name.
input_flags() {
  input_section "$1" | sed -n 's/^[0-9]*\. \*\*`\(--[a-z-]*\).*/\1/p'
}

test_start "the Input section states the mode comes from the path rather than a flag"
assert_contains "$(input_section "$RALPH_SKILL")" "The mode comes from the path, not from a flag"

test_start "and says so of a --spec flag by name, so the denial is findable"
assert_contains "$(input_section "$RALPH_SKILL")" 'There is no `--spec` flag'

test_start "no argument item in the Input list selects a mode"
assert_empty "$(input_flags "$RALPH_SKILL" | grep -E '^--(spec|epic|mode)$')"

test_start "control: the flag list is non-empty, so the filter above is filtering something"
if [ "$(input_flags "$RALPH_SKILL" | grep -c .)" -ge 3 ]; then
  test_pass
else
  test_fail "found $(input_flags "$RALPH_SKILL" | grep -c .) flag items — expected the three that predate spec mode"
fi

test_start "the mode table's argument-shape column names no flag"
assert_empty "$(mode_rows "$RALPH_SKILL" | awk -F'|' '{ print $2 }' | grep -oE '\-\-[a-z-]+')"

awk '/^5\. \*\*`--dry-run`\*\*/ { print "5. **`--spec PATH`** — select spec mode explicitly."; print; next } { print }' \
  "$RALPH_SKILL" > "$TEST_TMPDIR/mode-flag.md"

test_start "control: a mode-selecting flag added to the Input list is detected"
if [ -n "$(input_flags "$TEST_TMPDIR/mode-flag.md" | grep -E '^--(spec|epic|mode)$')" ]; then
  test_pass
else
  test_fail "the scoped negative did not see a --spec argument item"
fi

test_start "control: the unmutated file and the mutated one differ only in that item"
assert_equals "$(( $(input_flags "$RALPH_SKILL" | grep -c .) + 1 ))" \
  "$(input_flags "$TEST_TMPDIR/mode-flag.md" | grep -c .)"

# --- The fallback is not reachable by a spec path -------------------------------------------
#
# The old wording — "If no epic paths are provided" — is true of a spec path, because a spec
# path is not an epic path. That sentence sent spec mode to auto-discovery, which is FR2's
# failure mode arrived at through FR1. The rewrite is what makes the mode table reachable.

test_start "the fallback is phrased against any path, not against epic paths"
assert_contains "$(input_section "$RALPH_SKILL")" "If no path of any kind is provided"

test_start "and the old epic-path phrasing is gone from the Input section"
assert_not_contains "$(input_section "$RALPH_SKILL")" "If no epic paths are provided"

test_start "the Input section says the test is the directory, not the presence of epic paths"
assert_contains "$(input_section "$RALPH_SKILL")" "which directory does it point into"

# --- Story 2 (FR2): the shapes that predate spec mode still resolve as documented ----------
#
# Epic 44-03's Story 2 found that asserting "nothing changed" across a whole documented
# surface is mostly regression netting, and that the assertion worth having is the one place
# the change actually couples to the existing shapes. Here that place is the classification
# itself: before spec mode there was no mode at all, so **epic mode is the behaviour every
# existing invocation already had**, and the way Story 1 could have broken one is by making
# its path classify as something else — or as two things.
#
# So this section runs the rule rather than reading it. `classify` is built *from* the mode
# table, so a change to the table changes what it does, and it is fed real paths out of this
# repository rather than typed literals.

# Every directory the row names, not just its first: a row naming two would otherwise be
# classified by one of them and the other would never be seen — which is exactly the
# ambiguity the control at the end of this section builds. One matching row contributes one
# mode, so the count of lines is the count of rows that claim the path.
classify() {
  local file="$1" path="$2" row dir
  while IFS= read -r row; do
    for dir in $(row_dirs "$row"); do
      case "$path" in
        "$dir"*) row_mode "$row"; break ;;
      esac
    done
  done < <(mode_rows "$file")
}

REAL_EPIC="docs/epics/$(ls "$REPO_ROOT/docs/epics" | grep -- '-epic-' | head -1)"
REAL_SPEC="docs/specifications/$(ls "$REPO_ROOT/docs/specifications" | grep -- '-spec-' | head -1)"

test_start "control: a real epic path and a real spec path were found to classify"
if [ -f "$REPO_ROOT/$REAL_EPIC" ] && [ -f "$REPO_ROOT/$REAL_SPEC" ]; then
  test_pass
else
  test_fail "epic='$REAL_EPIC' spec='$REAL_SPEC' — one of them is not a file"
fi

test_start "a real epic path still classifies, and classifies to exactly one mode"
assert_equals "1" "$(classify "$RALPH_SKILL" "$REAL_EPIC" | grep -c .)"

test_start "and that mode is epic — the behaviour every existing invocation already had"
assert_equals '`epic`' "$(classify "$RALPH_SKILL" "$REAL_EPIC")"

test_start "a real spec path classifies to exactly one mode"
assert_equals "1" "$(classify "$RALPH_SKILL" "$REAL_SPEC" | grep -c .)"

test_start "and that mode is spec, so the two shapes are not both epic mode"
assert_equals '`spec`' "$(classify "$RALPH_SKILL" "$REAL_SPEC")"

# The range shape, read out of the skill rather than re-typed: the expansion the skill
# documents must still land in the epic-mode row, or a range stops meaning what it meant.
RANGE_EXPANSION=$(sed -n 's/.*For range-style references.*expand to matching files: `\([^`]*\)`.*/\1/p' "$RALPH_SKILL")

test_start "control: the documented range expansion was extracted from the skill"
if [ -n "$RANGE_EXPANSION" ]; then
  test_pass
else
  test_fail "no range expansion found — the assertion below would classify an empty string"
fi

test_start "a range still expands to a path the mode table classifies as epic mode"
assert_equals '`epic`' "$(classify "$RALPH_SKILL" "$RANGE_EXPANSION")"

# The fourth shape has no path, so no row matches it — the fallback sentence is what routes
# it. That is the division of labour Story 1 introduced, and FR2's criterion is about this
# half of it.
test_start "no argument matches no directory row, so the fallback is what handles it"
assert_equals "0" "$(classify "$RALPH_SKILL" "" | grep -c .)"

test_start "and the fallback still routes it to auto-discovery over all incomplete epics"
assert_contains "$(input_section "$RALPH_SKILL")" \
  "If no path of any kind is provided, auto-discover all incomplete epics"

# Auto-discovery's own procedure is untouched by Story 1: same glob, same status filter, same
# stop condition, same confirmation. Asserted here as the four steps rather than as prose,
# because "unchanged" is the claim and the steps are what would change.
# One definition, so the real file and every mutated fixture below are sliced identically.
# The two-sided line bound on this range lives in `test-ralph-promise.sh`, which owns the FR9
# regression net over the same section; repeating the numbers here would give them somewhere
# to drift apart. What is guarded here instead is that the range found both of its ends.
discovery_slice() { sed -n '/^#### 1a\. Epic Discovery/,/^#### 1b\./p' "$1"; }

DISCOVERY_SLICE=$(discovery_slice "$RALPH_SKILL")

test_start "control: the discovery slice starts and ends where it claims to"
if printf '%s\n' "$DISCOVERY_SLICE" | head -1 | grep -q '^#### 1a\. Epic Discovery' &&
   printf '%s\n' "$DISCOVERY_SLICE" | tail -1 | grep -q '^#### 1b\.'; then
  test_pass
else
  test_fail "slice runs from '$(printf '%s\n' "$DISCOVERY_SLICE" | head -1)' to '$(printf '%s\n' "$DISCOVERY_SLICE" | tail -1)'"
fi
DISCOVERY_STEPS=$(printf '%s\n' "$DISCOVERY_SLICE" | grep -E '^[0-9]+\. ')
# Steps carry sub-bullets now that step 3 branches on mode, so content lives one level in.
DISCOVERY_BODY=$(printf '%s\n' "$DISCOVERY_SLICE" | grep -E '^[0-9]+\. |^   - ')

test_start "auto-discovery still runs its four documented steps"
assert_equals "4" "$(printf '%s\n' "$DISCOVERY_STEPS" | grep -c .)"

for step in 'docs/epics/\*-epic-\*\.md' 'not `Complete`/`Done`' 'confirm with AskUserQuestion'; do
  test_start "auto-discovery still does: $(printf '%s' "$step" | sed 's/\\//g')"
  if printf '%s\n' "$DISCOVERY_BODY" | grep -qE -- "$step"; then
    test_pass
  else
    test_fail "no auto-discovery step matched /$step/"
  fi
done

# The stop message is asserted where it has to survive rather than anywhere in the list. Once
# step 3 branches, "the message is still somewhere in step 3" is satisfied by a spec-mode
# branch that emits it — which is precisely what Story 3's must-NOT forbids. The branch is
# the scope, so the FR2 net and the FR3 must-NOT read the same two bullets from opposite
# sides and cannot both be satisfied by one wrong edit.
epic_branch() { printf '%s\n' "$1" | grep -E '^   - \*\*Epic mode\*\*'; }
spec_branch() { printf '%s\n' "$1" | grep -E '^   - \*\*Spec mode\*\*'; }

test_start "control: step 3 has both branches, one line each"
if [ "$(epic_branch "$DISCOVERY_SLICE" | grep -c .)" = "1" ] &&
   [ "$(spec_branch "$DISCOVERY_SLICE" | grep -c .)" = "1" ]; then
  test_pass
else
  test_fail "epic branch: $(epic_branch "$DISCOVERY_SLICE" | grep -c .), spec branch: $(spec_branch "$DISCOVERY_SLICE" | grep -c .)"
fi

test_start "the stop message survives verbatim in the epic-mode branch"
assert_contains "$(epic_branch "$DISCOVERY_SLICE")" "No incomplete epics found. Nothing to run."

# The control that makes the unambiguity assertions mean something: a table whose epic row
# also names the spec directory. Every classification above still passes on such a table —
# except the counts, which is the point of asserting exactly one match rather than the mode
# alone. This is the concrete shape of a mode-blind edit.
sed 's@^| One or more paths under `docs/epics/`, or a range @| One or more paths under `docs/epics/` or `docs/specifications/`, or a range @' \
  "$RALPH_SKILL" > "$TEST_TMPDIR/ambiguous.md"

test_start "control: the ambiguous fixture really names two directories in one row"
assert_contains "$(mode_rows "$TEST_TMPDIR/ambiguous.md" | grep -F 'or a range')" "docs/specifications/"

test_start "control: a spec path matching two rows is detected as ambiguous"
if [ "$(classify "$TEST_TMPDIR/ambiguous.md" "$REAL_SPEC" | grep -c .)" -gt 1 ]; then
  test_pass
else
  test_fail "the spec path still matched one row on a table that classifies it twice"
fi

test_start "control: and the epic path is unaffected by that mutation, so it is scoped"
assert_equals "1" "$(classify "$TEST_TMPDIR/ambiguous.md" "$REAL_EPIC" | grep -c .)"

# --- Story 2's must-NOT as arithmetic, not judgement ---------------------------------------
#
# *"must NOT change the behaviour of any existing documented invocation"* is unfalsifiable as
# written — "behaviour" is unbounded. Retro 22's remedy is to make it countable: enumerate the
# invocations the Input section documents, and require each to still have a site that acts on
# it. A flag that keeps its Input entry while losing the step that reads it is a documented
# invocation whose behaviour is gone, and that is the failure this counts.
#
# The two ends are derived, not listed here: the flags come out of the Input section, and the
# sites are found by the rule the skill actually uses to reach a flag — either the flag's own
# name, or the placeholder Step 2 interpolates for it, whose name is the flag's with the
# dashes turned to underscores.

outside_input() { sed "/$INPUT_START/,/$INPUT_END/d" "$1"; }

has_behaviour_site() {
  local file="$1" flag="$2" base
  base=$(printf '%s' "$flag" | sed 's/^--//; s/-/_/g')
  outside_input "$file" | grep -qF -- "$flag" && return 0
  outside_input "$file" | grep -qE "\{${base}[a-z_]*\}" && return 0
  return 1
}

flags_with_sites() {
  local file="$1" flag n=0
  for flag in $(input_flags "$file"); do
    has_behaviour_site "$file" "$flag" && n=$((n + 1))
  done
  printf '%s\n' "$n"
}

for flag in $(input_flags "$RALPH_SKILL"); do
  test_start "$flag still has a site outside the Input section that acts on it"
  if has_behaviour_site "$RALPH_SKILL" "$flag"; then
    test_pass
  else
    test_fail "$flag is documented as an argument and read nowhere"
  fi
done

test_start "every documented flag has a behaviour site — counted from both ends"
assert_equals "$(input_flags "$RALPH_SKILL" | grep -c .)" "$(flags_with_sites "$RALPH_SKILL")"

awk '/^5\. \*\*`--dry-run`\*\*/ { print; print "6. **`--verbose`** — print more detail."; next } { print }' \
  "$RALPH_SKILL" > "$TEST_TMPDIR/orphan-flag.md"

test_start "control: a documented flag with no behaviour site is detected"
if [ "$(input_flags "$TEST_TMPDIR/orphan-flag.md" | grep -c .)" = "$(flags_with_sites "$TEST_TMPDIR/orphan-flag.md")" ]; then
  test_fail "the counts still agree after a flag was documented but never read"
else
  test_pass
fi

test_start "control: that mutated copy really gained a flag"
assert_equals "$(( $(input_flags "$RALPH_SKILL" | grep -c .) + 1 ))" \
  "$(input_flags "$TEST_TMPDIR/orphan-flag.md" | grep -c .)"

# The one documented behaviour carrying a *value*, so it is the one where the two sites can
# disagree silently: the Input section states the default and Step 2 states what the
# placeholder resolves to. Both numbers are read out of the file and compared to each other,
# rather than either being pinned to a literal here.
INPUT_DEFAULT=$(input_section "$RALPH_SKILL" | sed -n 's/.*`--max-iterations N`.*default: \([0-9]*\)).*/\1/p')
STEP2_DEFAULT=$(outside_input "$RALPH_SKILL" | sed -n 's/.*{max_iterations}.*default (\([0-9]*\)).*/\1/p' | head -1)

test_start "control: a default was extracted from each of the two sites"
if [ -n "$INPUT_DEFAULT" ] && [ -n "$STEP2_DEFAULT" ]; then
  test_pass
else
  test_fail "input='$INPUT_DEFAULT' step2='$STEP2_DEFAULT' — an empty one compares against nothing"
fi

test_start "the iteration default the Input section documents is the one Step 2 applies"
assert_equals "$INPUT_DEFAULT" "$STEP2_DEFAULT"

test_start "control: the two sites are detected when they disagree"
sed 's/(default: 50)/(default: 25)/' "$RALPH_SKILL" > "$TEST_TMPDIR/split-default.md"
BAD_INPUT=$(input_section "$TEST_TMPDIR/split-default.md" | sed -n 's/.*`--max-iterations N`.*default: \([0-9]*\)).*/\1/p')
if [ "$BAD_INPUT" = "$STEP2_DEFAULT" ]; then
  test_fail "the mutated Input section still states $BAD_INPUT — the control changed nothing"
else
  test_pass
fi

# `--dry-run`'s documented behaviour is a stop, and the step that stops is the one it has to
# survive in. Named because it is the only flag whose site is a control-flow instruction
# rather than an interpolation.
test_start "--dry-run still stops the skill before the launch confirmation"
assert_contains "$(sed -n '/^#### 3b\./,/^#### 3c\./p' "$RALPH_SKILL")" \
  'If `--dry-run` was specified, stop here.'

# --- Story 3 (FR3): zero epics is spec mode's starting state, not a failure ----------------
#
# The must-NOT quotes the very message it forbids — *"No incomplete epics found. Nothing to
# run."* — and the epic-mode branch two lines above has to carry that message verbatim, or
# FR2 breaks. So the negative is scoped to the **spec-mode bullet**, where the string would be
# an instruction; a step-wide or file-wide ban would fail on the rule's own other half. Retro
# 21, which is the disposition this epic recorded before any of it was written.

SPEC_BULLET=$(spec_branch "$DISCOVERY_SLICE")
EPIC_BULLET=$(epic_branch "$DISCOVERY_SLICE")

test_start "control: both bullets were extracted, so the two negatives below differ"
if [ -n "$SPEC_BULLET" ] && [ -n "$EPIC_BULLET" ] && [ "$SPEC_BULLET" != "$EPIC_BULLET" ]; then
  test_pass
else
  test_fail "spec='$SPEC_BULLET' epic='$EPIC_BULLET'"
fi

test_start "the spec-mode branch does not emit the stop message"
assert_not_contains "$SPEC_BULLET" "No incomplete epics found. Nothing to run."

test_start "and the epic-mode branch does — the same string, judged by where it sits"
assert_contains "$EPIC_BULLET" "No incomplete epics found. Nothing to run."

test_start "the spec-mode branch says not to stop"
assert_contains "$SPEC_BULLET" "do **not** stop"

test_start "and says pre-flight continues rather than ending there"
assert_contains "$SPEC_BULLET" "continue pre-flight"

test_start "and names what fills the empty list, so proceeding is a decision not an omission"
assert_contains "$SPEC_BULLET" "phase 1"

# The must-NOT phrased as a property of the whole step rather than of one bullet: the message
# appears exactly once, and in the branch that is not spec mode. A copy added to the spec
# branch raises the count; moving it there leaves the count at one but empties the epic
# branch, which the assertion above catches. Together they pin it to one place.
test_start "the stop message appears exactly once in the discovery step"
assert_equals "1" "$(printf '%s\n' "$DISCOVERY_SLICE" | grep -cF 'No incomplete epics found. Nothing to run.')"

# Controls: the identical predicates over a copy whose spec branch emits the message. This is
# the mode-blind edit the must-NOT exists to refuse, and it is the shape a careless "keep the
# stop everywhere" change takes.
sed 's@^   - \*\*Spec mode\*\* — do \*\*not\*\* stop@   - **Spec mode** — report "No incomplete epics found. Nothing to run." and stop@' \
  "$RALPH_SKILL" > "$TEST_TMPDIR/spec-stops.md"
LEAKED=$(spec_branch "$(discovery_slice "$TEST_TMPDIR/spec-stops.md")")

test_start "control: the mutated copy really put the message in the spec branch"
assert_contains "$LEAKED" "No incomplete epics found. Nothing to run."

test_start "control: and the scoped negative would have caught it"
if printf '%s\n' "$LEAKED" | grep -qF 'No incomplete epics found. Nothing to run.'; then
  test_pass
else
  test_fail "the spec-branch extraction did not see the message the mutation put there"
fi

test_start "control: the count check also detects that copy, from the other side"
if [ "$(discovery_slice "$TEST_TMPDIR/spec-stops.md" |
        grep -cF 'No incomplete epics found. Nothing to run.')" = "1" ]; then
  test_fail "the message still appears once after being added to a second branch"
else
  test_pass
fi

# The other half of FR3: an empty resolved list has to be a *valid* state for the rest of
# pre-flight, not merely an unblocked one. Step 1a already says spec mode's list may be empty;
# this asserts the two statements agree rather than each being locally true.
test_start "the resolved-list paragraph agrees that spec mode's list may be empty"
assert_contains "$(sed -n '/^\*\*The three epic-mode shapes resolve/,/^$/p' "$RALPH_SKILL")" \
  "at iteration 1 is normally none"

# --- Story 4: the four shapes against the two disk states ----------------------------------
#
# Stories 1-3 each assert one shape's behaviour. The failure this epic is most exposed to is
# an edit correct for the shape it was written for and wrong for one of the other three —
# Story 3's change to what zero epics *means* applies to exactly one shape, and nothing in
# Stories 1-3 says which. So this section enumerates all eight combinations and derives its
# two ends independently: the shape count comes out of the Input section, and each cell's
# outcome comes out of the clause in Step 1a that fires for it. A fifth shape raises the
# expected cell count and fails here until it is given outcomes.

documented_shapes() {
  local n
  n=$(input_path_shapes "$1" | grep -c .)
  # The range is an alternative form inside the epic-paths item rather than an item of its
  # own, so it is counted where it is written rather than assumed to be there.
  n=$((n + $(input_path_shapes "$1" | grep -c 'or a range')))
  n=$((n + $(fallback_present "$1")))
  printf '%s\n' "$n"
}

test_start "the Input section documents four argument shapes"
assert_equals "4" "$(documented_shapes "$RALPH_SKILL")"

# The outcome each cell reaches, named by the clause that produces it. Every branch reads the
# document; none returns a literal that is not also a claim about the file.
outcome_for() {
  local file="$1" shape="$2" disk="$3" slice
  slice=$(discovery_slice "$file")
  case "$shape:$disk" in
    explicit:*|range:*)
      printf '%s\n' "$slice" | grep -qF 'resolve them (expand globs)' && echo resolve ;;
    spec:present)
      printf '%s\n' "$slice" | grep -qF 'keep only the epics whose `**Source spec**` field names' && echo filter ;;
    spec:empty)
      # Reports whichever clause the spec branch actually carries, not only the right one —
      # a predicate that recognised just the correct clause would report a wrong branch as
      # *undocumented*, and the arithmetic below needs to see it as documented-and-wrong.
      if spec_branch "$slice" | grep -qF 'continue pre-flight'; then echo continue
      elif spec_branch "$slice" | grep -qF 'No incomplete epics found. Nothing to run.'; then echo stop
      fi ;;
    none:present)
      printf '%s\n' "$slice" | grep -qF 'Present the discovered epics and confirm with AskUserQuestion' && echo present ;;
    none:empty)
      epic_branch "$slice" | grep -qF 'No incomplete epics found. Nothing to run.' && echo stop ;;
  esac
}

SHAPES="explicit range spec none"
DISK_STATES="present empty"

# Both ends: cells enumerated by the loop, expected count derived from the document.
CELLS=0
for shape in $SHAPES; do
  for disk in $DISK_STATES; do
    CELLS=$((CELLS + 1))
  done
done

test_start "the matrix enumerates one cell per shape per disk state"
assert_equals "$(( $(documented_shapes "$RALPH_SKILL") * 2 ))" "$CELLS"

for shape in $SHAPES; do
  for disk in $DISK_STATES; do
    test_start "$shape with $disk epics reaches a documented pre-flight outcome"
    if [ -n "$(outcome_for "$RALPH_SKILL" "$shape" "$disk")" ]; then
      test_pass
    else
      test_fail "no clause in Step 1a documents what $shape does with $disk epics"
    fi
  done
done

# The cross-story claim no single story's criteria reach: the disk state changes the outcome
# for **exactly two** of the four shapes. Story 3 changed what zero epics means, and this is
# where "for which shapes" is asserted rather than assumed. A mode-blind edit — the failure
# this epic's Notes name — moves this number.
# Both matrix counts are the same sweep over the four shapes with a different question asked
# of each, so they are one loop and two predicates. Written apart they drifted: the first was
# reached for and did not discriminate, and the difference between them is the finding.
count_shapes() {
  local file="$1" pred="$2" shape n=0
  for shape in $SHAPES; do
    "$pred" "$file" "$shape" && n=$((n + 1))
  done
  printf '%s\n' "$n"
}

is_disk_sensitive() { [ "$(outcome_for "$1" "$2" present)" != "$(outcome_for "$1" "$2" empty)" ]; }
disk_sensitive()    { count_shapes "$1" is_disk_sensitive; }

test_start "the disk state changes the outcome for exactly two of the four shapes"
assert_equals "2" "$(disk_sensitive "$RALPH_SKILL")"

test_start "and those two are the shapes that discover rather than name their epics"
if [ "$(outcome_for "$RALPH_SKILL" spec present)" != "$(outcome_for "$RALPH_SKILL" spec empty)" ] &&
   [ "$(outcome_for "$RALPH_SKILL" none present)" != "$(outcome_for "$RALPH_SKILL" none empty)" ] &&
   [ "$(outcome_for "$RALPH_SKILL" explicit present)" = "$(outcome_for "$RALPH_SKILL" explicit empty)" ] &&
   [ "$(outcome_for "$RALPH_SKILL" range present)" = "$(outcome_for "$RALPH_SKILL" range empty)" ]; then
  test_pass
else
  test_fail "disk sensitivity landed on the wrong shapes"
fi

# The measurement that discriminates a mode-blind edit. Disk-sensitivity alone does not: a
# spec branch that stops is still *different* from a spec branch with epics present, so that
# count stays at 2 whether the branch is right or wrong. What changes is **how many shapes
# stop on an empty disk** — one, and it is auto-discovery. That is Story 3's change stated as
# a property of the whole matrix rather than of the branch it edited.
stops_on_empty()  { [ "$(outcome_for "$1" "$2" empty)" = "stop" ]; }
stops_when_empty() { count_shapes "$1" stops_on_empty; }

test_start "exactly one shape stops on an empty disk"
assert_equals "1" "$(stops_when_empty "$RALPH_SKILL")"

test_start "and it is the no-path shape, not the spec path"
if [ "$(outcome_for "$RALPH_SKILL" none empty)" = "stop" ] &&
   [ "$(outcome_for "$RALPH_SKILL" spec empty)" != "stop" ]; then
  test_pass
else
  test_fail "none:empty=$(outcome_for "$RALPH_SKILL" none empty) spec:empty=$(outcome_for "$RALPH_SKILL" spec empty)"
fi

# The mode-blind edit made concrete: a stop that fires regardless of mode. Every cell still
# has a documented outcome under it, and the disk-sensitivity count still reads 2 — which is
# exactly why neither of those is the assertion that catches it.
sed 's@^   - \*\*Spec mode\*\* — do \*\*not\*\* stop.*@   - **Spec mode** — report "No incomplete epics found. Nothing to run." and stop.@' \
  "$RALPH_SKILL" > "$TEST_TMPDIR/mode-blind.md"

test_start "control: every cell of the mode-blind copy still has a documented outcome"
INTACT=1
for shape in $SHAPES; do
  for disk in $DISK_STATES; do
    [ -n "$(outcome_for "$TEST_TMPDIR/mode-blind.md" "$shape" "$disk")" ] || INTACT=0
  done
done
assert_equals "1" "$INTACT"

test_start "control: and its disk-sensitivity count is unchanged, so that is not the oracle"
assert_equals "2" "$(disk_sensitive "$TEST_TMPDIR/mode-blind.md")"

test_start "control: the stop count is what detects it"
if [ "$(stops_when_empty "$TEST_TMPDIR/mode-blind.md")" = "1" ]; then
  test_fail "a mode-blind stop left the count at 1 — two shapes now stop on an empty disk"
else
  test_pass
fi

test_summary
