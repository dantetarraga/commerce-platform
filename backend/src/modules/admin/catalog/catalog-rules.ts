import { HttpStatus } from '@nestjs/common';
import { AppException, ErrorCode } from '../../../common/exceptions/app.exception';
import type { OpeningHours } from '../../../common/utils/schedule';

const DAY_MINUTES = 1440;

/** "Pollería Don Julián" → "polleria-don-julian". */
export function slugify(name: string): string {
  return name
    .normalize('NFD')
    .replace(/[̀-ͯ]/g, '')
    .toLowerCase()
    .replace(/[^a-z0-9]+/g, '-')
    .replace(/^-+|-+$/g, '')
    .slice(0, 60);
}

/** El primer slug libre: `base`, `base-2`, `base-3`… */
export function freeSlug(base: string, taken: ReadonlySet<string>): string {
  if (!taken.has(base)) return base;
  let n = 2;
  while (taken.has(`${base}-${n}`)) n++;
  return `${base}-${n}`;
}

/** Errores por campo con la misma forma que la validación (`details.fields`). */
export function invalid(fields: Record<string, string>): AppException {
  return new AppException(ErrorCode.VALIDATION_ERROR, HttpStatus.BAD_REQUEST, 'Revisa los datos enviados.', {
    fields,
  });
}

/** Tramos `[inicio, fin)` en minutos de la semana; un turno que cruza la medianoche sigue el día siguiente. */
function weekSpans(h: OpeningHours): [number, number][] {
  const start = h.dayOfWeek * DAY_MINUTES + h.opensAt;
  const end = h.dayOfWeek * DAY_MINUTES + (h.closesAt > h.opensAt ? h.closesAt : h.closesAt + DAY_MINUTES);
  const week = 7 * DAY_MINUTES;
  return end <= week
    ? [[start, end]]
    : [
        [start, week],
        [0, end - week],
      ];
}

/** Rangos válidos y sin turnos que se pisen (también los que cruzan la medianoche). */
export function scheduleErrors(hours: readonly OpeningHours[]): Record<string, string> {
  const errors: Record<string, string> = {};
  hours.forEach((h, i) => {
    if (h.opensAt === h.closesAt) errors[`schedules.${i}`] = 'El turno debe abrir y cerrar a horas distintas.';
  });
  if (Object.keys(errors).length) return errors;

  const spans = hours.flatMap((h, i) => weekSpans(h).map(([start, end]) => ({ i, start, end })));
  spans.sort((a, b) => a.start - b.start || a.end - b.end);
  let reach = { i: -1, end: 0 };
  for (const span of spans) {
    if (span.start < reach.end && span.i !== reach.i) errors[`schedules.${span.i}`] = 'Este turno se cruza con otro.';
    if (span.end > reach.end) reach = span;
  }
  return errors;
}

export interface OptionRules {
  name: string;
  minSelect: number;
  maxSelect: number;
  values: readonly unknown[];
}

/** Cada grupo debe poder cumplirse: mínimo ≤ máximo ≤ cantidad de valores. */
export function optionErrors(options: readonly OptionRules[]): Record<string, string> {
  const errors: Record<string, string> = {};
  options.forEach((o, i) => {
    if (o.minSelect > o.maxSelect) errors[`options.${i}.minSelect`] = 'El mínimo no puede ser mayor que el máximo.';
    else if (o.maxSelect > o.values.length)
      errors[`options.${i}.maxSelect`] = `"${o.name}" tiene menos valores que el máximo a elegir.`;
  });
  return errors;
}

/**
 * Qué hacer con hijos editados en bloque (variantes, opciones, valores): los que
 * traen `id` se actualizan, los nuevos se crean y los que faltan se borran.
 * Mantener los ids evita invalidar las bolsas guardadas en los teléfonos.
 */
export function syncPlan<T extends { id?: string }>(current: readonly string[], incoming: readonly T[]) {
  const known = new Set(current);
  const unknown = incoming.filter((item) => item.id !== undefined && !known.has(item.id));
  const kept = new Set(incoming.flatMap((item) => (item.id ? [item.id] : [])));
  return {
    unknownIds: unknown.map((item) => item.id!),
    update: incoming.filter((item): item is T & { id: string } => item.id !== undefined && known.has(item.id)),
    create: incoming.filter((item) => item.id === undefined),
    remove: current.filter((id) => !kept.has(id)),
  };
}
