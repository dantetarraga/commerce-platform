import { renderHook } from '@testing-library/react'
import { afterEach, describe, expect, it, vi } from 'vitest'
import { useAttentionAlert } from './use-attention-alert'

describe('useAttentionAlert', () => {
  afterEach(() => {
    vi.unstubAllGlobals()
  })

  it('pone la cuenta en el título y la quita al resolverse', () => {
    document.title = 'Pedidos · Apamuy'
    const message = (n: number) => `${n} atrasados`
    const { rerender, unmount } = renderHook(({ count }) => useAttentionAlert(count, message), {
      initialProps: { count: 0 },
    })
    expect(document.title).toBe('Pedidos · Apamuy')

    rerender({ count: 2 })
    expect(document.title).toBe('(2) Pedidos · Apamuy')

    rerender({ count: 0 })
    expect(document.title).toBe('Pedidos · Apamuy')
    unmount()
  })

  it('con la pestaña de fondo y permiso, avisa solo cuando sube', () => {
    const notices: string[] = []
    class FakeNotification {
      static permission = 'granted'
      onclick: (() => void) | null = null
      constructor(_title: string, options: { body: string }) {
        notices.push(options.body)
      }
    }
    vi.stubGlobal('Notification', FakeNotification)
    vi.spyOn(document, 'hidden', 'get').mockReturnValue(true)
    const message = (n: number) => `${n} atrasados`
    const { rerender } = renderHook(({ count }) => useAttentionAlert(count, message), {
      initialProps: { count: 0 },
    })

    rerender({ count: 1 })
    rerender({ count: 1 })
    rerender({ count: 0 })
    rerender({ count: 2 })

    expect(notices).toEqual(['1 atrasados', '2 atrasados'])
  })
})
