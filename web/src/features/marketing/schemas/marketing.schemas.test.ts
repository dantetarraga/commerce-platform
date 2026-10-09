import { describe, expect, it } from 'vitest'
import { couponPayload, couponSchema, type CouponForm } from './marketing.schemas'

const base: CouponForm = {
  code: 'bienvenida',
  label: 'S/ 5 de bienvenida',
  description: '',
  type: 'FIXED_AMOUNT',
  percentOff: '',
  amountOff: '5',
  maxDiscount: '',
  minOrderAmount: '20',
  cityId: '',
  storeId: '',
  startsAt: '2026-10-08T09:00',
  endsAt: '2026-11-08T23:59',
  usageLimit: '',
  perUserLimit: 1,
  firstOrderOnly: true,
  isActive: true,
}

describe('couponSchema', () => {
  it('pide el porcentaje solo en cupones de porcentaje', () => {
    const result = couponSchema.safeParse({ ...base, type: 'PERCENTAGE', percentOff: '' })
    expect(result.success).toBe(false)
    expect(result.error?.issues[0].path).toEqual(['percentOff'])
    expect(couponSchema.safeParse({ ...base, type: 'FREE_DELIVERY', amountOff: '' }).success).toBe(
      true,
    )
  })

  it('el fin debe ser posterior al inicio', () => {
    const result = couponSchema.safeParse({ ...base, endsAt: '2026-10-08T08:00' })
    expect(result.error?.issues[0].path).toEqual(['endsAt'])
  })
})

describe('couponPayload', () => {
  it('manda solo el descuento de su tipo, en céntimos y con fechas de Lima en UTC', () => {
    expect(couponPayload(base)).toMatchObject({
      code: 'BIENVENIDA',
      amountOff: { amount: 500, currency: 'PEN' },
      percentOff: undefined,
      maxDiscount: null,
      minOrderAmount: { amount: 2000, currency: 'PEN' },
      cityId: null,
      usageLimit: null,
      startsAt: '2026-10-08T14:00:00.000Z',
    })
  })

  it('un porcentaje puede llevar tope', () => {
    expect(
      couponPayload({ ...base, type: 'PERCENTAGE', percentOff: '15', maxDiscount: '10' }),
    ).toMatchObject({ percentOff: 15, amountOff: undefined, maxDiscount: { amount: 1000 } })
  })
})
