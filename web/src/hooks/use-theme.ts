import { useSyncExternalStore } from 'react'
import { currentTheme, setTheme, subscribeTheme } from '@/lib/theme'

export function useTheme() {
  const theme = useSyncExternalStore(subscribeTheme, currentTheme)
  const toggleTheme = () => setTheme(theme === 'dark' ? 'light' : 'dark')
  return { theme, toggleTheme }
}
