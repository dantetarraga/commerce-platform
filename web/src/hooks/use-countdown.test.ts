import { act, renderHook } from '@testing-library/react'
import { afterEach, beforeEach, describe, expect, it, vi } from 'vitest'
import { useCountdown } from './use-countdown'

beforeEach(() => vi.useFakeTimers())
afterEach(() => vi.useRealTimers())

describe('useCountdown', () => {
  it('cuenta hacia atrás hasta cero', () => {
    const { result } = renderHook(() => useCountdown())

    act(() => result.current.start(2))
    expect(result.current).toMatchObject({ seconds: 2, isRunning: true })

    act(() => vi.advanceTimersByTime(1000))
    expect(result.current.seconds).toBe(1)

    act(() => vi.advanceTimersByTime(1000))
    expect(result.current).toMatchObject({ seconds: 0, isRunning: false })
  })
})
