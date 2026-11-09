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
