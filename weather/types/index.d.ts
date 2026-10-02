/** The footer text, e.g. "Overcast 18°C · Inverness" after its icon; null before the first reading. */
export type WeatherReading = string | null

declare module 'claude-code' {
  interface PluginState {
    weather: { reading: WeatherReading }
  }
}
