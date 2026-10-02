export const EXTENSIONS = ['html', 'htm', 'svg', 'png', 'jpg', 'jpeg', 'gif', 'webp', 'docx', 'xlsx', 'pptx', 'pdf']

const EXT = new RegExp(`\\.(${EXTENSIONS.join('|')})$`, 'i')
const TOKEN = new RegExp(`[^\\s'"\`<>|;&()=]+\\.(?:${EXTENSIONS.join('|')})(?![\\w.])`, 'gi')

export const isGenerated = (path: string) => EXT.test(path)

/** The folder a command runs in: a leading `cd <dir> &&`, else the session's directory. */
export function commandDir(command: string, cwd: string, home: string): string {
  const cd = /^\s*cd\s+(['"]?)([^'"&;|]+?)\1\s*(?:&&|;)/.exec(command)

  return cd?.[2] === undefined ? cwd : resolvePath(cd[2], cwd, home)
}

export function resolvePath(path: string, dir: string, home: string): string {
  const expanded = path === '~' ? home : path.startsWith('~/') ? `${home}${path.slice(1)}` : path.replace(/^\$HOME(?=\/)/, home)
  const absolute = expanded.startsWith('/') ? expanded : `${dir.replace(/\/$/, '')}/${expanded}`
  const parts: string[] = []
  for (const part of absolute.split('/')) {
    if (part === '' || part === '.') continue
    if (part === '..') parts.pop()
    else parts.push(part)
  }

  return `/${parts.join('/')}`
}

/**
 * Paths a Bash command may have written: every token with a listed extension, and for
 * md2docx or pandoc runs the `.docx` beside each `.md` it names (md2docx's default output).
 * The caller keeps only those modified while the command ran.
 */
export function candidatePaths(command: string, cwd: string, home: string): string[] {
  const dir = commandDir(command, cwd, home)
  const found = [...command.matchAll(TOKEN)].map(m => m[0])
  if (/md2docx|pandoc/.test(command)) {
    for (const m of command.matchAll(/[^\s'"`<>|;&()=]+\.md(?![\w.])/g)) found.push(m[0].replace(/\.md$/, '.docx'))
  }

  return [...new Set(found.map(p => resolvePath(p, dir, home)))]
}

export function displayFolder(path: string, home: string): string {
  const folder = path.slice(0, path.lastIndexOf('/')) || '/'

  return folder === home || folder.startsWith(`${home}/`) ? `~${folder.slice(home.length)}` : folder
}
