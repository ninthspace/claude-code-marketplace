#!/usr/bin/env bash
# Updates this machine's installs of ninthspace-marketplace plugins to the versions in the repository's
# marketplace.json. With a commit sha, first waits (up to two minutes) until origin's main is at that
# commit, so it can run from pre-push before the push has landed. plugin-sync reloads open sessions.
set -euo pipefail

MARKETPLACE=ninthspace-marketplace
SHA=${1:-}

# Each remote read gives up after 10 seconds, and the wait after two minutes in all.
remote_main() { GIT_SSH_COMMAND="ssh -o ConnectTimeout=10" git ls-remote origin refs/heads/main 2>/dev/null | cut -f1; }

if [[ -n "$SHA" ]]; then
  until [[ "$(remote_main)" == "$SHA" ]]; do
    (( SECONDS < 120 )) || { echo "origin/main did not reach $SHA within two minutes; nothing updated"; exit 1; }
    sleep 2
  done
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
