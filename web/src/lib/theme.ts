export type Theme = 'light' | 'dark'

// Misma clave que el script de index.html, que aplica el tema antes del primer pintado.
const storageKey = 'apamuy-theme'
const listeners = new Set<() => void>()

export function currentTheme(): Theme {
  return document.documentElement.classList.contains('dark') ? 'dark' : 'light'
}

export function setTheme(theme: Theme) {
  document.documentElement.classList.toggle('dark', theme === 'dark')
  try {
    localStorage.setItem(storageKey, theme)
  } catch {
    // Sin almacenamiento el tema dura solo esta visita.
  }
  listeners.forEach((listener) => listener())
}

export function subscribeTheme(listener: () => void) {
  listeners.add(listener)
  return () => {
    listeners.delete(listener)
  }
}
