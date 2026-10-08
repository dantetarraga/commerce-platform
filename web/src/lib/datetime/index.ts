import { DateFnsAdapter } from './date-fns.adapter'
import type { DateTimeAdapter } from './date-time.adapter'

export const APP_TIME_ZONE = 'America/Lima'

export const dateTime: DateTimeAdapter = new DateFnsAdapter(APP_TIME_ZONE)

export type { DateInput, DateTimeAdapter } from './date-time.adapter'
