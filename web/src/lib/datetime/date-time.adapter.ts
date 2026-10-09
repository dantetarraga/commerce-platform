export type DateInput = string | number | Date

/**
 * Contrato de fechas del panel. Las pantallas solo conocen esta interfaz:
 * cambiar de librería es escribir otra implementación y cambiarla en index.ts.
 */
export interface DateTimeAdapter {
  readonly timeZone: string
  /** 08/10/2026 */
  formatDate: (value: DateInput) => string
  /** 18:33 */
  formatTime: (value: DateInput) => string
  /** 8 oct 2026, 18:33 */
  formatDateTime: (value: DateInput) => string
  /** hace 3 minutos */
  formatRelative: (value: DateInput, now?: DateInput) => string
  /** Día en la zona horaria del panel, como lo espera la API: 2026-10-08 */
  toApiDate: (value?: DateInput) => string
  minutesSince: (value: DateInput, now?: DateInput) => number
  /** Día de la API (2026-10-06) para un eje o una lista: lun 6 */
  formatApiDay: (apiDate: string) => string
  /** Suma días a un día de la API: (2026-10-06, -6) → 2026-09-30 */
  shiftApiDate: (apiDate: string, days: number) => string
  /** Valor de un `<input type="datetime-local">` en la zona del panel: 2026-10-08T18:30 */
  toInputDateTime: (value: DateInput) => string
  /** Lo que escribió el usuario en un `datetime-local`, como instante (ISO 8601). */
  fromInputDateTime: (value: string) => string
}
