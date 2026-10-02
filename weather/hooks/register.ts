import { atom, read, update } from 'claude-code'
import type { EngineInterface, Register } from 'claude-code'

import { forecastUrl, geocodeUrl, statusText } from './weather'

const REFRESH_MS = 15 * 60 * 1000

const reading = atom({ plugin: 'weather', key: 'reading' } as const, null)

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

async function refresh($: EngineInterface, location: string) {
  try {
    const place = await findPlace($, location)
    if (place === null) {
      await update($, reading, () => `no place called ${location}`)
      return
    }
    const response = await $.http.fetch(forecastUrl(place.latitude, place.longitude))
    if (!response.ok) return
    const { current } = JSON.parse(response.text) as {
      current: { temperature_2m: number; weather_code: number; is_day: number }
    }
    const text = statusText(place.name, current.temperature_2m, current.weather_code, current.is_day === 1)
    await update($, reading, () => text)
  } catch {
    // Offline or a bad reply: keep the last reading on screen and try again at the next refresh.
  }
}

export const register: Register = (on, options) => {
  const location = String(options.location ?? 'Inverness, GB')

  on('session.start', async ($, e, next) => {
    // A status entry pinned by an earlier load outlives a reload; this mod draws in the footer instead.
    $.ui.status(undefined)
    // Not awaited: a slow network must not hold up the session's first prompt.
    void refresh($, location)
    $.clock.every(REFRESH_MS, () => void refresh($, location))

    return next(e)
  })

  // Drawn as one of the footer's mode labels, at its right-hand end.
  on('ui.render', { component: 'SessionMode' }, async ($, e, next) => {
    const text = await read($, reading)
    if (text === null) return next(e)

    return next({ ...e, props: { ...e.props, modes: [...e.props.modes, text] } })
  })
}
