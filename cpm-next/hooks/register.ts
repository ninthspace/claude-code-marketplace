import type { EngineInterface, Register } from 'claude-code'

import { decide, isCommit } from './guard'

const fsOf = ($: EngineInterface) => ({
  read: (path: string) => $.fs.read(path),
  exists: (path: string) => $.fs.exists(path),
  list: (path: string) => $.fs.list(path),
  real: async (path: string) => (await $.fs.stat(path, { resolve: true })).realPath ?? path,
})

export const register: Register = on => {
  // A red pass leaves source files mutated until it ends; a commit made then would record the mutation.
  on('tool.call', { tool: 'Bash' }, async ($, e, next) => {
    const { command } = e as unknown as { command?: unknown }
    if (typeof command !== 'string' || !isCommit(command)) return next(e)
    const reason = await decide(command, await $.session.cwd(), fsOf($))

    return reason === undefined ? next(e) : { deny: reason }
  })
}
