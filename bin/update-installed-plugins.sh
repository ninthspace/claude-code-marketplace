#!/usr/bin/env bash
# Updates this machine's installs of ninthspace-marketplace plugins to the versions in the repository's
# marketplace.json. With a commit sha, first waits (up to two minutes) until origin's main is at that
# commit, so it can run from pre-push before the push has landed. plugin-sync reloads open sessions.
set -euo pipefail

MARKETPLACE=ninthspace-marketplace
SHA=${1:-}

if [[ -n "$SHA" ]]; then
  for _ in $(seq 1 60); do
    [[ "$(git ls-remote origin refs/heads/main | cut -f1)" == "$SHA" ]] && break
    sleep 2
  done
  [[ "$(git ls-remote origin refs/heads/main | cut -f1)" == "$SHA" ]] || { echo "origin/main never reached $SHA; nothing updated"; exit 1; }
fi

claude plugin marketplace update "$MARKETPLACE"

# Each installed plugin whose user-scope version differs from the version marketplace.json now lists.
stale=$(python3 - "$MARKETPLACE" "${SHA:-HEAD}" <<'PY'
import json, os, subprocess, sys
market, ref = sys.argv[1], sys.argv[2]
listed = {p['name']: p['version'] for p in json.loads(subprocess.check_output(['git', 'show', f'{ref}:.claude-plugin/marketplace.json']))['plugins']}
installed = json.load(open(os.path.expanduser('~/.claude/plugins/installed_plugins.json'))).get('plugins', {})
for key, installs in installed.items():
    name, _, source = key.partition('@')
    user = next((i for i in installs if i.get('scope') == 'user'), None)
    if source == market and user is not None and name in listed and user.get('version') != listed[name]:
        print(f"{name} {user.get('version')} {listed[name]}")
PY
)

if [[ -z "$stale" ]]; then
  echo "All installed $MARKETPLACE plugins are current."
  exit 0
fi
while read -r name from to; do
  echo "Updating $name $from -> $to"
  claude plugin update "$name@$MARKETPLACE" --scope user
done <<< "$stale"
