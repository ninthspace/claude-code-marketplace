import { expect, test } from 'claude-code/testing'

import { familyOf, isHeldSkill, isPersonsSwitch, overrideFor, statusText } from './pin'

test('every cpm-next skill is held, others are not', () => {
  expect(isHeldSkill('cpm-next:do')).toBe(true)
  expect(isHeldSkill('cpm-next:status')).toBe(true)
  expect(isHeldSkill('cpm:do')).toBe(false)
  expect(isHeldSkill('commit')).toBe(false)
})

test('a held model replaces a different step model only', () => {
  const held = { skill: 'cpm-next:do', model: 'claude-sonnet-5-5' }
  expect(overrideFor(held, 'claude-opus-5-5')).toBe('claude-sonnet-5-5')
  expect(overrideFor(held, 'claude-sonnet-5-5')).toBeUndefined()
  expect(overrideFor(null, 'claude-opus-5-5')).toBeUndefined()
})

test("only the person's own switch releases the hold", () => {
  expect(isPersonsSwitch('command')).toBe(true)
  expect(isPersonsSwitch('picker')).toBe(true)
  expect(isPersonsSwitch('auto')).toBe(false)
  expect(isPersonsSwitch('resume')).toBe(false)
})

test('status line text', () => {
  expect(familyOf('claude-opus-5-5')).toBe('opus')
  expect(familyOf('custom-model')).toBe('custom-model')
  expect(statusText({ skill: 'cpm-next:do', model: 'claude-sonnet-5-5' })).toBe('cpm-next:do · sonnet')
  expect(statusText(null)).toBeUndefined()
})
