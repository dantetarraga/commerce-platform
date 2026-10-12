import { z } from 'zod'
import { httpsUrl, soles, sortOrderSchema } from '@/lib/form-schemas'
import { parseSoles } from '@/lib/money'
import { timeToMinutes, type Schedule } from '../model/catalog'

export const storeSchema = z.object({
  cityId: z.string().min(1, 'Elige una ciudad.'),
  ownerId: z.string().min(1, 'Busca y selecciona al dueño por su celular.'),
  name: z.string().trim().min(2, 'Escribe el nombre del negocio.').max(80, 'Máximo 80 caracteres.'),
  addressLine: z.string().trim().min(3, 'Escribe la dirección.').max(160, 'Máximo 160 caracteres.'),
  latitude: z
    .number({ error: 'Ingresa una latitud válida.' })
    .min(-90, 'La latitud debe estar entre -90 y 90.')
    .max(90, 'La latitud debe estar entre -90 y 90.'),
  longitude: z
    .number({ error: 'Ingresa una longitud válida.' })
    .min(-180, 'La longitud debe estar entre -180 y 180.')
    .max(180, 'La longitud debe estar entre -180 y 180.'),
  description: z.string().trim().max(500, 'Máximo 500 caracteres.'),
  phone: z
    .string()
    .trim()
    .refine(
      (value) => value === '' || (value.length >= 6 && value.length <= 15),
      'El celular debe tener entre 6 y 15 caracteres.',
    ),
  logoUrl: httpsUrl,
  coverUrl: httpsUrl,
  minOrderAmount: soles,
  avgPrepMinutes: z
    .number({ error: 'Ingresa los minutos de preparación.' })
    .int('Usa minutos enteros.')
    .min(1, 'El mínimo es 1 minuto.')
    .max(180, 'El máximo es 180 minutos.'),
  categoryIds: z.array(z.string()),
})
export type StoreForm = z.infer<typeof storeSchema>

export function storePayload(values: StoreForm, currency: string) {
  return {
    ...values,
    phone: values.phone || null,
    logoUrl: values.logoUrl || null,
    coverUrl: values.coverUrl || null,
    minOrderAmount: { amount: parseSoles(values.minOrderAmount)!, currency },
  }
}

/** Lo que el dueño edita desde el Portal Socios. */
export const storeProfileSchema = storeSchema.pick({
  description: true,
  phone: true,
  logoUrl: true,
  coverUrl: true,
  minOrderAmount: true,
  avgPrepMinutes: true,
})
export type StoreProfileForm = z.infer<typeof storeProfileSchema>

export function storeProfilePayload(values: StoreProfileForm, currency: string) {
  return {
    ...values,
    phone: values.phone || null,
    logoUrl: values.logoUrl || null,
    coverUrl: values.coverUrl || null,
    minOrderAmount: { amount: parseSoles(values.minOrderAmount)!, currency },
  }
}

const childName = z.string().trim().min(1, 'Escribe un nombre.').max(60, 'Máximo 60 caracteres.')

/** "1/4", "Grande": cada una con su precio. */
const variantSchema = z.object({
  id: z.string().optional(),
  name: childName,
  price: soles.refine(
    (value) => (parseSoles(value) ?? 0) > 0,
    'El precio debe ser mayor que cero.',
  ),
  isAvailable: z.boolean(),
})

const optionValueSchema = z.object({
  id: z.string().optional(),
  name: childName,
  /** Lo que suma al precio; vacío: nada. */
  priceDelta: z.union([z.literal(''), soles]),
  isAvailable: z.boolean(),
})

/** "Cremas" (elige hasta 3), "Bebida" (elige 1, obligatorio). */
const optionSchema = z
  .object({
    id: z.string().optional(),
    name: childName,
    minSelect: z.number({ error: 'Usa un número.' }).int().min(0).max(20),
    maxSelect: z.number({ error: 'Usa un número.' }).int().min(1, 'Al menos 1.').max(20),
    values: z
      .array(optionValueSchema)
      .min(1, 'Agrega al menos una opción.')
      .max(30, 'Hasta 30 opciones.'),
  })
  .refine((o) => o.minSelect <= o.maxSelect, {
    message: 'El mínimo no puede ser mayor que el máximo.',
    path: ['minSelect'],
  })
  .refine((o) => o.maxSelect <= o.values.length, {
    message: 'Hay menos opciones que el máximo a elegir.',
    path: ['maxSelect'],
  })

