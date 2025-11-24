const envBaseUrl = (import.meta.env.VITE_API_BASE_URL || '').trim()

function deriveDefaultBaseUrl() {
  // When no env is provided, fall back to the current host but the API port (8080 for dev).
  if (typeof window === 'undefined') {
    return 'http://localhost:8080'
  }
  const { protocol, hostname } = window.location
  const defaultPort = protocol === 'https:' ? '8443' : '8080'
  return `${protocol}//${hostname}:${defaultPort}`
}

function normalizeBaseUrl(url) {
  const base = url || deriveDefaultBaseUrl()
  return base.replace(/\/+$/, '')
}

const API_BASE_URL = normalizeBaseUrl(envBaseUrl)

function buildUrl(path = '') {
  if (!path.startsWith('/')) {
    return `${API_BASE_URL}/${path}`
  }
  return `${API_BASE_URL}${path}`
}

export function getApiBaseUrl() {
  return API_BASE_URL
}

export async function apiRequest(path, options = {}) {
  const accessToken = localStorage.getItem('accessToken')
  const headers = {
    'Content-Type': 'application/json',
    ...(options.headers || {}),
  }

  if (accessToken) {
    headers.Authorization = `Bearer ${accessToken}`
  }

  let res
  try {
    res = await fetch(buildUrl(path), {
      ...options,
      headers,
    })
  } catch (err) {
    throw new Error(`Cannot reach API at ${API_BASE_URL} (${err.message})`)
  }

  let data = null
  const isJson = res.headers.get('content-type')?.includes('application/json')

  if (isJson) {
    try {
      data = await res.json()
    } catch (err) {
      data = null
    }
  }

  if (!res.ok) {
    const message = data?.error?.message || data?.error || res.statusText || 'Request failed'
    const error = new Error(message)
    error.status = res.status
    throw error
  }

  return data
}
