import { z } from 'zod'
import { dateTime } from '@/lib/datetime'
import { soles, sortOrderSchema } from '@/lib/form-schemas'
import { parseSoles } from '@/lib/money'

const CURRENCY = 'PEN'
const toMoney = (value: string) => ({ amount: parseSoles(value)!, currency: CURRENCY })

const dateTimeInput = z.string().regex(/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}$/, 'Elige fecha y hora.')

const period = <T extends { startsAt: string; endsAt: string }>(value: T, ctx: z.RefinementCtx) => {
  if (value.endsAt <= value.startsAt) {
    ctx.addIssue({
      code: 'custom',
      path: ['endsAt'],
      message: 'La fecha de fin debe ser posterior al inicio.',
    })
  }
}

export const couponSchema = z
  .object({
    code: z
      .string()
      .trim()
      .regex(/^[A-Za-z0-9]{3,20}$/, 'Usa de 3 a 20 letras o números, sin espacios.'),
    label: z.string().trim().min(3, 'Mínimo 3 caracteres.').max(60, 'Máximo 60 caracteres.'),
    description: z.string().trim().max(200, 'Máximo 200 caracteres.'),
    type: z.enum(['PERCENTAGE', 'FIXED_AMOUNT', 'FREE_DELIVERY']),
    percentOff: z.string(),
    amountOff: z.string(),
    maxDiscount: z.string(),
    minOrderAmount: soles,
    cityId: z.string(),
    storeId: z.string(),
    startsAt: dateTimeInput,
    endsAt: dateTimeInput,
    usageLimit: z
      .string()
      .refine(
        (value) => value === '' || /^[1-9]\d*$/.test(value),
        'Usa un número entero mayor a 0.',
      ),
    perUserLimit: z
      .number({ error: 'Indica cuántas veces puede usarlo cada cliente.' })
      .int('Usa un número entero.')
      .min(1, 'Mínimo 1.')
      .max(100, 'Máximo 100.'),
    firstOrderOnly: z.boolean(),
    isActive: z.boolean(),
  })
  .superRefine((value, ctx) => {
    period(value, ctx)
    const issue = (path: string, message: string) =>
      ctx.addIssue({ code: 'custom', path: [path], message })
    if (value.type === 'PERCENTAGE') {
      const percent = Number(value.percentOff)
      if (!Number.isInteger(percent) || percent < 1 || percent > 100) {
        issue('percentOff', 'Indica un porcentaje entero entre 1 y 100.')
      }
      if (value.maxDiscount !== '' && parseSoles(value.maxDiscount) === null) {
        issue('maxDiscount', 'Ingresa un monto válido con hasta 2 decimales.')
      }
    }
    if (value.type === 'FIXED_AMOUNT' && !parseSoles(value.amountOff)) {
      issue('amountOff', 'Indica cuánto descuenta, mayor a S/ 0.')
    }
  })
export type CouponForm = z.infer<typeof couponSchema>

export function couponPayload(values: CouponForm) {
  return {
    code: values.code.toUpperCase(),
    label: values.label,
    description: values.description,
    type: values.type,
    percentOff: values.type === 'PERCENTAGE' ? Number(values.percentOff) : undefined,
    amountOff: values.type === 'FIXED_AMOUNT' ? toMoney(values.amountOff) : undefined,
    maxDiscount:
      values.type === 'PERCENTAGE' && values.maxDiscount ? toMoney(values.maxDiscount) : null,
    minOrderAmount: toMoney(values.minOrderAmount),
    cityId: values.cityId || null,
    storeId: values.storeId || null,
    startsAt: dateTime.fromInputDateTime(values.startsAt),
    endsAt: dateTime.fromInputDateTime(values.endsAt),
    usageLimit: values.usageLimit ? Number(values.usageLimit) : null,
    perUserLimit: values.perUserLimit,
    firstOrderOnly: values.firstOrderOnly,
    isActive: values.isActive,
  }
}

export const promotionSchema = z
  .object({
    cityId: z.string().min(1, 'Elige la ciudad donde se muestra.'),
    storeId: z.string(),
    couponId: z.string(),
    title: z.string().trim().min(3, 'Mínimo 3 caracteres.').max(60, 'Máximo 60 caracteres.'),
    subtitle: z.string().trim().max(120, 'Máximo 120 caracteres.'),
    imageUrl: z.url({ protocol: /^https$/, error: 'Ingresa la URL https de la imagen.' }),
    startsAt: dateTimeInput,
    endsAt: dateTimeInput,
    sortOrder: sortOrderSchema,
    isActive: z.boolean(),
  })
  .superRefine(period)
export type PromotionForm = z.infer<typeof promotionSchema>

export function promotionPayload(values: PromotionForm) {
  return {
    ...values,
    storeId: values.storeId || null,
    couponId: values.couponId || null,
    startsAt: dateTime.fromInputDateTime(values.startsAt),
    endsAt: dateTime.fromInputDateTime(values.endsAt),
  }
}
