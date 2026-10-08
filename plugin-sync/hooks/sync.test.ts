import { expect, test } from 'claude-code/testing'

import { changes, installedVersions } from './sync'

const INSTALLED = JSON.stringify({
  version: 2,
  plugins: {
    'cpm-next@ninthspace-marketplace': [
      { scope: 'user', installPath: '/c/cpm-next/0.7.0', version: '0.7.0' },
      { scope: 'project', projectPath: '/work/a', installPath: '/c/cpm-next/0.6.0', version: '0.6.0' },
    ],
    'weather@ninthspace-marketplace': [{ scope: 'user', installPath: '/c/weather/0.1.2', version: '0.1.2' }],
    'other@elsewhere': [{ scope: 'user', installPath: '/c/other/1.0.0', version: '1.0.0' }],
    'local-only@ninthspace-marketplace': [{ scope: 'project', projectPath: '/work/b', installPath: '/c/l', version: '1.0.0' }],
  },
})

test('a session reads its own project install, else the user install, of the marketplace\'s plugins only', () => {
  expect([...installedVersions(INSTALLED, '/work/a')]).toEqual([['cpm-next', '0.6.0'], ['weather', '0.1.2']])
  expect([...installedVersions(INSTALLED, '/work/c')]).toEqual([['cpm-next', '0.7.0'], ['weather', '0.1.2']])
  expect(installedVersions(INSTALLED, '/work/b').get('local-only')).toBe('1.0.0')
})

test('changes list updated, new and removed plugins, and nothing when versions match', () => {
  const loaded = new Map([['cpm-next', '0.6.0'], ['weather', '0.1.2'], ['gone', '1.0.0']])
  const now = new Map([['cpm-next', '0.7.0'], ['weather', '0.1.2'], ['scout', '0.1.0']])

  expect(changes(loaded, now)).toEqual(['cpm-next 0.6.0 → 0.7.0', 'gone (removed)', 'scout 0.1.0 (new)'])
  expect(changes(now, new Map(now))).toEqual([])
})
