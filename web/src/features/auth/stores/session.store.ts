import { createStore, useStore } from 'zustand'
import { createJSONStorage, devtools, persist } from 'zustand/middleware'
import type { SessionTokens } from '../model/auth'
import type { SessionUser } from '../model/user'

export type SessionStatus = 'unknown' | 'anonymous' | 'authenticated'

interface SessionData {
  status: SessionStatus
  accessToken: string | null
  refreshToken: string | null
  user: SessionUser | null
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
  refreshToken: null,
  user: null,
}

/**
 * Store vanilla: lo leen también el router y los interceptores, fuera de React.
 * Access token solo en memoria. El refresh token se persiste en localStorage de forma
 * interina, hasta que el backend lo entregue en una cookie httpOnly (docs/PANEL_WEB.md §9).
 */
export const sessionStore = createStore<SessionState>()(
  devtools(
    persist(
      (set) => ({
        ...initialState,
        actions: {
          setTokens: ({ accessToken, refreshToken }) => set({ accessToken, refreshToken }),
          setUser: (user) => set({ user, status: 'authenticated' }),
          clear: () => set({ ...initialState, status: 'anonymous' }),
        },
      }),
      {
        name: SESSION_STORAGE_KEY,
        version: 1,
        storage: createJSONStorage(() => localStorage),
        partialize: ({ refreshToken }) => ({ refreshToken }),
      },
    ),
    { name: 'session', enabled: import.meta.env.DEV },
  ),
)

export function useSessionStore<T>(selector: (state: SessionState) => T): T {
  return useStore(sessionStore, selector)
}

export const useSessionStatus = () => useSessionStore((state) => state.status)

/**
 * El backend rota el refresh token en cada uso y, si ve uno ya usado, cierra la sesión
 * en todos lados. Por eso cada pestaña adopta el token que guardó otra, y si otra cerró
 * sesión, esta también.
 */
export function syncSessionAcrossTabs(): () => void {
  const handleStorage = (event: StorageEvent) => {
    if (event.key !== SESSION_STORAGE_KEY) return
    void Promise.resolve(sessionStore.persist.rehydrate()).then(() => {
      const { refreshToken, status, actions } = sessionStore.getState()
      if (!refreshToken && status !== 'anonymous') actions.clear()
    })
  }
  window.addEventListener('storage', handleStorage)
  return () => window.removeEventListener('storage', handleStorage)
}
