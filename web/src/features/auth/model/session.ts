import { ApiError } from '@/api'
import { fetchMe, logout, refreshTokens, type AuthResponse } from '../api/auth.api'
import { useSessionStore } from './session.store'
import { panelHomeFor } from './user'

const store = useSessionStore

let refreshing: Promise<string> | null = null
let restoring: Promise<void> | null = null

/** Una sola renovación a la vez: el backend rota el refresh token en cada uso. */
export function refreshAccessToken(): Promise<string> {
  refreshing ??= (async () => {
    const refreshToken = store.getState().refreshToken
    if (!refreshToken) {
      throw new ApiError(401, 'INVALID_REFRESH_TOKEN', 'Tu sesión terminó. Vuelve a ingresar.')
    }
    try {
      const tokens = await refreshTokens(refreshToken)
      store.getState().setTokens(tokens)
      return tokens.accessToken
    } catch (error) {
      if (error instanceof ApiError && error.isUnauthorized) store.getState().clear()
      throw error
    }
  })().finally(() => {
    refreshing = null
  })
  return refreshing
}

function revokeQuietly() {
  const { refreshToken, clear } = store.getState()
  clear()
  if (refreshToken) logout(refreshToken).catch(() => undefined)
}

/** Recupera la sesión guardada. Sin conexión lanza el error y deja `unknown` para reintentar. */
export function restoreSession(): Promise<void> {
  if (store.getState().status !== 'unknown') return Promise.resolve()

  restoring ??= (async () => {
    const { refreshToken, accessToken, clear, setUser } = store.getState()
    if (!refreshToken) return clear()
    try {
      if (!accessToken) await refreshAccessToken()
      const user = await fetchMe()
      if (panelHomeFor(user)) setUser(user)
      else revokeQuietly()
    } catch (error) {
      if (error instanceof ApiError && error.isUnauthorized) return clear()
      throw error
    }
  })().finally(() => {
    restoring = null
  })
  return restoring
}

export function signIn({ user, ...tokens }: AuthResponse): boolean {
  store.getState().setTokens(tokens)
  if (!panelHomeFor(user)) {
    revokeQuietly()
    return false
  }
  store.getState().setUser(user)
  return true
}

export function signOut() {
  revokeQuietly()
}

export function getCurrentUser() {
  return store.getState().user
}
