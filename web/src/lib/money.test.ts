import { describe, expect, it } from 'vitest'
import { formatMoney, parseSoles } from './money'

describe('formatMoney', () => {
  it('formatea céntimos como soles', () => {
    expect(formatMoney({ amount: 13850, currency: 'PEN' })).toBe('S/ 138.50')
    expect(formatMoney({ amount: 0, currency: 'PEN' })).toBe('S/ 0.00')
  })
})

describe('parseSoles', () => {
  it('convierte lo que escribe una persona a céntimos', () => {
    expect(parseSoles('12.5')).toBe(1250)
    expect(parseSoles(' 12,50 ')).toBe(1250)
    expect(parseSoles('0.1')).toBe(10)
  })

  it('rechaza montos inválidos', () => {
    expect(parseSoles('')).toBeNull()
    expect(parseSoles('12.345')).toBeNull()
    expect(parseSoles('-3')).toBeNull()
    expect(parseSoles('abc')).toBeNull()
  })
})
