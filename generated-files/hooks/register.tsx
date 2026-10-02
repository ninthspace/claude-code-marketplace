import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register } from 'claude-code'

import type { GeneratedFile } from '../types'
import { candidatePaths, displayFolder, isGenerated } from './paths'

const PANE = 'generated-files'
const TITLE = 'Files'
const LIMIT = 30

const files = atom({ plugin: 'generated-files', key: 'files' } as const, [])

let home = ''
let hasOpened = false

async function homeDir($: EngineInterface): Promise<string> {
  if (home === '') home = (await $.env.get('HOME')) ?? ''

  return home
}

async function remember($: EngineInterface, paths: string[], via: GeneratedFile['via']) {
  if (paths.length === 0) return
  const at = await $.clock.now()
  const base = await homeDir($)
  const added: GeneratedFile[] = paths.map(path => ({
    path,
    name: path.slice(path.lastIndexOf('/') + 1),
    folder: displayFolder(path, base),
    at,
    via,
  }))
  // Newest first; a file written again moves to the top rather than appearing twice.
  await update($, files, list => [...added, ...list.filter(f => !paths.includes(f.path))].slice(0, LIMIT))
  if (!hasOpened) {
    hasOpened = true
    await $.ui.open({ id: PANE, title: TITLE })
  }
}

// Of the paths a command names, the ones that exist and changed while it ran.
async function writtenSince($: EngineInterface, paths: string[], startedAt: number): Promise<string[]> {
  const written: string[] = []
  for (const path of paths) {
    const stat = await $.fs.stat(path).catch(() => undefined)
    if (stat?.kind === 'file' && stat.mtimeMs >= startedAt - 2000) written.push(path)
  }

  return written
}

async function openFile($: EngineInterface, path: string, isReveal: boolean) {
  const argv = isReveal ? ['open', '-R', path] : ['open', path]
  const { exitCode, stderr } = await $.process.run(argv)
  if (exitCode !== 0) $.ui.toast(`Could not open ${path}: ${stderr.trim() || `exit ${exitCode}`}`)
}

let isStarted = false

// Registers /files, once per load.
async function start($: EngineInterface) {
  if (isStarted) return
  isStarted = true
  await $.command.register({ name: 'files', description: 'Show the files Claude generated this session, with Open buttons' })
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    await start($)

    return next(e)
  })

  // A plugin loaded by /reload-plugins (an install or update mid-session) sees no session.start; start on the first prompt.
  on('prompt.submit', async ($, e, next) => {
    await start($)

    return next(e)
  })

  on('command.run', { command: 'files' }, async $ => {
    await $.ui.open({ id: PANE, title: TITLE })
    const list = await read($, files)

    return {
      text: list.length === 0
        ? 'No generated files yet this session.'
        : list.map((f, i) => `${i + 1}. ${f.path}`).join('\n'),
    }
  })

  on('tool.call', { tool: ['Write', 'Edit'] }, async ($, e, next) => {
    const result = await next(e)
    if (!('deny' in result && result.deny !== undefined) && result.isError !== true && isGenerated(e.file_path)) {
      await remember($, [e.file_path], e.tool)
    }

    return result
  })

  on('tool.call', { tool: 'Bash' }, async ($, e, next) => {
    const startedAt = await $.clock.now()
    const result = await next(e)
    const candidates = candidatePaths(e.command, await $.session.cwd(), await homeDir($))
    if (candidates.length > 0) await remember($, await writtenSince($, candidates, startedAt), 'Bash')

    return result
  })

  on('ui.render', { component: 'Pane', requestId: PANE }, async ($, e) => {
    const { Box, Text, Button } = $.ui.resolve(e)
    const list = await read($, files)

    if (list.length === 0) return <Text dimColor>No HTML, image, Office or PDF files generated yet this session.</Text>

    return (
      <Box flexDirection="column">
        <Box>
          <Text bold>{list.length} generated {list.length === 1 ? 'file' : 'files'}  </Text>
          <Button key="clear" label="Clear" plain dimColor onPress={() => void update($, files, () => [])} />
        </Box>
        <Text> </Text>
        {list.map((f, i) => (
          <Box flexDirection="column">
            <Box>
              <Button key={`open-${f.path}`} label="Open" hotkey={i < 9 ? String(i + 1) : undefined} onPress={() => void openFile($, f.path, false)} />
              <Text> </Text>
              <Button key={`reveal-${f.path}`} label="Reveal" onPress={() => void openFile($, f.path, true)} />
              <Text wrap="truncate-end"> {f.name}</Text>
            </Box>
            <Text wrap="truncate-middle" dimColor>  {f.folder}</Text>
          </Box>
        ))}
      </Box>
    )
  })
}
