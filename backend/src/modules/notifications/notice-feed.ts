import { NoticeKind } from './order-notices';

/** Pestañas del centro de avisos. */
export const NOTICE_FILTERS = ['all', 'orders', 'offers'] as const;
export type NoticeFilter = (typeof NOTICE_FILTERS)[number];

export type NoticeDay = 'TODAY' | 'YESTERDAY' | 'EARLIER';

/** Lo que el feed necesita de un aviso ya proyectado al JSON de la app. */
export interface FeedNotice {
  id: string;
  kind: string;
  at: string;
  orderId: string | null;
}

const isOrder = (n: FeedNotice) => n.kind !== NoticeKind.PROMOTION;
const closesOrder = (n: FeedNotice) => n.kind === NoticeKind.DELIVERED || n.kind === NoticeKind.ORDER_CANCELLED;

/**
 * Avisos del pedido en curso (antiguo → reciente) para mostrarlos como un
 * hilo; vacío si hay menos de dos. Los sin `orderId` cuentan como un pedido.
 */
export function activeOrderThread<T extends FeedNotice>(notices: readonly T[]): T[] {
  const byOrder = new Map<string | null, T[]>();
  for (const n of notices.filter(isOrder)) byOrder.set(n.orderId, [...(byOrder.get(n.orderId) ?? []), n]);
  let latest: T[] | null = null;
  for (const group of byOrder.values()) {
    group.sort((a, b) => a.at.localeCompare(b.at));
    const last = group[group.length - 1];
    if (closesOrder(last)) continue;
    if (!latest || last.at > latest[latest.length - 1].at) latest = group;
  }
  if (!latest || latest.length < 2) return [];
  // Solo el tramo desde el último cierre (un pedido anterior sin orderId).
  let start = 0;
  latest.forEach((n, i) => {
    if (closesOrder(n)) start = i + 1;
  });
  const thread = latest.slice(start);
  return thread.length < 2 ? [] : thread;
}

/**
 * El centro de avisos armado: el hilo del pedido en curso (salvo en Ofertas) y
 * el resto del filtro agrupado por día, del más reciente al más antiguo.
 * [dayOf] da el día local (`YYYY-MM-DD`) de un instante ISO.
 */
export function buildNoticeFeed<T extends FeedNotice>(
  notices: readonly T[],
  filter: NoticeFilter,
  today: string,
  yesterday: string,
  dayOf: (at: string) => string,
) {
  const thread = filter === 'offers' ? [] : activeOrderThread(notices);
  const inThread = new Set(thread.map((n) => n.id));
  const accepts = (n: T) => filter === 'all' || (filter === 'orders' ? isOrder(n) : !isOrder(n));
  const rest = notices.filter((n) => !inThread.has(n.id) && accepts(n)).sort((a, b) => b.at.localeCompare(a.at));

  const groups: { day: NoticeDay; items: T[] }[] = [];
  for (const n of rest) {
    const date = dayOf(n.at);
    const day: NoticeDay = date === today ? 'TODAY' : date === yesterday ? 'YESTERDAY' : 'EARLIER';
    const last = groups[groups.length - 1];
    if (last?.day === day) last.items.push(n);
    else groups.push({ day, items: [n] });
  }
  return { thread, groups };
}
