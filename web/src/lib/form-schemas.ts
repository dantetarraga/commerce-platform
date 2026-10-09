import { z } from 'zod'
import { parseSoles } from './money'

export const nationalPhone = z
  .string()
  .transform((value) => value.replace(/[\s-]/g, ''))
  .pipe(z.string().regex(/^9\d{8}$/, 'Ingresa un celular de 9 dígitos que empiece con 9.'))
export const httpsUrl = z.union(
  [z.literal(''), z.url({ protocol: /^https$/, error: 'Ingresa una URL https válida.' })],
  { error: 'Ingresa una URL https válida.' },
)
export const sortOrderSchema = z
  .number({ error: 'Ingresa un número de orden.' })
  .int('El orden debe ser entero.')
  .min(0, 'El orden no puede ser negativo.')
  .max(2147483647, 'El orden es demasiado grande.')
export const soles = z.string().refine((value) => {
  const amount = parseSoles(value)
  return amount !== null && Number.isSafeInteger(amount) && amount <= 2147483647
}, 'Ingresa un monto válido con hasta 2 decimales.')
