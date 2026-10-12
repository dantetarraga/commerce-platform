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
  variants: [],
  options: [],
}

describe('Formulario del catálogo', () => {
  it('envía céntimos y las listas completas de variantes y opciones', () => {
    const payload = productPayload(productSchema.parse(product), 'PEN')
    expect(payload.basePrice).toEqual({ amount: 1250, currency: 'PEN' })
    expect(payload.variants).toEqual([])
    expect(payload.options).toEqual([])
    expect(payload.menuSectionId).toBeNull()
    expect(payload.imageUrl).toBeNull()
  })

  it('con variantes conserva sus ids y el precio base es el más bajo', () => {
    const payload = productPayload(
      productSchema.parse({
        ...product,
        variants: [
          { id: 'v1', name: '1/2', price: '35', isAvailable: true },
          { name: '1/4', price: '18,50', isAvailable: true },
        ],
        options: [
          {
            id: 'o1',
            name: 'Cremas',
            minSelect: 0,
            maxSelect: 2,
            values: [
              { id: 'ov1', name: 'Mayonesa', priceDelta: '', isAvailable: true },
              { name: 'Ají', priceDelta: '0,50', isAvailable: false },
            ],
          },
        ],
      }),
      'PEN',
    )
    expect(payload.basePrice.amount).toBe(1850)
    expect(payload.variants).toEqual([
      {
        id: 'v1',
        name: '1/2',
        price: { amount: 3500, currency: 'PEN' },
        isAvailable: true,
        sortOrder: 0,
      },
      { name: '1/4', price: { amount: 1850, currency: 'PEN' }, isAvailable: true, sortOrder: 1 },
    ])
    expect(payload.options[0].values.map((v) => v.priceDelta.amount)).toEqual([0, 50])
    expect(payload.options[0]).toMatchObject({ id: 'o1', minSelect: 0, maxSelect: 2 })
  })

  it('valida los grupos de opciones como el backend', () => {
    const option = (minSelect: number, maxSelect: number) => ({
      name: 'Bebida',
      minSelect,
      maxSelect,
      values: [{ name: 'Chicha', priceDelta: '', isAvailable: true }],
    })
    expect(productSchema.safeParse({ ...product, options: [option(1, 1)] }).success).toBe(true)
    expect(productSchema.safeParse({ ...product, options: [option(2, 1)] }).success).toBe(false)
    expect(productSchema.safeParse({ ...product, options: [option(0, 2)] }).success).toBe(false)
    const free = { name: 'Gratis', price: '0', isAvailable: true }
    expect(productSchema.safeParse({ ...product, variants: [free] }).success).toBe(false)
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
