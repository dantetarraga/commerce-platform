import { describe, expect, it } from 'vitest'
import { minutesToTime, timeToMinutes } from '../model/catalog'
import { productPayload, productSchema, scheduleSchema } from './catalog.schemas'

const product = {
  name: 'Sopa de quinua',
  description: '',
  imageUrl: '',
  basePrice: '12,50',
  menuSectionId: '',
  stock: '',
  sortOrder: 0,
  isAvailable: true,
  isFeatured: false,
  isLocal: true,
}

describe('Formulario del catálogo', () => {
  it('envía céntimos y conserva las variantes al editar datos básicos', () => {
    const payload = productPayload(productSchema.parse(product), 'PEN')
    expect(payload.basePrice).toEqual({ amount: 1250, currency: 'PEN' })
    expect(payload).not.toHaveProperty('variants')
    expect(payload).not.toHaveProperty('options')
    expect(payload.menuSectionId).toBeNull()
    expect(payload.imageUrl).toBeNull()
  })

  it('distingue stock sin límite de producto agotado', () => {
    expect(productPayload(product, 'PEN').stock).toBeNull()
    expect(productPayload({ ...product, stock: '0' }, 'PEN').stock).toBe(0)
    expect(productSchema.safeParse({ ...product, stock: '-1' }).success).toBe(false)
    expect(productSchema.safeParse({ ...product, stock: '1.5' }).success).toBe(false)
  })

  it.each(['-5', '1.234', 'NaN', '999999999999999999'])('rechaza el importe %s', (basePrice) => {
    expect(productSchema.safeParse({ ...product, basePrice }).success).toBe(false)
  })

  it('admite medianoche y turnos nocturnos sin convertirlos por la zona del navegador', () => {
    expect(minutesToTime(1440)).toBe('24:00')
    expect(timeToMinutes('24:00')).toBe(1440)
    expect(timeToMinutes('02:30')).toBe(150)
    expect(
      scheduleSchema.safeParse({
        schedules: [{ dayOfWeek: 6, opensAt: '22:00', closesAt: '02:30' }],
      }).success,
    ).toBe(true)
    expect(
      scheduleSchema.safeParse({
        schedules: [{ dayOfWeek: 0, opensAt: '00:00', closesAt: '24:00' }],
      }).success,
    ).toBe(true)
  })

  it('rechaza horas inválidas y turnos de duración cero', () => {
    for (const closesAt of ['25:00', '20:70', '09:00']) {
      expect(
        scheduleSchema.safeParse({ schedules: [{ dayOfWeek: 1, opensAt: '09:00', closesAt }] })
          .success,
      ).toBe(false)
    }
  })
})
