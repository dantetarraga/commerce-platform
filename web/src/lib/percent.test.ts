import { describe, expect, it } from 'vitest'
import { formatRate, parsePercent } from './percent'

describe('formatRate', () => {
  it('muestra los puntos básicos como porcentaje', () => {
    expect(formatRate(1000)).toBe('10 %')
    expect(formatRate(1250)).toBe('12.5 %')
    expect(formatRate(0)).toBe('0 %')
  })
})

describe('parsePercent', () => {
  it('convierte el porcentaje escrito a puntos básicos', () => {
    expect(parsePercent('10')).toBe(1000)
    expect(parsePercent(' 12,5 % ')).toBe(1250)
    expect(parsePercent('0')).toBe(0)
    expect(parsePercent('100')).toBe(10_000)
  })

  it('rechaza lo que no es un porcentaje válido', () => {
    expect(parsePercent('')).toBeNull()
    expect(parsePercent('101')).toBeNull()
    expect(parsePercent('-5')).toBeNull()
    expect(parsePercent('10.123')).toBeNull()
  })
})
