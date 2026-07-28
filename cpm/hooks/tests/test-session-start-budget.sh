#!/bin/bash
# test-session-start-budget.sh — the SessionStart payload stays small enough to arrive.
#
# --- The failure this covers --------------------------------------------------------
#
# The harness inlines only the first 2 KB of an oversized hook payload and persists the
# rest to a file nothing reads. Both SessionStart hooks used to `cat` skill-conventions.md
# (45 KB) plus every current-session progress file plus, on the compact path, the compact
# summary. A real session reached 86,748 bytes, of which what arrived was: the session id,
# the user name, `## Roster Loading`, and half of `## Perspectives`.
#
# Nothing failed. Fifteen of seventeen conventions sections, the active-ralph-loop warning
# and the resumed session's own state were simply not there, and no output said so. A
# session ran without the shared conventions it believed it had.
#
# So the payload's size is a correctness property, and this suite is where it is enforced.
#
# --- Which assertions are oracles ---------------------------------------------------
#
# **The independence check is, and it is the real invariant.** A byte ceiling only catches
# growth once it crosses a number someone chose. The property that actually matters is that
# the payload does not grow with the documents it describes — so the same fixture is run
# twice, once with a 200-byte progress file and once with a 60 KB one, and the two outputs
# must be byte-identical. Restoring a `cat` anywhere in either hook fails this immediately,
# at any file size, without waiting for a threshold. The ceiling below is the backstop.
#
# **The budget is read out of session-start.sh, not spelled here.** Changing the constant
# is a deliberate act with one edit site; a copy in this file would let the two drift and
# the suite would then be asserting a number the hook had abandoned.
#
# **The core-section check is a round trip.** Each name in the hook's CORE_SECTIONS is
# looked up in skill-conventions.md and its heading must exist — a typo emits nothing at
# all, silently, which is the same class of failure as the truncation itself. It is paired
# with a control that the extracted text is non-empty, because a section that exists and a
# section that was actually emitted are different claims.

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

STARTUP_HOOK="$SCRIPT_DIR/../session-start.sh"
COMPACT_HOOK="$SCRIPT_DIR/../session-start-compact.sh"
CORE_LIB="$SCRIPT_DIR/../lib/conventions-core.sh"
CONVENTIONS="$SCRIPT_DIR/../../shared/skill-conventions.md"

echo "Testing: the SessionStart payload stays under budget and independent of document size"
echo "===================================================================================="

# --- The numbers the hook declares, read from the hook -------------------------------

BUDGET=$(grep -m1 '^CPM_PAYLOAD_BUDGET=' "$STARTUP_HOOK" | cut -d= -f2)
LIST_CAP=$(grep -m1 '^CPM_LIST_CAP=' "$STARTUP_HOOK" | cut -d= -f2)

# Not CPM's numbers. The documented cap on hook stdout, and the preview size the harness
# falls back to when that cap is breached — see anthropics/claude-code#44086 and #55750,
# and docs/maintenance/README.md. Spelled here because they are external constants that no
# file in this repo owns; if either changes upstream, both sites change together.
HARNESS_LIMIT=10000
HARNESS_PREVIEW=2000

test_start "control: a payload budget was read out of session-start.sh"
if [ -n "$BUDGET" ] && [ "$BUDGET" -gt 0 ] 2>/dev/null; then
  test_pass
else
  test_fail "no CPM_PAYLOAD_BUDGET found in $STARTUP_HOOK — the ceiling below would be vacuous"
fi

# The budget is CPM's choice; the cap is not. Checking the payload against both is not
# enough on its own — a budget raised above the cap passes every payload check right up
# until the day a payload uses the room it was given. So the budget itself is constrained
# here, which is the only place the relationship between the two numbers is visible.
test_start "the declared budget is itself below the harness's hard limit"
if [ "$BUDGET" -le "$HARNESS_LIMIT" ] 2>/dev/null; then
  test_pass
else
  test_fail "CPM_PAYLOAD_BUDGET=$BUDGET exceeds the ${HARNESS_LIMIT}-character cap, so staying inside the budget would not keep a payload inside the limit"
fi

# The cap has to be a number, and it has to be a bound. A cap set above any plausible
# number of leftover progress files is a cap in name only — it would list every file and
# the payload would grow with the count again. The upper limit here is also what keeps the
# fixture below finite: it sizes itself from the cap, so an unbounded cap would otherwise
# ask for an unbounded number of files.
LIST_CAP_MAX=50

