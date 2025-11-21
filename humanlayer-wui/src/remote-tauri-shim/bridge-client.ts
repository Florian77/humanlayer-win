const DEFAULT_BRIDGE_URL = (import.meta.env.VITE_TAURI_BRIDGE_URL as string) || 'http://localhost:17650'

type HttpMethod = 'GET' | 'POST'

async function parseJSON(response: Response) {
  const text = await response.text()
  if (!text) return null
  try {
    return JSON.parse(text)
  } catch {
    return text
  }
}

export async function bridgeRequest<T = any>(
  path: string,
  options: {
    method?: HttpMethod
    query?: Record<string, string | number | boolean | undefined>
    body?: any
  } = {},
): Promise<T> {
  const method = options.method || 'GET'
  const base = DEFAULT_BRIDGE_URL.replace(/\/$/, '')
  const query = options.query
    ? '?' +
      Object.entries(options.query)
        .filter(([, v]) => v !== undefined)
        .map(([k, v]) => `${encodeURIComponent(k)}=${encodeURIComponent(String(v))}`)
        .join('&')
    : ''

  const url = `${base}${path}${query}`

  const resp = await fetch(url, {
    method,
    headers: {
      'Content-Type': 'application/json',
    },
    body: method === 'POST' ? JSON.stringify(options.body || {}) : undefined,
  })

  if (!resp.ok) {
    const msg = await resp.text()
    throw new Error(`Bridge request failed (${resp.status}): ${msg || url}`)
  }

  const data = await parseJSON(resp)
  return data as T
}

export function getBridgeBaseUrl() {
  return DEFAULT_BRIDGE_URL
}
