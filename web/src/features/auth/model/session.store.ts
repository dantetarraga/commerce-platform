import { create } from 'zustand'
import { createJSONStorage, persist } from 'zustand/middleware'
import type { SessionTokens } from '../api/auth.api'
import type { SessionUser } from './user'

export type SessionStatus = 'unknown' | 'anonymous' | 'authenticated'

interface SessionState {
  status: SessionStatus
  accessToken: string | null
  refreshToken: string | null
  user: SessionUser | null
  setTokens: (tokens: SessionTokens) => void
  setUser: (user: SessionUser) => void
  clear: () => void
}

/**
 * Access token solo en memoria. El refresh token se persiste en localStorage de forma
 * interina, hasta que el backend lo entregue en una cookie httpOnly (docs/PANEL_WEB.md §9).
 */
export const useSessionStore = create<SessionState>()(
  persist(
    (set) => ({
      status: 'unknown',
      accessToken: null,
      refreshToken: null,
      user: null,
      setTokens: ({ accessToken, refreshToken }) => set({ accessToken, refreshToken }),
      setUser: (user) => set({ user, status: 'authenticated' }),
      clear: () => set({ status: 'anonymous', accessToken: null, refreshToken: null, user: null }),
    }),
    {
      name: 'apamuy.panel.session',
      version: 1,
      storage: createJSONStorage(() => localStorage),
      partialize: ({ refreshToken }) => ({ refreshToken }),
    },
  ),
)
