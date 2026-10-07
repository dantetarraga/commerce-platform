import { LuxonZonedTime } from './luxon-zoned-time';
import { ZonedTime } from './zoned-time';

export type { DayRange, LocalTime, ZonedTime } from './zoned-time';

/** Zona de las ciudades sin una propia (`City.timezone` tiene el mismo default). */
export const DEFAULT_TIMEZONE = 'America/Lima';

/** Para cambiar de librería, cambia solo esta línea. */
export const zonedTime: ZonedTime = new LuxonZonedTime();
