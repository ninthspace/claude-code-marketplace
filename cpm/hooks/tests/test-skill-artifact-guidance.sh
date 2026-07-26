#!/bin/bash
# test-skill-artifact-guidance.sh — Tests for the per-skill "when an artifact earns
# its place here" guidance added beside the canonical reference line.
#
# These back Epic 41-03 Story 2's [integration] acceptance criteria (spec 41 R4).
#
# The story's first criterion — that each sentence names something apt for *that*
# skill's output — is tagged [manual] and is deliberately not tested here: whether a
# problem map is the right artifact for `discover` has no automatable oracle, and a
# grep proxy for it would report quality it cannot see. What is tested is the part
# that is structural: the sentence exists at each site, sits with the reference line,
# names its own skill rather than a neighbour's, and is not a restatement of the
# shared procedure.
#
# The heuristic is the load-bearing assertion. Nine new suggestion sites are nine new
# chances for artifact generation to become a default; the heuristic is the sentence
# that keeps each one honest, so it is asserted verbatim rather than by paraphrase.
#
# Assertions whose two halves form one claim share a test_start (retro 15).

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
source "$SCRIPT_DIR/test-helpers.sh"

SKILLS_DIR="$SCRIPT_DIR/../../skills"
CONVENTIONS="$SCRIPT_DIR/../../shared/skill-conventions.md"

# The nine skills R4 names. `present` carries the reference line but no earns-its-place
# guidance: its artifact *is* the communication, so there is no judgement call about
# whether a visual is warranted.
NINE="discover brief architect spec epics review audit retro status"

HEURISTIC='if you cannot write the one-line justification for what the visual carries that the prose cannot, it has not earned its place'
CANONICAL='An artifact can be published from this output on request — follow the shared **Artifact Publishing** procedure. It is always separately confirmed, and never the default.'

echo "Testing: per-skill artifact guidance"
echo "===================================="

# --- Criterion: each of the nine names what an artifact could show ---
# Structural half only; aptness is the [manual] half.

for skill in $NINE; do
  file="$SKILLS_DIR/$skill/SKILL.md"

  test_start "$skill names what an artifact would show for its own output"
  if [ ! -f "$file" ]; then
    test_fail "Expected skill at $file"
    continue
  fi
  # The site names *this* skill. A copied sentence naming another skill is the drift
  # this catches — it reads correctly and describes the wrong output.
  if grep -qF "For \`$skill\` the artifact is" "$file"; then
    test_pass
  else
    test_fail "no \"For \\\`$skill\\\` the artifact is …\" sentence found"
  fi
done

# --- Criterion: the heuristic appears verbatim at each of the nine ---

for skill in $NINE; do
  test_start "$skill carries the conservative heuristic verbatim"
  count=$(grep -cF "$HEURISTIC" "$SKILLS_DIR/$skill/SKILL.md")
  if [ "$count" -ge 1 ]; then
    test_pass
  else
    test_fail "heuristic absent (found $count occurrences)"
  fi
done

# --- The guidance sits with the reference line, not adrift in the file ---

for skill in $NINE; do
  file="$SKILLS_DIR/$skill/SKILL.md"

  test_start "$skill's guidance sits with the reference line"
  # Every reference line, not the first. A skill with two publishable outputs carries the
  # line twice — `status` gained a second site in epic 44-02, for the spec coverage page —
  # and each site needs its own guidance. Taking `head -1` on both sides would let one
  # site's sentence stand in for the other's, which is precisely the drift this checks for.
  ref_lns=$(grep -nxF "$CANONICAL" "$file" | cut -d: -f1)
  sent_lns=$(grep -nF "For \`$skill\` the artifact is" "$file" | cut -d: -f1)
  if [ -z "$ref_lns" ] || [ -z "$sent_lns" ]; then
    test_fail "reference lines '${ref_lns:-none}', sentences '${sent_lns:-none}'"
    continue
  fi
  # One blank line between them. Adjacency is the claim: guidance placed elsewhere in
  # the file is guidance a reader arriving via the reference line never sees.
  orphaned=""
  for ref_ln in $ref_lns; do
    printf '%s\n' "$sent_lns" | grep -qx "$((ref_ln + 2))" || orphaned="$orphaned $ref_ln"
  done
  if [ -z "$orphaned" ]; then
    test_pass
  else
    test_fail "reference line(s) at$orphaned have no guidance sentence two lines below"
  fi
