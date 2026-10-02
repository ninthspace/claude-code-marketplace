// WMO weather interpretation codes, as Open-Meteo reports them.
const CODES: Record<number, [string, string]> = {
  0: ['Clear', '☀️'], 1: ['Mainly clear', '🌤️'], 2: ['Partly cloudy', '⛅'], 3: ['Overcast', '☁️'],
  45: ['Fog', '🌫️'], 48: ['Rime fog', '🌫️'],
  51: ['Light drizzle', '🌦️'], 53: ['Drizzle', '🌦️'], 55: ['Heavy drizzle', '🌧️'], 56: ['Freezing drizzle', '🌧️'], 57: ['Freezing drizzle', '🌧️'],
  61: ['Light rain', '🌦️'], 63: ['Rain', '🌧️'], 65: ['Heavy rain', '🌧️'], 66: ['Freezing rain', '🌧️'], 67: ['Freezing rain', '🌧️'],
  71: ['Light snow', '🌨️'], 73: ['Snow', '🌨️'], 75: ['Heavy snow', '❄️'], 77: ['Snow grains', '🌨️'],
  80: ['Showers', '🌦️'], 81: ['Heavy showers', '🌧️'], 82: ['Violent showers', '⛈️'], 85: ['Snow showers', '🌨️'], 86: ['Snow showers', '🌨️'],
  95: ['Thunderstorm', '⛈️'], 96: ['Thunder and hail', '⛈️'], 99: ['Thunder and hail', '⛈️'],
}

/** "Inverness, GB" → name and country code for the geocoding search. */
export function parseLocation(raw: string): { name: string; countryCode?: string } {
  const match = /^(.*?),\s*([A-Za-z]{2})\s*$/.exec(raw.trim())

  return match?.[1] !== undefined && match[2] !== undefined
    ? { name: match[1].trim(), countryCode: match[2].toUpperCase() }
    : { name: raw.trim() }
}

export function geocodeUrl(raw: string): string {
  const { name, countryCode } = parseLocation(raw)
  const country = countryCode === undefined ? '' : `&countryCode=${countryCode}`

  return `https://geocoding-api.open-meteo.com/v1/search?name=${encodeURIComponent(name)}&count=1&language=en&format=json${country}`
}

export function forecastUrl(latitude: number, longitude: number): string {
  return `https://api.open-meteo.com/v1/forecast?latitude=${latitude}&longitude=${longitude}&current=temperature_2m,weather_code,is_day&timezone=auto`
}

export function statusText(place: string, temperature: number, code: number, isDay: boolean): string {
  const [label, icon] = CODES[code] ?? ['Unknown', '❔']
  const shown = !isDay && (code === 0 || code === 1) ? '🌙' : icon

  return `${shown} ${label} ${Math.round(temperature)}°C · ${place}`
}
