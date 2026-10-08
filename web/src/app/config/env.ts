import { z } from 'zod'

const schema = z.object({
  VITE_API_URL: z.string().min(1).default('/api/v1'),
  VITE_WS_URL: z.string().min(1).default('/ws'),
  VITE_GOOGLE_MAPS_API_KEY: z.string().default(''),
  // Celular de contacto (9 dígitos, sin +51). Vacío: la landing no ofrece WhatsApp.
  VITE_SUPPORT_WHATSAPP: z
    .string()
    .regex(/^(\d{9})?$/, 'Debe tener 9 dígitos')
    .default(''),
})

const parsed = schema.safeParse(import.meta.env)
if (!parsed.success) {
  throw new Error(`Variables de entorno inválidas: ${z.prettifyError(parsed.error)}`)
}

export const env = {
  apiUrl: parsed.data.VITE_API_URL,
  wsUrl: parsed.data.VITE_WS_URL,
  googleMapsApiKey: parsed.data.VITE_GOOGLE_MAPS_API_KEY,
  supportWhatsapp: parsed.data.VITE_SUPPORT_WHATSAPP,
} as const
