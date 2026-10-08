import { OrderStatus } from '../../generated/prisma/enums';
import { groupBoard } from './merchant-board';

describe('groupBoard', () => {
  it('reparte por estado en el orden de llegada y cuenta cada columna', () => {
    const board = groupBoard([
      { id: 'a', status: OrderStatus.RECEIVED },
      { id: 'b', status: OrderStatus.PREPARING },
      { id: 'c', status: OrderStatus.RECEIVED },
      { id: 'd', status: OrderStatus.ON_THE_WAY },
      { id: 'e', status: OrderStatus.CONFIRMED },
      { id: 'f', status: OrderStatus.DELIVERED },
    ]);
    expect(board.map((c) => [c.key, c.count, c.items.map((o) => o.id)])).toEqual([
      ['fresh', 2, ['a', 'c']],
      ['cooking', 2, ['b', 'e']],
      ['ready', 1, ['d']],
    ]);
  });

  it('sin pedidos, las tres columnas vacías', () => {
    expect(groupBoard([])).toEqual([
      { key: 'fresh', count: 0, items: [] },
      { key: 'cooking', count: 0, items: [] },
      { key: 'ready', count: 0, items: [] },
    ]);
  });
});
