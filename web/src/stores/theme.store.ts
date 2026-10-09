import { createStore, useStore } from 'zustand'

export type Theme = 'light' | 'dark'

// Misma clave y formato (texto plano) que el script de index.html, que aplica el tema antes
// del primer pintado. Por eso no se usa el middleware persist, que guarda JSON.
const STORAGE_KEY = 'apamuy-theme'

interface ThemeState {
  theme: Theme
  actions: {
    setTheme: (theme: Theme) => void
    toggleTheme: () => void
  }
}

export const themeStore = createStore<ThemeState>()((set, get) => ({
  theme: document.documentElement.classList.contains('dark') ? 'dark' : 'light',
  actions: {
    setTheme: (theme) => {
      document.documentElement.classList.toggle('dark', theme === 'dark')
      try {
        localStorage.setItem(STORAGE_KEY, theme)
      } catch {
        // Sin almacenamiento el tema dura solo esta visita.
      }
      set({ theme })
    },
    toggleTheme: () => get().actions.setTheme(get().theme === 'dark' ? 'light' : 'dark'),
  },
}))

export const useTheme = () => useStore(themeStore, (state) => state.theme)
export const useThemeActions = () => useStore(themeStore, (state) => state.actions)
