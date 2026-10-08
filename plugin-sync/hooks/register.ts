import type { EngineInterface, Register } from 'claude-code'

import { changes, installedVersions } from './sync'

const INTERVAL_MS = 5 * 60 * 1000

let loaded: Map<string, string> | null = null
let isStarted = false
let isReloading = false

async function readVersions($: EngineInterface): Promise<Map<string, string> | null> {
  try {
    const home = await $.env.get('HOME')

    return installedVersions(await $.fs.read(`${home}/.claude/plugins/installed_plugins.json`), await $.session.root())
  } catch {
    return null
  }
}

/** Reloads the session's plugins when the installed versions differ from the ones it loaded. */
async function check($: EngineInterface) {
  if (isReloading || loaded === null) return
  const now = await readVersions($)
  if (now === null) return
  const changed = changes(loaded, now)
  if (changed.length === 0) return

  const previous = loaded
  isReloading = true
  try {
    // Recorded before the reload: when this mod's own code is unchanged it is not rebuilt, and would otherwise reload again.
    loaded = now
    $.ui.toast(`Reloading plugins: ${changed.join(', ')}`, { timeoutMs: 8000 })
    await $.command.run({ command: 'reload-plugins' })
  } catch {
    // A refused or failed reload is tried again at the next check.
    loaded = previous
  } finally {
    isReloading = false
  }
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    if (!isStarted) {
      isStarted = true
      loaded = await readVersions($)
      $.clock.every(INTERVAL_MS, () => void check($))
    }

    return next(e)
  })

  // After each answer, once the session is idle; the run is queued, never awaited inside the turn.
  on('turn.complete', async ($, e, next) => {
    const result = await next(e)
    $.clock.after(1000, () => void check($))

    return result
  })
}
