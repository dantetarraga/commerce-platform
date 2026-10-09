import { z } from 'zod'

export const cancelOrderSchema = z.object({
  reason: z
    .string()
    .trim()
    .min(3, 'Explica el motivo: lo verá el cliente.')
    .max(300, 'Máximo 300 caracteres.'),
})
export type CancelOrderValues = z.infer<typeof cancelOrderSchema>

/** Motivos frecuentes para no escribirlos cada vez. */
export const CANCEL_REASONS = [
  'El negocio no contesta',
  'El cliente pidió cancelar',
  'No hay repartidores disponibles',
  'El negocio se quedó sin stock',
] as const
