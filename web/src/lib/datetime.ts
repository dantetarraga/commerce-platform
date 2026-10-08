export const APP_TIME_ZONE = 'America/Lima'

const dateTime = new Intl.DateTimeFormat('es-PE', {
  timeZone: APP_TIME_ZONE,
  day: '2-digit',
  month: 'short',
  hour: '2-digit',
  minute: '2-digit',
  hour12: false,
})
const time = new Intl.DateTimeFormat('es-PE', {
  timeZone: APP_TIME_ZONE,
  hour: '2-digit',
  minute: '2-digit',
  hour12: false,
})
const isoDate = new Intl.DateTimeFormat('en-CA', {
  timeZone: APP_TIME_ZONE,
  year: 'numeric',
  month: '2-digit',
  day: '2-digit',
})

/** `2026-10-08T23:33:00Z` → `08 oct., 18:33`. */
export function formatDateTime(value: string | Date): string {
  return dateTime.format(new Date(value))
}

export function formatTime(value: string | Date): string {
  return time.format(new Date(value))
}

/** Día en hora de Lima como lo espera la API (`date=YYYY-MM-DD`). */
export function toApiDate(value: string | Date = new Date()): string {
  return isoDate.format(new Date(value))
}

export function minutesSince(value: string | Date, now: Date = new Date()): number {
  return Math.max(0, Math.floor((now.getTime() - new Date(value).getTime()) / 60_000))
}