done

# --- must NOT make artifact generation a default, automatic, or unconfirmed behaviour ---

test_start "The shared procedure still states publishing is never a default"
assert_contains "$(cat "$CONVENTIONS")" 'Publishing is never offered as a default'

for skill in $NINE; do
  file="$SKILLS_DIR/$skill/SKILL.md"

  test_start "$skill does not make generation automatic or unconfirmed"
  # Two halves of one claim: the on-request trigger is present, and no site overrides
  # it with language that fires generation without a request or a confirmation.
  if grep -qxF "$CANONICAL" "$file" \
    && ! grep -qiE 'automatically publish|publish(es)? (it|the page|the artifact) (automatically|by default)|always publish' "$file"; then
    test_pass
  else
    test_fail "missing the on-request line, or carrying automatic-publish language"
  fi
done

# --- must NOT offer publishing during an autonomous run ---
# The rule has one home: the shared procedure every site reaches through the reference
# line. Restating it at nine sites would be nine copies to drift. What is asserted here
# is that the rule exists, names the autonomous skill, and that `ralph` — the skill that
# runs unattended — introduces no publishing instruction of its own.

test_start "The shared procedure forbids publishing on autonomous runs, naming cpm:ralph"
CONV=$(cat "$CONVENTIONS")
if printf '%s' "$CONV" | grep -qF 'autonomous runs (`cpm:ralph`) never publish'; then
  test_pass
else
  test_fail "the autonomous-run prohibition is not stated in $CONVENTIONS"
fi

test_start "ralph introduces no publishing instruction of its own"
assert_empty "$(grep -niE 'artifact tool|publish' "$SKILLS_DIR/ralph/SKILL.md")"

# --- The local sentence is not a restatement of the shared procedure ---

for skill in $NINE; do
  test_start "$skill's sentence carries judgement, not a copy of the shared rule"
  sentence=$(grep -F "For \`$skill\` the artifact is" "$SKILLS_DIR/$skill/SKILL.md" | head -1)
  if [ -n "$sentence" ] && ! printf '%s' "$sentence" | grep -qF 'follow the shared'; then
    test_pass
  else
    test_fail "sentence missing, or restating the shared procedure: $sentence"
  fi
done

# --- Negative controls ---
# Each check is asserted to fail on the shape it exists to reject.

FIXTURES="$TEST_TMPDIR/fixtures"
mkdir -p "$FIXTURES"

# A sentence naming the wrong skill — reads fine, describes another skill's output.
printf 'For `epics` the artifact is a readiness view.\n' > "$FIXTURES/wrong-skill.md"

test_start "Negative control: a sentence naming another skill is not accepted for this one"
if ! grep -qF 'For `discover` the artifact is' "$FIXTURES/wrong-skill.md"; then
  test_pass
else
  test_fail "the per-skill check matched a sentence naming a different skill"
fi

# A paraphrased heuristic — the meaning survives, the verbatim string does not.
printf "If you can't justify the visual in a line, don't generate it.\n" \
  > "$FIXTURES/paraphrased.md"

test_start "Negative control: a paraphrased heuristic is not accepted"
if [ "$(grep -cF "$HEURISTIC" "$FIXTURES/paraphrased.md")" -eq 0 ]; then
  test_pass
else
  test_fail "the verbatim check accepted a paraphrase"
fi

# Automatic-publish language — the must-NOT this guards.
printf '%s\n\nThe page is automatically published once the document is saved.\n' \
  "$CANONICAL" > "$FIXTURES/automatic.md"

test_start "Negative control: automatic-publish language is rejected"
if grep -qiE 'automatically publish|publish(es)? (it|the page|the artifact) (automatically|by default)|always publish' "$FIXTURES/automatic.md"; then
  test_pass
else
  test_fail "the automatic-publish pattern missed 'automatically published'"
fi

test_summary
