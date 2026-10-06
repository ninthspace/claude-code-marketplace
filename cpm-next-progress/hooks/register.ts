import type { EngineInterface, Register } from 'claude-code'

import type { Drift, EpicFile, LiveDoc } from './progress'
import { buildItems, dateOf, describeDrift, diff, fillTemplate, modelNote, parseBuildOrder, parseDocs, pendingJson } from './progress'

const ORDER_FILE = /^\d+-build-order\.json$/
const EPIC_FILE = /-epic-.*\.md$/
const WRITING_TOOLS = new Set(['Edit', 'Write', 'MultiEdit', 'NotebookEdit', 'Bash'])
const COMMAND = 'progress-tracker'
const WORK_DIR = '.claude/cpm-next-progress'

type Listing = { name: string; mtimeMs: number; size: number }
type Check = { lines: string[]; drift: Drift[] }

async function findRoot($: EngineInterface): Promise<string | null> {
  let dir = await $.session.cwd()
  for (;;) {
    if (await $.fs.exists(`${dir}/docs/specifications`)) return dir
    const cut = dir.lastIndexOf('/')
    if (cut <= 0) return null
    dir = dir.slice(0, cut)
  }
}

async function listDocs($: EngineInterface, dir: string, pattern: RegExp): Promise<Listing[]> {
  if (!(await $.fs.exists(dir))) return []

  return (await $.fs.list(dir)).filter(e => e.kind === 'file' && pattern.test(e.name)).sort((a, b) => a.name.localeCompare(b.name))
}

const signatureOf = (...lists: Listing[][]) => lists.map(list => list.map(e => `${e.name}:${e.mtimeMs}:${e.size}`).join(',')).join('|')

async function readEpics($: EngineInterface, root: string): Promise<EpicFile[]> {
  const files: EpicFile[] = []
  for (const e of await listDocs($, `${root}/docs/epics`, EPIC_FILE)) {
    files.push({ name: e.name, text: await $.fs.read(`${root}/docs/epics/${e.name}`) })
  }

  return files
}

/** Reads one collection of the artifact. Reads need no approval from auto mode; this mod never writes. */
async function readLive($: EngineInterface, url: string, collection: string): Promise<LiveDoc[]> {
  const result = await $.tool.call({ tool: 'ArtifactData', action: 'list', url, collection, query: { limit: 1000 } })
  if ('deny' in result && result.deny !== undefined) throw new Error(result.deny)
  if (result.isError === true) throw new Error(result.text ?? 'the read failed')

  return parseDocs(result.text ?? '')
}

/** Compares one build-order file with the epic docs and the live artifact, and saves the writes that would bring them in line. */
async function checkOne($: EngineInterface, root: string, name: string): Promise<{ line: string; drift?: Drift }> {
  const order = parseBuildOrder(await $.fs.read(`${root}/docs/specifications/${name}`))
  if (order.artifact === undefined) return { line: `${name}: no tracker yet; run /${COMMAND} init ${name}` }

  const { items, missing } = buildItems(order, await readEpics($, root), dateOf(await $.clock.now()))
  const live = await readLive($, order.artifact, 'items')
  const liveMeta = (await readLive($, order.artifact, 'meta')).find(d => d.id === 'tracker')
  const writes = diff(items, { title: order.title, spec: order.spec ?? '', decisions: order.decisions ?? [] }, live, liveMeta)
  const skipped = missing.length === 0 ? '' : `; not found in the epics: ${missing.join(', ')}`
  if (writes.length === 0) return { line: `${name}: up to date${skipped}` }

  const file = `${root}/${WORK_DIR}/${name.replace(/\.json$/, '')}.pending.json`
  const drift: Drift = { name, url: order.artifact, file, writes }
  await $.fs.write(file, pendingJson(drift))

  return { line: `${describeDrift(drift)}${skipped}`, drift }
}

let isChecking = false

/**
 * Checks every tracker in the repository. Unless forced, it does nothing when the epic docs and
 * build-order files are as they were at the last check, so a tool call that changed neither costs
 * two directory listings.
 */
