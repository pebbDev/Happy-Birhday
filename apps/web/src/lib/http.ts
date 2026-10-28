/** Generic HTTP helper. Do not use it to bypass Fastify access checks. */
export async function httpRequest<T>(path: string, init?: RequestInit): Promise<T> {
  const configuredBase = import.meta.env.VITE_API_BASE_URL
  if (!configuredBase) throw new Error('VITE_API_BASE_URL is not configured')
  const base = configuredBase.replace(/\/$/, '')
  const url = `${base}/${path.replace(/^\//, '')}`
  const response = await fetch(url, { credentials: 'include', ...init })
  if (!response.ok) throw new Error(`Request failed (${response.status})`)
  return response.json() as Promise<T>
}