test_start "control: a list cap was read out of session-start.sh, and is an actual bound"
if [ -n "$LIST_CAP" ] && [ "$LIST_CAP" -gt 0 ] 2>/dev/null && [ "$LIST_CAP" -le "$LIST_CAP_MAX" ]; then
  test_pass
else
  test_fail "CPM_LIST_CAP is '${LIST_CAP:-unset}' — expected 1..$LIST_CAP_MAX; a cap above that does not bound anything"
  LIST_CAP=$LIST_CAP_MAX  # keep the fixture finite so the rest of the suite still reports
fi

# --- Fixture -------------------------------------------------------------------------
#
# Deliberately hostile, and hostile along every axis the payload could grow on at once:
# an active ralph loop, a current-session progress file, a compact summary, and far more
# leftover other-session files than the cap lists. `body_bytes` sets how large the two
# document-shaped inputs are — that is the knob the independence check turns.

CUR_ID="budget-session"
STALE_TOTAL=$(( LIST_CAP * 4 ))
FRESH_TOTAL=$(( LIST_CAP * 2 ))

setup_fixture() {
  local body_bytes="$1"
  local project_dir="$TEST_TMPDIR/budget-$$-$RANDOM"
  mkdir -p "$project_dir/docs/plans" "$project_dir/.claude"
  local plans="$project_dir/docs/plans"

  printf 'iteration: 7\nmax_iterations: 40\ncompletion_promise: "the suite is green"\n' \
    > "$project_dir/.claude/ralph-loop.local.md"

  {
    printf '# CPM Session State\n\n**Skill**: cpm:epics\n**Phase**: Break into Stories\n\n'
    head -c "$body_bytes" /dev/zero | tr '\0' 'x'
    printf '\n'
  } > "$plans/.cpm-progress-${CUR_ID}.md"

  {
    printf '# Compact summary\n\n'
    head -c "$body_bytes" /dev/zero | tr '\0' 'x'
    printf '\n'
  } > "$plans/.cpm-compact-summary-${CUR_ID}.md"

  # Well over the cap on both other-session classifications — and deliberately a DIFFERENT
  # number of each. The two lists are separate code paths that emit the same sentence, so
  # equal counts would let either one satisfy an assertion meant for the other: the stale
  # list could stop reporting what it dropped and the fresh list's notice would cover for
  # it. Different totals make each notice name a number only its own path can produce.
  local i
  for i in $(seq 1 "$STALE_TOTAL"); do
    printf '# CPM Session State\n\n**Skill**: cpm:do\n**Phase**: Load Context\n' > "$plans/.cpm-progress-stale$i.md"
    touch -t 202001010000 "$plans/.cpm-progress-stale$i.md"
  done
  for i in $(seq 1 "$FRESH_TOTAL"); do
    printf '# CPM Session State\n\n**Skill**: cpm:spec\n**Phase**: Section 3\n' > "$plans/.cpm-progress-fresh$i.md"
  done

  echo "$project_dir"
}

run_hook() {
  local hook="$1" project_dir="$2" source="$3"
  echo "{\"session_id\":\"$CUR_ID\",\"source\":\"$source\"}" \
    | CLAUDE_PROJECT_DIR="$project_dir" CPM_USER_NAME="Tester" bash "$hook" 2>/dev/null
}

# --- The oracle: the payload does not grow with the documents ------------------------

SMALL=$(setup_fixture 200)
LARGE=$(setup_fixture 60000)

