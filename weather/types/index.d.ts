/** The footer text, e.g. "Overcast 18°C · Inverness" after its icon; null before the first reading. */
export type WeatherReading = string | null

/** Why the last refresh failed, e.g. "forecast HTTP 503"; null after a good one. */
export type WeatherError = string | null

declare module 'claude-code' {
  interface PluginState {
    weather: { reading: WeatherReading; error: WeatherError }
  }
}
