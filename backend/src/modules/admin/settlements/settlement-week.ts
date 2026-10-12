const DAY_MS = 24 * 60 * 60 * 1000;
const toUtc = (date: string) => Date.parse(`${date}T00:00:00Z`);
const fromUtc = (ms: number) => new Date(ms).toISOString().slice(0, 10);

export const addDays = (date: string, days: number) => fromUtc(toUtc(date) + days * DAY_MS);

/** Lunes (`AAAA-MM-DD`) de la semana del día `date`. Las semanas van de lunes a domingo. */
export function weekStartOf(date: string): string {
  const dayOfWeek = new Date(toUtc(date)).getUTCDay();
  return addDays(date, -((dayOfWeek + 6) % 7));
}

export interface SettlementWeek {
  start: string;
  /** Domingo, incluido. */
  end: string;
  previous: string;
  next: string;
}

export function settlementWeek(date: string): SettlementWeek {
  const start = weekStartOf(date);
  return { start, end: addDays(start, 6), previous: addDays(start, -7), next: addDays(start, 7) };
}

/** `@db.Date` llega como medianoche UTC. */
export const weekStartDate = (start: string) => new Date(`${start}T00:00:00Z`);
export const weekStartString = (date: Date) => date.toISOString().slice(0, 10);
