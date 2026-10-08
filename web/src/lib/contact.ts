import { env } from '@/app/config/env'

/** Enlace a WhatsApp del equipo con un mensaje listo; `null` si no hay número configurado. */
export function supportWhatsappUrl(text: string): string | null {
  if (!env.supportWhatsapp) return null
  return `https://wa.me/51${env.supportWhatsapp}?text=${encodeURIComponent(text)}`
}
