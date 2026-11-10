import { expect, test } from 'claude-code/testing'

test('a skill the model starts mid-run leaves the hold; a cpm-next one takes it', async ($, on) => {
  const held: Record<string, unknown> = {}
  on('tool.call', () => ({ result: {} }))
  on('state.set', ($, e, next) => {
    held[e.key] = e.value
    return next(e)
  })

  await $.tool.call({ tool: 'Skill', skill: 'cpm-next:do', args: 'all 01' })
  expect(held.pending).toEqual({ skill: 'cpm-next:do', args: 'all 01' })

  await $.tool.call({ tool: 'Skill', skill: 'artifact-capabilities' })
  expect(held.pending).toEqual({ skill: 'cpm-next:do', args: 'all 01' })
  expect(held.pin).toBeUndefined()

  await $.tool.call({ tool: 'Skill', skill: 'cpm-next:review', args: '02-01' })
  expect(held.pending).toEqual({ skill: 'cpm-next:review', args: '02-01' })
})

test('a switch of session model releases the hold; the same model keeps it', async ($, on) => {
  const held: Record<string, unknown> = {}
  let sessionModel = 'opus'
  const sent: string[] = []
  on('tool.call', () => ({ result: {} }))
  on('session.model', () => ({ value: sessionModel }))
  on('state.set', ($, e, next) => {
    held[e.key] = e.value
    return next(e)
  })
  on('turn.step', async function* ($, e) {
    sent.push(e.model)
    return { turnId: e.turnId, index: e.index, answer: '', toolUses: [] }
  })
  const step = async (turnId: string, model: string) => {
    const stream = $.turn.step({ turnId, index: 0, model, messageCount: 1 })
    for await (const _ of stream);
  }

  await $.tool.call({ tool: 'Skill', skill: 'cpm-next:do', args: '3' })
  await step('t1', 'claude-sonnet-5-5')
  expect(held.pin).toMatchObject({ skill: 'cpm-next:do', model: 'claude-sonnet-5-5', sessionModel: 'opus' })

  await step('t2', 'claude-opus-5-5')
  expect(sent.at(-1)).toBe('claude-sonnet-5-5')
  expect(held.pin).not.toBeNull()

  sessionModel = 'haiku'
  await step('t3', 'claude-haiku-5-5')
  expect(sent.at(-1)).toBe('claude-haiku-5-5')
  expect(held.pin).toBeNull()
})
