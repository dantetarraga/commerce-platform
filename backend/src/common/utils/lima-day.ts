// Días en hora de Lima (America/Lima: UTC-5 todo el año, sin horario de verano).
// Los resúmenes y el filtro "hoy" de negocio y repartidor usan este día, no el UTC.

const LIMA_OFFSET_MS = -5 * 60 * 60 * 1000;
const DAY_MS = 24 * 60 * 60 * 1000;

export interface DayRange {
  /** Inicio del día (incluido), en UTC. */
  start: Date;
  /** Inicio del día siguiente (excluido), en UTC. */
  end: Date;
}

/** `YYYY-MM-DD` del día de Lima en que cae `at`. */
export function limaDate(at: Date): string {
  return new Date(at.getTime() + LIMA_OFFSET_MS).toISOString().slice(0, 10);
}

/** Rango UTC del día de Lima `date` (`YYYY-MM-DD`): de 05:00Z a 05:00Z del día siguiente. */
export function limaDayRange(date: string): DayRange {
  const [year, month, day] = date.split('-').map(Number);
  const start = new Date(Date.UTC(year, month - 1, day) - LIMA_OFFSET_MS);
  return { start, end: new Date(start.getTime() + DAY_MS) };
}
