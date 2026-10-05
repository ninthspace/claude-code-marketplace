import { expect, test } from 'claude-code/testing'

import {
  effortFor, effortStep, familyOf, isHeldSkill, isPersonsSwitch, overrideFor, parseFrontmatter, pickInstall,
  resolveModel, skillName, slashSkill, statusText,
} from './pin'

test('every cpm-next skill is held, others are not', () => {
  expect(isHeldSkill('cpm-next:do')).toBe(true)
  expect(isHeldSkill('/cpm-next:status')).toBe(true)
  expect(isHeldSkill('cpm:do')).toBe(false)
  expect(isHeldSkill('commit')).toBe(false)
  expect(skillName('/cpm-next:do')).toBe('cpm-next:do')
})

test('do all runs at high effort; everything else keeps the frontmatter effort', () => {
  expect(effortFor('cpm-next:do', 'all', 'medium')).toBe('high')
  expect(effortFor('/cpm-next:do', '  ALL epics', 'medium')).toBe('high')
  expect(effortFor('cpm-next:do', 'docs/epics/03-epic-auth.md', 'medium')).toBe('medium')
  expect(effortFor('cpm-next:do', 'allow guests to book', 'medium')).toBe('medium')
  expect(effortFor('cpm-next:plan', 'all', 'medium')).toBe('medium')
  expect(effortFor('cpm-next:status', '', undefined)).toBeUndefined()
})

test('a held model replaces a different step model only', () => {
  const held = { skill: 'cpm-next:do', model: 'claude-sonnet-5-5', turnId: 't1' }
  expect(overrideFor(held, 'claude-opus-5-5')).toBe('claude-sonnet-5-5')
  expect(overrideFor(held, 'claude-sonnet-5-5')).toBeUndefined()
  expect(overrideFor(null, 'claude-opus-5-5')).toBeUndefined()
})

test('held effort applies until the person changes /effort', () => {
  const start = { skill: 'cpm-next:do', model: 'claude-sonnet-5-5', effort: 'high' as const, turnId: 't1' }

  const sameTurn = effortStep(start, 't1', 'high')
  expect(sameTurn).toEqual({ effort: 'high', pin: start })

  const nextTurn = effortStep(start, 't2', 'medium')
  expect(nextTurn.effort).toBe('high')
  expect(nextTurn.pin).toEqual({ ...start, baseline: 'medium' })

  const unchanged = effortStep(nextTurn.pin, 't3', 'medium')
  expect(unchanged).toEqual({ effort: 'high', pin: nextTurn.pin })

  const changed = effortStep(nextTurn.pin, 't4', 'low')
  expect(changed.effort).toBe('low')
  expect(changed.pin).toEqual({ ...nextTurn.pin, effort: undefined })
  expect(effortStep(changed.pin, 't5', 'max').effort).toBe('max')
})

test('no held effort leaves the request alone', () => {
  expect(effortStep(null, 't1', 'medium').effort).toBe('medium')
  const modelOnly = { skill: 'cpm-next:party', model: 'claude-sonnet-5-5', turnId: 't1' }
  expect(effortStep(modelOnly, 't2', 'low')).toEqual({ effort: 'low', pin: modelOnly })
})

test("only the person's own switch releases the hold", () => {
  expect(isPersonsSwitch('command')).toBe(true)
  expect(isPersonsSwitch('picker')).toBe(true)
  expect(isPersonsSwitch('auto')).toBe(false)
  expect(isPersonsSwitch('resume')).toBe(false)
})

test('footer label', () => {
  expect(familyOf('claude-opus-5-5')).toBe('opus')
  expect(familyOf('custom-model')).toBe('custom-model')
  expect(statusText({ skill: 'cpm-next:do', model: 'claude-sonnet-5-5', effort: 'high', turnId: 't1' })).toBe('cpm-next:do · sonnet · high')
  expect(statusText({ skill: 'cpm-next:party', model: 'claude-sonnet-5-5', turnId: 't1' })).toBe('cpm-next:party · sonnet')
  expect(statusText(null)).toBeUndefined()
})

test('frontmatter model and effort are read from a SKILL.md', () => {
  const text = '---\nname: status\ndescription: x: y\nmodel: sonnet\neffort: low\n---\n\n# Status\nmodel: opus'
  expect(parseFrontmatter(text)).toEqual({ model: 'sonnet', effort: 'low' })
  expect(parseFrontmatter('---\nname: x\neffort: loud\n---\n')).toEqual({ model: undefined, effort: undefined })
  expect(parseFrontmatter('# no frontmatter')).toEqual({})
})

test('a typed cpm-next skill is recognised with its arguments', () => {
  expect(slashSkill('/cpm-next:do all')).toEqual({ skill: 'cpm-next:do', args: 'all' })
  expect(slashSkill('  /cpm-next:status  ')).toEqual({ skill: 'cpm-next:status', args: '' })
  expect(slashSkill('/cpm-next:plan add a thing\nover two lines')).toEqual({ skill: 'cpm-next:plan', args: 'add a thing\nover two lines' })
  expect(slashSkill('/commit')).toBeNull()
  expect(slashSkill('yes, /cpm-next:do')).toBeNull()
})

test('a frontmatter model family takes the session model version', () => {
  expect(resolveModel('sonnet', 'claude-opus-5-5')).toBe('claude-sonnet-5-5')
  expect(resolveModel('claude-haiku-4-5-20251001', 'claude-opus-5-5')).toBe('claude-haiku-4-5-20251001')
  expect(resolveModel(undefined, 'claude-opus-5-5')).toBe('claude-opus-5-5')
  expect(resolveModel('inherit', 'claude-opus-5-5')).toBe('claude-opus-5-5')
})

test('the project install wins over the user install', () => {
  const installs = [
    { scope: 'user', installPath: '/c/0.6.0' },
    { scope: 'project', projectPath: '/work/a', installPath: '/c/0.3.0' },
  ]
  expect(pickInstall(installs, '/work/a')).toBe('/c/0.3.0')
  expect(pickInstall(installs, '/work/b')).toBe('/c/0.6.0')
  expect(pickInstall([], '/work/b')).toBeUndefined()
})
