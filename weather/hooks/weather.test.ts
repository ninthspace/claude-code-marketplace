import { expect, test } from 'claude-code/testing'

import { forecastUrl, geocodeUrl, parseLocation, statusText } from './weather'

test('a trailing two-letter code is the country', () => {
  expect(parseLocation('Inverness, gb')).toEqual({ name: 'Inverness', countryCode: 'GB' })
  expect(parseLocation('Fort William')).toEqual({ name: 'Fort William' })
})

test('urls carry the name, country and coordinates', () => {
  expect(geocodeUrl('Fort William, GB')).toContain('name=Fort%20William&count=1&language=en&format=json&countryCode=GB')
  expect(forecastUrl(57.47908, -4.22398)).toContain('latitude=57.47908&longitude=-4.22398&current=temperature_2m,weather_code,is_day')
})

test('status line text', () => {
  expect(statusText('Inverness', 17.5, 3, true)).toBe('☁️ Overcast 18°C · Inverness')
  expect(statusText('Inverness', 9.2, 0, false)).toBe('🌙 Clear 9°C · Inverness')
  expect(statusText('Inverness', 9, 42, true)).toBe('❔ Unknown 9°C · Inverness')
})