async function checkAll($: EngineInterface, isForced: boolean): Promise<Check> {
  if (isChecking) return { lines: ['A check is already running.'], drift: [] }
  isChecking = true
  try {
    const root = await findRoot($)
    if (root === null) return { lines: ['No docs/specifications folder in this directory or above it.'], drift: [] }
    const orders = await listDocs($, `${root}/docs/specifications`, ORDER_FILE)
    if (orders.length === 0) return { lines: [`No docs/specifications/NN-build-order.json in ${root}.`], drift: [] }
    const signature = `${root}|${signatureOf(orders, await listDocs($, `${root}/docs/epics`, EPIC_FILE))}`
    if (!isForced && signature === (await $.store.get(`checked:${root}`))) return { lines: [], drift: [] }

    const lines: string[] = []
    const drift: Drift[] = []
    let isFailed = false
    for (const order of orders) {
      try {
        const found = await checkOne($, root, order.name)
        lines.push(found.line)
        if (found.drift !== undefined) drift.push(found.drift)
      } catch (error) {
        isFailed = true
        lines.push(`${order.name}: check failed: ${error instanceof Error ? error.message : String(error)}`)
      }
    }
    // A failed check is repeated at the next change; a finished one, drift or not, is reported once.
    if (!isFailed) await $.store.set(`checked:${root}`, signature)

    return { lines, drift }
  } finally {
    isChecking = false
  }
}

/** Writes the page for a build-order file; publishing it is left to the model, which is the one the permission system evaluates. */
async function prepare($: EngineInterface, arg: string): Promise<string> {
  const root = await findRoot($)
  if (root === null) return 'No docs/specifications folder in this directory or above it.'
  const name = arg.split('/').at(-1) ?? arg
  if (!ORDER_FILE.test(name)) return `Name a build-order file: /${COMMAND} init 01-build-order.json`
  const path = `${root}/docs/specifications/${name}`
  if (!(await $.fs.exists(path))) return `${path} does not exist.`
  const order = parseBuildOrder(await $.fs.read(path))
  if (order.artifact !== undefined) return `${name} already has a tracker: ${order.artifact}`

  const repo = root.split('/').filter(Boolean).at(-1) ?? root
  const page = `${root}/${WORK_DIR}/${name.replace(/\.json$/, '')}.html`
  await $.fs.write(page, fillTemplate(await $.fs.read(`${$.plugin.root}/page/tracker.html`), order, repo))

  return [
    `Page written to ${page}.`,
    `Ask Claude to publish it: the Artifact tool, icon "checklist", capabilities {"db":{"rules":[{"path":"","read":"view","write":"admin"}]}},`,
    `then to put the link in the "artifact" field of ${name}. The next check lists the rows to write, and Claude writes them.`,
  ].join('\n')
}

let isStarted = false

async function start($: EngineInterface) {
  if (isStarted) return
  isStarted = true
  await $.command.register({ name: COMMAND, description: 'Check the cpm-next progress trackers against the epic docs and list what to update, or "init NN-build-order.json" to prepare a new page' })
  const { lines, drift } = await checkAll($, false)
  if (drift.length > 0) $.ui.toast(`Progress tracker out of date: ${lines.join(' · ')}`)
}

export const register: Register = on => {
  on('session.start', async ($, e, next) => {
    await start($).catch(() => undefined)

    return next(e)
  })

  // A plugin loaded by /reload-plugins sees no session.start; start on the first prompt.
  on('prompt.submit', async ($, e, next) => {
    await start($).catch(() => undefined)

    return next(e)
  })

  on('command.run', { command: COMMAND }, async ($, e) => {
    const [verb, ...rest] = e.args.trim().split(/\s+/)
    if (verb === 'init') return { text: await prepare($, rest.join(' ')) }
    const { lines } = await checkAll($, true)

    return { text: lines.join('\n') }
  })

  // After a tool call that writes, check the trackers if an epic doc or build-order file changed, and
  // tell the model what to write. The tracker is only ever written by the model's own ArtifactData calls.
  on('tool.call', async ($, e, next) => {
    const result = await next(e)
    if (!WRITING_TOOLS.has(String(e.tool)) || result.deny !== undefined || result.isError === true) return result

    const found = await checkAll($, false).catch(() => null)
    if (found === null || found.drift.length === 0) return result
    $.ui.toast(`Progress tracker out of date: ${found.lines.join(' · ')}`)

    return { ...result, context: [...(result.context ?? []), modelNote(found.drift)] }
  })
}
