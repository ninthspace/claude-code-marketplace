import { describe, expect, test } from 'claude-code/testing'

import { candidatePaths, commandDir, displayFolder, isGenerated, resolvePath } from './paths'

const HOME = '/Users/me'
const CWD = '/Users/me/Work/git/app'

describe('which files count', () => {
  test('listed extensions, any case', () => {
    expect(isGenerated('/a/report.HTML')).toBe(true)
    expect(isGenerated('/a/deck.pptx')).toBe(true)
    expect(isGenerated('/a/notes.md')).toBe(false)
    expect(isGenerated('/a/app.ts')).toBe(false)
  })
})

describe('paths in a Bash command', () => {
  test('relative, home and parent paths resolve', () => {
    expect(resolvePath('out/a.html', CWD, HOME)).toBe('/Users/me/Work/git/app/out/a.html')
    expect(resolvePath('~/x/b.pdf', CWD, HOME)).toBe('/Users/me/x/b.pdf')
    expect(resolvePath('$HOME/x/b.pdf', CWD, HOME)).toBe('/Users/me/x/b.pdf')
    expect(resolvePath('../c.png', CWD, HOME)).toBe('/Users/me/Work/git/c.png')
  })

  test('a leading cd sets the folder', () => {
    expect(commandDir('cd ~/Work/git/other && make', CWD, HOME)).toBe('/Users/me/Work/git/other')
    expect(commandDir('npm test', CWD, HOME)).toBe(CWD)
  })

  test('picks out generated files, including redirects and quoted paths', () => {
    expect(candidatePaths('node build.js > dist/index.html && cp "img/logo.svg" out/', CWD, HOME)).toEqual([
      `${CWD}/dist/index.html`,
      `${CWD}/img/logo.svg`,
    ])
  })

  test('md2docx with no output named implies the .docx beside the .md', () => {
    expect(candidatePaths('~/.claude/skills/docx/md2docx.sh docs/brief.md', CWD, HOME)).toEqual([`${CWD}/docs/brief.docx`])
  })

  test('commands with no such file name nothing', () => {
    expect(candidatePaths('git status && php artisan test', CWD, HOME)).toEqual([])
  })
})

test('folders under home show as ~', () => {
  expect(displayFolder('/Users/me/Work/a.html', HOME)).toBe('~/Work')
  expect(displayFolder('/tmp/a.html', HOME)).toBe('/tmp')
})
