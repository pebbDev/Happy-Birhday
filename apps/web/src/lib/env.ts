// Only public browser-side values may be read through import.meta.env.
export const appEnv = {
  apiBaseUrl: import.meta.env.VITE_API_BASE_URL ?? '',
} as const