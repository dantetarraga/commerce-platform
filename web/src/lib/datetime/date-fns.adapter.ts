import { TZDate } from '@date-fns/tz'
import { differenceInMinutes, format, formatDistanceStrict, type Locale } from 'date-fns'
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

  #zoned(value: DateInput) {
    return new TZDate(new Date(value), this.timeZone)
  }

  #format(value: DateInput, pattern: string) {
    return format(this.#zoned(value), pattern, { locale: this.#locale })
  }
}
