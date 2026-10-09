import { z } from 'zod'
import { soles } from '@/lib/form-schemas'
import { parseSoles } from '@/lib/money'

const km = (label: string) =>
  z
    .number({ error: `Indica ${label} en km.` })
    .min(0.5, 'El mínimo es 0.5 km.')
    .max(50, 'El máximo es 50 km.')

export const citySchema = z.object({
  name: z.string().trim().min(2, 'Escribe el nombre.').max(60, 'Máximo 60 caracteres.'),
  region: z.string().trim().max(60, 'Máximo 60 caracteres.'),
  centerLat: z
    .number({ error: 'Ingresa una latitud válida.' })
    .min(-90, 'Entre -90 y 90.')
    .max(90, 'Entre -90 y 90.'),
  centerLng: z
    .number({ error: 'Ingresa una longitud válida.' })
    .min(-180, 'Entre -180 y 180.')
    .max(180, 'Entre -180 y 180.'),
  coverageKm: km('el radio de la zona'),
  maxDeliveryKm: km('la distancia máxima'),
  baseDeliveryFee: soles,
  feePerKm: soles,
  routeFactor: z
    .number({ error: 'Indica el factor de ruta.' })
    .min(1, 'El mínimo es 1 (línea recta).')
    .max(3, 'El máximo es 3.'),
  avgSpeedKmh: z
    .number({ error: 'Indica la velocidad media.' })
    .int('Usa un número entero.')
    .min(5, 'El mínimo es 5 km/h.')
    .max(80, 'El máximo es 80 km/h.'),
  isActive: z.boolean(),
})
export type CityForm = z.infer<typeof citySchema>

export function cityPayload(values: CityForm, currency: string) {
  return {
    ...values,
    baseDeliveryFee: { amount: parseSoles(values.baseDeliveryFee)!, currency },
    feePerKm: { amount: parseSoles(values.feePerKm)!, currency },
  }
}
