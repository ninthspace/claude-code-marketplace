import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register } from 'claude-code'

import { forecastUrl, geocodeUrl, statusText } from './weather'

const REFRESH_MS = 15 * 60 * 1000

const reading = atom({ plugin: 'weather', key: 'reading' } as const, null)
const error = atom({ plugin: 'weather', key: 'error' } as const, null)

type Place = { name: string; latitude: number; longitude: number }

// The geocoded place is kept across sessions, so a location costs one lookup.
async function findPlace($: EngineInterface, location: string): Promise<Place | null> {
  const key = `place:${location.toLowerCase()}`
  const saved = (await $.store.get(key)) as Place | undefined
  if (saved !== undefined) return saved

  const response = await $.http.fetch(geocodeUrl(location))
  if (!response.ok) return null
  const first = (JSON.parse(response.text) as { results?: Place[] }).results?.[0]
  if (first === undefined) return null
  const place: Place = { name: first.name, latitude: first.latitude, longitude: first.longitude }
  await $.store.set(key, place)

  return place
}

// Fetches a reading; a failure keeps the last reading and records why, for the footer and /weather.
async function refresh($: EngineInterface, location: string) {
  try {
    const place = await findPlace($, location)
    if (place === null) {
      await update($, error, () => `no place called ${location}`)
      return
    }
    const response = await $.http.fetch(forecastUrl(place.latitude, place.longitude))
    if (!response.ok) {
      await update($, error, () => `forecast HTTP ${response.status}`)
      return
    }
    const { current } = JSON.parse(response.text) as {
      current: { temperature_2m: number; weather_code: number; is_day: number }
    }
    const text = statusText(place.name, current.temperature_2m, current.weather_code, current.is_day === 1)
    await update($, reading, () => text)
    await update($, error, () => null)
  } catch (failure) {
    const message = failure instanceof Error ? failure.message : String(failure)
    await update($, error, () => message.slice(0, 80)).catch(() => undefined)
  }
}

export const register: Register = (on, options) => {
  const location = String(options.location ?? 'Inverness, GB')

  on('session.start', async ($, e, next) => {
    // A status entry pinned by an earlier load outlives a reload; this mod draws in the footer instead.
    $.ui.status(undefined)
    await $.command.register({ name: 'weather', description: 'Refresh the weather now and show the reading or why it failed' })
    // The first fetch runs on a timer of its own, so the session's first prompt never waits on the network.
    $.clock.after(1, () => void refresh($, location))
    $.clock.every(REFRESH_MS, () => void refresh($, location))

    return next(e)
  })

  on('command.run', { command: 'weather' }, async $ => {
    await refresh($, location)
    const text = await read($, reading)
    const failed = await read($, error)

    return { text: failed === null ? (text ?? 'No reading yet.') : `Weather for ${location} failed: ${failed}${text === null ? '' : ` (showing the last reading: ${text})`}` }
  })

  // Drawn as one of the footer's mode labels, at its right-hand end.
  on('ui.render', { component: 'SessionMode' }, async ($, e, next) => {
    const text = await read($, reading)
    const failed = await read($, error)
    const label = text ?? (failed === null ? null : `weather: ${failed}`)
    if (label === null) return next(e)

    return next({ ...e, props: { ...e.props, modes: [...e.props.modes, label] } })
  })
}
