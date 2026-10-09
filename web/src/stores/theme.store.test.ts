import { describe, expect, it } from 'vitest'
import { themeStore } from './theme.store'

describe('themeStore', () => {
  it('cambia la clase del documento y guarda el tema en texto plano para index.html', () => {
    themeStore.getState().actions.setTheme('light')

    themeStore.getState().actions.toggleTheme()

    expect(themeStore.getState().theme).toBe('dark')
    expect(document.documentElement.classList.contains('dark')).toBe(true)
    expect(localStorage.getItem('apamuy-theme')).toBe('dark')
  })
})