export const productSchema = z.object({
  name: z
    .string()
    .trim()
    .min(2, 'Escribe el nombre del producto.')
    .max(80, 'Máximo 80 caracteres.'),
  description: z.string().trim().max(500, 'Máximo 500 caracteres.'),
  imageUrl: httpsUrl,
  basePrice: soles,
  menuSectionId: z.string(),
  stock: z
    .string()
    .refine(
      (value) => value === '' || (/^\d+$/.test(value) && Number(value) <= 2147483647),
      'Ingresa un stock entero, sin decimales.',
    ),
  sortOrder: sortOrderSchema,
  isAvailable: z.boolean(),
  isFeatured: z.boolean(),
  isLocal: z.boolean(),
  variants: z.array(variantSchema).max(20, 'Hasta 20 variantes.'),
  options: z.array(optionSchema).max(20, 'Hasta 20 grupos de opciones.'),
})
export type ProductForm = z.infer<typeof productSchema>

/**
 * Manda variantes y opciones completas: las que traen `id` se editan, las nuevas se
 * crean y las que faltan se borran. Con variantes, el precio base es el más bajo.
 */
export function productPayload(values: ProductForm, currency: string) {
  const money = (value: string) => ({ amount: parseSoles(value) ?? 0, currency })
  const variants = values.variants.map((v, i) => ({
    ...(v.id && { id: v.id }),
    name: v.name,
    price: money(v.price),
    isAvailable: v.isAvailable,
    sortOrder: i,
  }))
  const lowest = variants.length
    ? Math.min(...variants.map((v) => v.price.amount))
    : parseSoles(values.basePrice)!
  return {
    ...values,
    imageUrl: values.imageUrl || null,
    menuSectionId: values.menuSectionId || null,
    stock: values.stock === '' ? null : Number(values.stock),
    basePrice: { amount: lowest, currency },
    variants,
    options: values.options.map((o, i) => ({
      ...(o.id && { id: o.id }),
      name: o.name,
      minSelect: o.minSelect,
      maxSelect: o.maxSelect,
      sortOrder: i,
      values: o.values.map((value, j) => ({
        ...(value.id && { id: value.id }),
        name: value.name,
        priceDelta: money(value.priceDelta || '0'),
        isAvailable: value.isAvailable,
        sortOrder: j,
      })),
    })),
  }
}

export const categorySchema = z.object({
  name: z.string().trim().min(2, 'Escribe un nombre.').max(40, 'Máximo 40 caracteres.'),
  iconUrl: httpsUrl,
})
export type CategoryForm = z.infer<typeof categorySchema>
export const sectionSchema = z.object({
  name: z.string().trim().min(1, 'Escribe un nombre.').max(60, 'Máximo 60 caracteres.'),
  sortOrder: sortOrderSchema,
})
export type SectionForm = z.infer<typeof sectionSchema>

const time = z.string().regex(/^([01]\d|2[0-3]):[0-5]\d$/, 'Usa el formato HH:mm.')
export const scheduleSchema = z.object({
  schedules: z
    .array(
      z
        .object({
          dayOfWeek: z.number().int().min(0).max(6),
          opensAt: time,
          closesAt: z.union([time, z.literal('24:00')], {
            error: 'Usa el formato HH:mm, hasta 24:00.',
          }),
        })
        .refine((value) => value.opensAt !== value.closesAt, {
          message: 'El turno debe abrir y cerrar a horas distintas.',
          path: ['closesAt'],
        }),
    )
    .max(28, 'Puedes registrar hasta 28 turnos.'),
})
export type ScheduleForm = z.infer<typeof scheduleSchema>

export function schedulesPayload(values: ScheduleForm): Schedule[] {
  return values.schedules.map((value) => ({
    dayOfWeek: value.dayOfWeek,
    opensAt: timeToMinutes(value.opensAt),
    closesAt: value.closesAt === '00:00' ? 1440 : timeToMinutes(value.closesAt),
  }))
}