for pair in "startup:$STARTUP_HOOK" "compact:$COMPACT_HOOK"; do
  src="${pair%%:*}"; hook="${pair#*:}"
  small_out=$(run_hook "$hook" "$SMALL" "$src")
  large_out=$(run_hook "$hook" "$LARGE" "$src")
  # Characters, not bytes: the 10,000 limit is stated in characters, and this output is
  # full of em dashes at three bytes each. Measuring bytes would overstate the payload by
  # a few percent — harmless — but it would also let a byte-denominated budget be compared
  # against a character-denominated limit, which is the mistake worth not making.
  small_n=$(printf '%s' "$small_out" | wc -m | tr -d ' ')
  large_n=$(printf '%s' "$large_out" | wc -m | tr -d ' ')

  # The paths differ between the two fixture dirs, so compare sizes after normalising the
  # project dir out of each — what must not differ is everything else.
  small_norm=$(printf '%s' "$small_out" | sed "s#$SMALL##g" | wc -m | tr -d ' ')
  large_norm=$(printf '%s' "$large_out" | sed "s#$LARGE##g" | wc -m | tr -d ' ')

  test_start "$src: payload size is independent of the size of the files it describes"
  if [ "$small_norm" -eq "$large_norm" ]; then
    test_pass
  else
    test_fail "a 200-byte fixture gave $small_n bytes and a 60000-byte one gave $large_n — the payload is tracking a document, so something is being emitted in full"
  fi

  test_start "$src: the worst-case payload is under the declared budget"
  if [ "$large_n" -le "$BUDGET" ]; then
    test_pass
  else
    test_fail "$large_n characters exceeds CPM_PAYLOAD_BUDGET=$BUDGET"
  fi

  # The budget is CPM's own choice; the 10,000-character cap is not. Asserting both means
  # a future edit that raises the budget past the real limit fails here rather than
  # shipping — the budget cannot be used to define the problem away.
  test_start "$src: the worst-case payload is under the harness's hard limit"
  if [ "$large_n" -le "$HARNESS_LIMIT" ]; then
    test_pass
  else
    test_fail "$large_n characters exceeds the ${HARNESS_LIMIT}-character hook output cap — this payload would be replaced by a ~2 KB preview"
  fi
done

# --- The list cap fires, and says that it did ----------------------------------------

STARTUP_OUT=$(run_hook "$STARTUP_HOOK" "$LARGE" "startup")

# Both lists use the same row shape, so each is counted inside its own block rather than
# across the whole payload — otherwise one list could list six and the other none, and the
# total would still look like the cap was working.
block_rows() {
  printf '%s\n' "$STARTUP_OUT" \
    | awk -v want="$1" '$0 ~ want { inside = 1; next }
                        inside && /^--- END ---$/ { exit }
                        inside && /^  [0-9]+\. / { n++ }
                        END { print n + 0 }'
}

test_start "startup: the stale list stops at the cap"
assert_equals "$LIST_CAP" "$(block_rows 'STALE PROGRESS FILES')"

test_start "startup: the parallel list stops at the cap"
assert_equals "$LIST_CAP" "$(block_rows 'ACTIVE/RECENT PARALLEL SESSIONS')"

# A silent cap reads as "that is all of them", which is how a truncation becomes a wrong
# answer rather than a short one — the same failure this whole suite exists to stop, one
# level down. Each list is asserted against its own total, so neither can cover for the
# other going quiet.
test_start "startup: the capped STALE list says how many it left out"
assert_contains "$STARTUP_OUT" "Listing the first ${LIST_CAP} of ${STALE_TOTAL}"

test_start "startup: the capped PARALLEL list says how many it left out"
assert_contains "$STARTUP_OUT" "Listing the first ${LIST_CAP} of ${FRESH_TOTAL}"

test_start "control: with fewer files than the cap, no truncation notice appears"
UNDER=$(setup_fixture 200)
rm -f "$UNDER/docs/plans/.cpm-progress-stale"*.md "$UNDER/docs/plans/.cpm-progress-fresh"*.md
printf '# CPM Session State\n\n**Skill**: cpm:do\n**Phase**: Load Context\n' > "$UNDER/docs/plans/.cpm-progress-lone.md"
touch -t 202001010000 "$UNDER/docs/plans/.cpm-progress-lone.md"
assert_not_contains "$(run_hook "$STARTUP_HOOK" "$UNDER" "startup")" "Listing the first"

# --- The conventions extract: every named section exists, and arrives -----------------

