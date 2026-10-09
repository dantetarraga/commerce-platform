import { dateTime } from '@/lib/datetime'

/** Rango de un reporte: días `AAAA-MM-DD`, ambos incluidos. */
export interface DateRange {
  from: string
  to: string
}

/** "+12 %", "−5 %" o `null` si no hay base para comparar. */
export function changeLabel(current: number, previous: number): string | null {
  if (previous === 0) return null
  const change = Math.round(((current - previous) / previous) * 100)
  if (change === 0) return 'igual'
  return `${change > 0 ? '+' : '−'}${Math.abs(change)} %`
}

/** "18 h". */
export const hourLabel = (hour: number) => `${hour} h`

/** Los últimos [days] días, hoy incluido. */
export function lastDays(days: number): DateRange {
  const to = dateTime.toApiDate()
  return { from: dateTime.shiftApiDate(to, -(days - 1)), to }
}
