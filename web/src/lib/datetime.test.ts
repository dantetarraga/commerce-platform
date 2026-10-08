import { describe, expect, it } from 'vitest'
import { formatTime, minutesSince, toApiDate } from './datetime'

describe('datetime (hora de Lima)', () => {
  it('muestra la hora de Lima aunque el instante sea UTC', () => {
    expect(formatTime('2026-10-08T23:33:00Z')).toBe('18:33')
  })

  it('el día de la API es el de Lima, no el de UTC', () => {
    // 02:00 UTC del 9 = 21:00 del 8 en Lima.
    expect(toApiDate('2026-10-09T02:00:00Z')).toBe('2026-10-08')
  })

  it('cuenta minutos enteros y nunca negativos', () => {
    const now = new Date('2026-10-08T12:10:30Z')
    expect(minutesSince('2026-10-08T12:00:00Z', now)).toBe(10)
    expect(minutesSince('2026-10-08T12:20:00Z', now)).toBe(0)
  })
})
