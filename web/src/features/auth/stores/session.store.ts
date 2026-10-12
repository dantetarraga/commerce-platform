import { createStore, useStore } from 'zustand'
import { createJSONStorage, devtools, persist } from 'zustand/middleware'
import type { SessionTokens } from '../model/auth'
import type { SessionUser } from '../model/user'

export type SessionStatus = 'unknown' | 'anonymous' | 'authenticated'

interface SessionData {
  status: SessionStatus
  accessToken: string | null
  user: SessionUser | null
  /** Hay una cookie de sesión que vale la pena renovar (la cookie no se puede leer). */
  hasSession: boolean
  /** Refresh token que guardaba la versión anterior en localStorage; se canjea una vez por la cookie. */
  legacyRefreshToken: string | null
}

interface SessionActions {
  setTokens: (tokens: SessionTokens) => void
  setUser: (user: SessionUser) => void
  clear: () => void
}

export type SessionState = SessionData & { actions: SessionActions }

export const SESSION_STORAGE_KEY = 'apamuy.panel.session'

const initialState: SessionData = {
  status: 'unknown',
  accessToken: null,
  user: null,
  hasSession: false,
  legacyRefreshToken: null,
}

/**
 * Store vanilla: lo leen también el router y los interceptores, fuera de React.
 * El access token vive solo en memoria y el refresh token en una cookie httpOnly
 * que pone la API; aquí solo se recuerda si hay sesión.
 */
export const sessionStore = createStore<SessionState>()(
  devtools(
    persist(
      (set) => ({
        ...initialState,
        actions: {
          setTokens: ({ accessToken }) =>
            set({ accessToken, hasSession: true, legacyRefreshToken: null }),
          setUser: (user) => set({ user, status: 'authenticated' }),
          clear: () => set({ ...initialState, status: 'anonymous' }),
        },
      }),
      {
        name: SESSION_STORAGE_KEY,
        version: 2,
        storage: createJSONStorage(() => localStorage),
        partialize: ({ hasSession, legacyRefreshToken }) => ({ hasSession, legacyRefreshToken }),
        migrate: (persisted, version) => {
          if (version < 2) {
            const { refreshToken } = (persisted ?? {}) as { refreshToken?: string | null }
            return { hasSession: Boolean(refreshToken), legacyRefreshToken: refreshToken ?? null }
          }
          return persisted as Pick<SessionData, 'hasSession' | 'legacyRefreshToken'>
        },
      },
    ),
    { name: 'session', enabled: import.meta.env.DEV },
  ),
)

export function useSessionStore<T>(selector: (state: SessionState) => T): T {
  return useStore(sessionStore, selector)
}

export const useSessionStatus = () => useSessionStore((state) => state.status)

/** Si otra pestaña cerró sesión, esta también (la cookie es la misma para todas). */
export function syncSessionAcrossTabs(): () => void {
  const handleStorage = (event: StorageEvent) => {
    if (event.key !== SESSION_STORAGE_KEY) return
    void Promise.resolve(sessionStore.persist.rehydrate()).then(() => {
      const { hasSession, status, actions } = sessionStore.getState()
      if (!hasSession && status !== 'anonymous') actions.clear()
    })
  }
  window.addEventListener('storage', handleStorage)
  return () => window.removeEventListener('storage', handleStorage)
}
