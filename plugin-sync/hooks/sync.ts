// Pure logic for plugin-sync: which installed plugin versions differ from the ones a session loaded.

export const MARKETPLACE = 'ninthspace-marketplace'

type Install = { scope?: string; projectPath?: string; version?: string }

/**
 * The version of each of the marketplace's plugins that a session in `root` runs, from
 * `~/.claude/plugins/installed_plugins.json`: the project's own install, else the user-scope one.
 */
export function installedVersions(text: string, root: string, marketplace = MARKETPLACE): Map<string, string> {
  const parsed = JSON.parse(text) as { plugins?: Record<string, Install[]> }
  const versions = new Map<string, string>()
  for (const [key, installs] of Object.entries(parsed.plugins ?? {})) {
    if (!key.endsWith(`@${marketplace}`)) continue
    const install = installs.find(i => i.scope === 'project' && i.projectPath === root) ?? installs.find(i => i.scope === 'user')
    if (install?.version !== undefined) versions.set(key.slice(0, -marketplace.length - 1), install.version)
  }

  return versions
}

/** One line per plugin whose version differs from the loaded one, e.g. "cpm-next 0.6.0 → 0.7.0"; added and removed plugins too. */
export function changes(loaded: Map<string, string>, now: Map<string, string>): string[] {
  const lines: string[] = []
  for (const [name, version] of now) {
    const before = loaded.get(name)
    if (before === undefined) lines.push(`${name} ${version} (new)`)
    else if (before !== version) lines.push(`${name} ${before} → ${version}`)
  }
  for (const name of loaded.keys()) {
    if (!now.has(name)) lines.push(`${name} (removed)`)
  }

  return lines.sort()
}
