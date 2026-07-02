#!/usr/bin/env bash
# Structural check for the routing-handoff emission (spec 01, M9).
# Covers the [integration] acceptance criterion for Story 2.
#
#   ./scripts/check-routing-emission.sh                     # from the filament-mockup dir
#   ./filament-mockup/scripts/check-routing-emission.sh     # or from the repo root
#
# Exits non-zero on the first failed check.
#
# Limitation: the criterion names an "artifact-exists check after dry-run", but
# this skill cannot be executed here (it needs an LLM + a real brief + Node/
# Playwright to produce a mockup and its routing table). So — consistent with this
# epic family's convention that [integration] criteria in a docs/skills repo are
# verified structurally — this check verifies the SKILL.md *documents* the emission
# (path, schema, the fixed filament column values, and the no-brief-to-mockups
# prerequisite), which is the automatable proxy for "the skill will write it". The
# [manual] method/logic review remains the substantive gate.

set -euo pipefail

skill_dir="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
skill="$skill_dir/SKILL.md"

fail() { echo "FAIL: $1" >&2; exit 1; }
pass() { echo "ok:   $1"; }

[ -f "$skill" ] || fail "$skill does not exist"

# The Phase 7 emission step exists.
grep -qF 'Phase 7 — Write the routing handoff artifact' "$skill" \
  || fail "no 'Phase 7 — Write the routing handoff artifact' step found"
pass "Phase 7 routing-emission step present"

# Names the durable artifact path.
grep -qF 'docs/mockups/surface-routing.md' "$skill" \
  || fail "the routing artifact path docs/mockups/surface-routing.md is not named"
pass "routing artifact path named"

# Names the fixed schema columns.
grep -qF 'surface · FRs · substrate · producer · builder' "$skill" \
  || fail "the routing schema (surface · FRs · substrate · producer · builder) is not named"
pass "routing schema named"

# Names the three fixed column values this producer writes.
for kv in 'substrate = filament' 'producer = filament-mockup' 'builder = mockup-to-filament'; do
  grep -qF "$kv" "$skill" || fail "the fixed value '$kv' is not stated"
  pass "fixed value stated: $kv"
done

# States the no-brief-to-mockups prerequisite (the M9 must-NOT).
grep -qF 'No `brief-to-mockups` prerequisite' "$skill" \
  || fail "the no-brief-to-mockups-prerequisite property (M9 must-NOT) is not stated"
pass "no-brief-to-mockups-prerequisite stated (M9 must-NOT)"

echo
echo "filament-mockup routing emission: all [integration] (structural) checks passed."
