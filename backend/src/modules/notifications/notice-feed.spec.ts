import { activeOrderThread, buildNoticeFeed, FeedNotice } from './notice-feed';

const n = (id: string, kind: string, at: string, orderId: string | null = 'o1'): FeedNotice => ({
  id,
  kind,
  at,
  orderId,
});
const dayOf = (at: string) => at.slice(0, 10);

describe('activeOrderThread', () => {
  it('el hilo es el pedido en curso más reciente, de antiguo a reciente', () => {
    const thread = activeOrderThread([
      n('a', 'ORDER_CONFIRMED', '2026-10-08T10:00:00Z'),
      n('b', 'PREPARING', '2026-10-08T10:05:00Z'),
      n('c', 'ORDER_CONFIRMED', '2026-10-07T09:00:00Z', 'o0'),
      n('d', 'DELIVERED', '2026-10-07T09:30:00Z', 'o0'),
    ]);
    expect(thread.map((x) => x.id)).toEqual(['a', 'b']);
  });

  it('sin pedido en curso o con un solo aviso no hay hilo', () => {
    expect(activeOrderThread([n('a', 'ORDER_CONFIRMED', '2026-10-08T10:00:00Z')])).toEqual([]);
    expect(
      activeOrderThread([n('a', 'PREPARING', '2026-10-08T10:00:00Z'), n('b', 'DELIVERED', '2026-10-08T10:30:00Z')]),
    ).toEqual([]);
  });
});

describe('buildNoticeFeed', () => {
  const notices = [
    n('a', 'ORDER_CONFIRMED', '2026-10-08T10:00:00Z'),
    n('b', 'PREPARING', '2026-10-08T10:05:00Z'),
    n('p1', 'PROMOTION', '2026-10-08T08:00:00Z', null),
    n('p2', 'PROMOTION', '2026-10-07T08:00:00Z', null),
    n('old', 'DELIVERED', '2026-10-01T08:00:00Z', 'o0'),
  ];

  it('separa el hilo y agrupa el resto por día, del más reciente al más antiguo', () => {
    const feed = buildNoticeFeed(notices, 'all', '2026-10-08', '2026-10-07', dayOf);
    expect(feed.thread.map((x) => x.id)).toEqual(['a', 'b']);
    expect(feed.groups.map((g) => [g.day, g.items.map((x) => x.id)])).toEqual([
      ['TODAY', ['p1']],
      ['YESTERDAY', ['p2']],
      ['EARLIER', ['old']],
    ]);
  });

  it('Ofertas no trae el hilo; Pedidos no trae promociones', () => {
    const offers = buildNoticeFeed(notices, 'offers', '2026-10-08', '2026-10-07', dayOf);
    expect(offers.thread).toEqual([]);
    expect(offers.groups.flatMap((g) => g.items.map((x) => x.id))).toEqual(['p1', 'p2']);
    const orders = buildNoticeFeed(notices, 'orders', '2026-10-08', '2026-10-07', dayOf);
    expect(orders.groups.flatMap((g) => g.items.map((x) => x.id))).toEqual(['old']);
  });
});