CORE_NAMES=$(awk '/^CORE_SECTIONS="/ { inside = 1; sub(/^CORE_SECTIONS="/, ""); }
                  inside {
                    line = $0
                    if (sub(/"$/, "", line)) { if (line != "") print line; exit }
                    if (line != "") print line
                  }' "$CORE_LIB")

test_start "control: CORE_SECTIONS was read out of the shared library"
CORE_COUNT=$(printf '%s\n' "$CORE_NAMES" | grep -c .)
if [ "$CORE_COUNT" -ge 1 ]; then
  test_pass
else
  test_fail "no section names parsed out of $CORE_LIB — every check below would be vacuous"
fi

CORE_OUT=$(bash "$CORE_LIB" "$CONVENTIONS")

MISSING_HEADINGS=""
EMPTY_SECTIONS=""
while IFS= read -r name; do
  [ -z "$name" ] && continue
  grep -qxF "## $name" "$CONVENTIONS" || MISSING_HEADINGS="$MISSING_HEADINGS $name"
  body=$(awk -v want="## $name" '$0 == want { inside = 1; next }
                                 inside && /^## / { exit }
                                 inside { print }' "$CONVENTIONS" | grep -c .)
  [ "$body" -gt 0 ] || EMPTY_SECTIONS="$EMPTY_SECTIONS $name"
done <<EOF
$CORE_NAMES
EOF

test_start "every name in CORE_SECTIONS is a real heading in skill-conventions.md"
if [ -z "$MISSING_HEADINGS" ]; then
  test_pass
else
  test_fail "no such heading:$MISSING_HEADINGS — a name that matches nothing emits nothing, silently"
fi

test_start "control: each named section has a body, so a match is not a match on nothing"
if [ -z "$EMPTY_SECTIONS" ]; then
  test_pass
else
  test_fail "empty section:$EMPTY_SECTIONS"
fi

test_start "the emitted extract carries each core section's heading"
MISSING_FROM_OUT=""
while IFS= read -r name; do
  [ -z "$name" ] && continue
  printf '%s' "$CORE_OUT" | grep -qxF "## $name" || MISSING_FROM_OUT="$MISSING_FROM_OUT $name"
done <<EOF
$CORE_NAMES
EOF
if [ -z "$MISSING_FROM_OUT" ]; then
  test_pass
else
  test_fail "named in CORE_SECTIONS but absent from the output:$MISSING_FROM_OUT"
fi

# The must-NOT that makes "extract" mean something. A section outside CORE_SECTIONS must
# appear in the index and NOT as a heading of its own with a body — otherwise the hook is
# back to emitting the file.
test_start "a section outside CORE_SECTIONS is indexed but not emitted"
NON_CORE=$(grep '^## ' "$CONVENTIONS" | sed 's/^## //' | while IFS= read -r h; do
  printf '%s\n' "$CORE_NAMES" | grep -qxF "$h" || { echo "$h"; break; }
done)
assert_contains "$CORE_OUT" "$NON_CORE"
if printf '%s' "$CORE_OUT" | grep -qxF "## $NON_CORE"; then
  test_fail "'$NON_CORE' is emitted as a full section, so the extract is not an extract"
else
  test_pass
fi

# --- The pointer: a reader is told where the rest is ---------------------------------

test_start "the extract names the conventions file by path"
assert_contains "$CORE_OUT" "skill-conventions.md"

test_start "and says the procedures are not in context"
assert_contains "$CORE_OUT" "NOT in your context"

# Skills say "follow the shared X procedure". If that phrase is not the trigger the pointer
# arms, the pointer is answering a question nobody asks.
test_start "the pointer keys on the phrase the skills actually use"
assert_contains "$CORE_OUT" "follow the shared"

test_start "control: the phrase the pointer keys on is one the skills really use"
SKILL_USES=$(grep -rl "shared \*\*[A-Za-z /-]*\*\* procedure" "$SCRIPT_DIR/../../skills"/*/SKILL.md | wc -l | tr -d ' ')
if [ "$SKILL_USES" -ge 2 ]; then
  test_pass
else
  test_fail "only $SKILL_USES skills defer to a shared procedure — the pointer's premise is wrong"
fi

# --- Both hooks emit the same extract ------------------------------------------------
#
# Two hooks, one decision about what a session needs. They share a library so this cannot
# drift, and this asserts the sharing rather than trusting it.

STARTUP_CORE=$(run_hook "$STARTUP_HOOK" "$SMALL" "startup" | grep -c '^## ')
COMPACT_CORE=$(run_hook "$COMPACT_HOOK" "$SMALL" "compact" | grep -c '^## ')

test_start "both hooks emit the same conventions extract"
assert_agrees "the number of full sections emitted" \
  "session-start.sh" "$STARTUP_CORE" \
  "session-start-compact.sh" "$COMPACT_CORE"

# --- The compact hook's recovery pointer ---------------------------------------------
#
# After compaction there is no context left, so naming the files is the entire recovery
# path. Both must be named, and the instruction must be to read them.

COMPACT_OUT=$(run_hook "$COMPACT_HOOK" "$LARGE" "compact")

test_start "compact: the progress file is named"
assert_contains "$COMPACT_OUT" ".cpm-progress-${CUR_ID}.md"

test_start "compact: the compact summary is named"
assert_contains "$COMPACT_OUT" ".cpm-compact-summary-${CUR_ID}.md"

test_start "compact: the reader is told to read them"
assert_contains "$COMPACT_OUT" "Read this file now"
assert_contains "$COMPACT_OUT" "Read it for what was"

# The ordering rule, asserted. The recovery pointer is what a post-compaction context most
# needs, so it must not sit behind the conventions extract.
test_start "compact: the recovery pointer precedes the conventions extract"
RECOVERY_LINE=$(printf '%s\n' "$COMPACT_OUT" | grep -n 'CPM SESSION STATE' | head -1 | cut -d: -f1)
CONVENTIONS_LINE=$(printf '%s\n' "$COMPACT_OUT" | grep -n 'CPM Shared Skill Conventions' | head -1 | cut -d: -f1)
if [ -n "$RECOVERY_LINE" ] && [ -n "$CONVENTIONS_LINE" ] && [ "$RECOVERY_LINE" -lt "$CONVENTIONS_LINE" ]; then
  test_pass
else
  test_fail "recovery pointer at line ${RECOVERY_LINE:-none}, conventions at ${CONVENTIONS_LINE:-none} — the urgent output is not first"
fi

# The same rule on the startup side, where the urgent output is the ralph warning.
test_start "startup: the active-loop warning precedes the conventions extract"
WARN_LINE=$(printf '%s\n' "$STARTUP_OUT" | grep -n 'ACTIVE RALPH LOOP DETECTED' | head -1 | cut -d: -f1)
CONV_LINE=$(printf '%s\n' "$STARTUP_OUT" | grep -n 'CPM Shared Skill Conventions' | head -1 | cut -d: -f1)
if [ -n "$WARN_LINE" ] && [ -n "$CONV_LINE" ] && [ "$WARN_LINE" -lt "$CONV_LINE" ]; then
  test_pass
else
  test_fail "ralph warning at line ${WARN_LINE:-none}, conventions at ${CONV_LINE:-none}"
fi

test_start "startup: the session's own state precedes the conventions extract"
STATE_LINE=$(printf '%s\n' "$STARTUP_OUT" | grep -n 'CPM SESSION STATE' | head -1 | cut -d: -f1)
if [ -n "$STATE_LINE" ] && [ -n "$CONV_LINE" ] && [ "$STATE_LINE" -lt "$CONV_LINE" ]; then
  test_pass
else
  test_fail "session state at line ${STATE_LINE:-none}, conventions at ${CONV_LINE:-none}"
fi

# --- What survives the failure mode itself -------------------------------------------
#
# The budget assertions above say the payload should not breach the cap. This one says
# what happens if it does anyway — because the cap is external, undefended, and currently
# the subject of two open bugs. On breach the harness shows a ~2 KB preview, so anything
# inside the first HARNESS_PREVIEW characters still reaches the session. That makes the
# ordering rule a guarantee rather than a preference, and this is where it is enforced:
# the content that can cost a user work must fit in the preview, whatever else does not.
#
# It is deliberately NOT asserted for the conventions extract. That one names a file which
# is on disk either way, so losing it costs a Read call — which is the whole reason it was
# put last.

# `cut -c` would take the first N characters of EVERY LINE, which on this payload is
# almost all of it — a preview that proves nothing. `head -c` truncates the stream, and
# takes BYTES: since a byte count is never below the character count, this cuts at or
# before the real preview boundary, so the assertions below are conservative.
preview_of() { printf '%s' "$1" | head -c "$HARNESS_PREVIEW"; }

STARTUP_PREVIEW=$(preview_of "$STARTUP_OUT")
COMPACT_PREVIEW=$(preview_of "$COMPACT_OUT")

test_start "control: the preview really is a truncation, not the whole payload"
PREVIEW_N=$(printf '%s' "$STARTUP_PREVIEW" | wc -m | tr -d ' ')
FULL_N=$(printf '%s' "$STARTUP_OUT" | wc -m | tr -d ' ')
if [ "$PREVIEW_N" -lt "$FULL_N" ]; then
  test_pass
else
  test_fail "preview ($PREVIEW_N) is not shorter than the payload ($FULL_N), so the checks below prove nothing"
fi

test_start "startup: the active-loop warning survives a preview-only truncation"
assert_contains "$STARTUP_PREVIEW" "ACTIVE RALPH LOOP DETECTED"

test_start "startup: the session's own state survives a preview-only truncation"
assert_contains "$STARTUP_PREVIEW" "CPM SESSION STATE"

test_start "compact: the recovery pointer survives a preview-only truncation"
assert_contains "$COMPACT_PREVIEW" "CPM SESSION STATE"

test_start "compact: the summary pointer survives a preview-only truncation"
assert_contains "$COMPACT_PREVIEW" "CPM COMPACT SUMMARY"

test_summary
