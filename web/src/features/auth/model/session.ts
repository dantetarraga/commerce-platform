import { ApiError } from '@/app/api'
import { fetchMe, logout, refreshTokens } from '../actions/auth.actions'
import type { AuthResponse } from './auth'
import { sessionStore } from '../stores/session.store'
import { panelHomeFor } from './user'

const session = () => sessionStore.getState()

let refreshing: Promise<string> | null = null
let restoring: Promise<void> | null = null

/** Serializa la renovación entre pestañas; sin Web Locks, solo dentro de esta. */
function withRefreshLock<T>(task: () => Promise<T>): Promise<T> {
  if (typeof navigator !== 'undefined' && 'locks' in navigator) {
    return navigator.locks.request('apamuy.panel.refresh', task)
  }
  return task()
}

/** Una sola renovación a la vez: el backend rota el refresh token en cada uso. */
export function refreshAccessToken(): Promise<string> {
  refreshing ??= withRefreshLock(async () => {
    // Otra pestaña pudo haberlo rotado mientras esperábamos el lock.
    await sessionStore.persist.rehydrate()
    const refreshToken = session().refreshToken
    if (!refreshToken) {
      throw new ApiError(401, 'INVALID_REFRESH_TOKEN', 'Tu sesión terminó. Vuelve a ingresar.')
    }
    try {
      const tokens = await refreshTokens(refreshToken)
      session().actions.setTokens(tokens)
      return tokens.accessToken
    } catch (error) {
      if (error instanceof ApiError && error.isUnauthorized) session().actions.clear()
      throw error
    }
  }).finally(() => {
    refreshing = null
  })
  return refreshing
}

function revokeQuietly() {
  const { refreshToken, actions } = session()
  actions.clear()
  if (refreshToken) logout(refreshToken).catch(() => undefined)
}

/** Recupera la sesión guardada. Sin conexión lanza el error y deja `unknown` para reintentar. */
export function restoreSession(): Promise<void> {
  if (session().status !== 'unknown') return Promise.resolve()

  restoring ??= (async () => {
    const { refreshToken, accessToken, actions } = session()
    if (!refreshToken) return actions.clear()
    try {
      if (!accessToken) await refreshAccessToken()
      const user = await fetchMe()
      if (panelHomeFor(user)) actions.setUser(user)
      else revokeQuietly()
    } catch (error) {
      if (error instanceof ApiError && error.isUnauthorized) return session().actions.clear()
      throw error
    }
  })().finally(() => {
    restoring = null
  })
  return restoring
}

export function signIn({ user, ...tokens }: AuthResponse): boolean {
  session().actions.setTokens(tokens)
  if (!panelHomeFor(user)) {
    revokeQuietly()
    return false
  }
  session().actions.setUser(user)
  return true
}

export function signOut() {
  revokeQuietly()
}

export function getCurrentUser() {
  return session().user
}

export function getAccessToken() {
  return session().accessToken
}

export function hasRefreshToken() {
  return session().refreshToken !== null
}
