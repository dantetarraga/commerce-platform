import { describe, expect, it } from 'vitest'
import { DateFnsAdapter } from './date-fns.adapter'
import type { DateTimeAdapter } from './date-time.adapter'

// Toda implementación nueva se agrega aquí y debe pasar el mismo contrato.
const implementations: Array<[string, () => DateTimeAdapter]> = [
  ['date-fns', () => new DateFnsAdapter('America/Lima')],
]

describe.each(implementations)('DateTimeAdapter (%s)', (_name, create) => {
  const dateTime = create()

  it('muestra la hora de Lima aunque el instante venga en UTC', () => {
    expect(dateTime.formatTime('2026-10-08T23:33:00Z')).toBe('18:33')
    expect(dateTime.formatDate('2026-10-09T02:00:00Z')).toBe('08/10/2026')
    expect(dateTime.formatDateTime('2026-10-08T23:33:00Z')).toBe('8 oct 2026, 18:33')
  })

  it('el día de la API es el de Lima, no el de UTC', () => {
    expect(dateTime.toApiDate('2026-10-09T02:00:00Z')).toBe('2026-10-08')
  })

  it('tiempo relativo en español', () => {
    expect(dateTime.formatRelative('2026-10-08T12:00:00Z', '2026-10-08T12:03:00Z')).toBe(
      'hace 3 minutos',
    )
  })

  it('los campos datetime-local van en hora de Lima', () => {
    expect(dateTime.toInputDateTime('2026-10-08T23:30:00Z')).toBe('2026-10-08T18:30')
    expect(dateTime.fromInputDateTime('2026-10-08T18:30')).toBe('2026-10-08T23:30:00.000Z')
  })

  it('días de la API para ejes y rangos', () => {
    expect(dateTime.formatApiDay('2026-10-05')).toBe('lun 5')
    expect(dateTime.shiftApiDate('2026-10-05', -6)).toBe('2026-09-29')
    expect(dateTime.shiftApiDate('2026-12-31', 1)).toBe('2027-01-01')
  })

  it('cuenta minutos enteros y nunca negativos', () => {
    const now = '2026-10-08T12:10:30Z'
    expect(dateTime.minutesSince('2026-10-08T12:00:00Z', now)).toBe(10)
    expect(dateTime.minutesSince('2026-10-08T12:20:00Z', now)).toBe(0)
  })
})
