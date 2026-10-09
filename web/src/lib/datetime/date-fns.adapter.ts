import { TZDate } from '@date-fns/tz'
import { addDays, differenceInMinutes, format, formatDistanceStrict, type Locale } from 'date-fns'
import { es } from 'date-fns/locale'
import type { DateInput, DateTimeAdapter } from './date-time.adapter'

export class DateFnsAdapter implements DateTimeAdapter {
  readonly timeZone: string
  readonly #locale: Locale

  constructor(timeZone: string, locale: Locale = es) {
    this.timeZone = timeZone
    this.#locale = locale
  }

  formatDate(value: DateInput) {
    return this.#format(value, 'dd/MM/yyyy')
  }

  formatTime(value: DateInput) {
    return this.#format(value, 'HH:mm')
  }

  formatDateTime(value: DateInput) {
    return this.#format(value, 'd MMM yyyy, HH:mm')
  }

  formatRelative(value: DateInput, now: DateInput = new Date()) {
    return formatDistanceStrict(new Date(value), new Date(now), {
      addSuffix: true,
      locale: this.#locale,
    })
  }

  toApiDate(value: DateInput = new Date()) {
    return format(this.#zoned(value), 'yyyy-MM-dd')
  }

  minutesSince(value: DateInput, now: DateInput = new Date()) {
    return Math.max(0, differenceInMinutes(new Date(now), new Date(value)))
  }

  formatApiDay(apiDate: string) {
    return format(this.#apiDay(apiDate), 'EEE d', { locale: this.#locale })
  }

  shiftApiDate(apiDate: string, days: number) {
    return format(addDays(this.#apiDay(apiDate), days), 'yyyy-MM-dd')
  }

  toInputDateTime(value: DateInput) {
    return format(this.#zoned(value), "yyyy-MM-dd'T'HH:mm")
  }

  fromInputDateTime(value: string) {
    const match = /^(\d{4})-(\d{2})-(\d{2})T(\d{2}):(\d{2})$/.exec(value)
    if (!match) throw new RangeError(`Fecha inválida: ${value}`)
    const [year, month, day, hours, minutes] = match.slice(1).map(Number)
    // TZDate.toISOString() conserva el desfase; new Date lo normaliza a UTC.
    return new Date(+new TZDate(year, month - 1, day, hours, minutes, this.timeZone)).toISOString()
  }

  /** Mediodía de ese día en la zona del panel: ningún desfase lo cambia de día. */
  #apiDay(apiDate: string) {
    const [year, month, day] = apiDate.split('-').map(Number)
    return new TZDate(year, month - 1, day, 12, 0, this.timeZone)
  }

  #zoned(value: DateInput) {
    return new TZDate(new Date(value), this.timeZone)
  }

  #format(value: DateInput, pattern: string) {
    return format(this.#zoned(value), pattern, { locale: this.#locale })
  }
}
