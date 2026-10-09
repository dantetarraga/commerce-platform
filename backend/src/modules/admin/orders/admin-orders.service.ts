import { Injectable } from '@nestjs/common';
import { DEFAULT_TIMEZONE, zonedTime } from '../../../common/time';
import { money } from '../../../common/utils/money';
import { PrismaService } from '../../../database/prisma.service';
import { Prisma } from '../../../generated/prisma/client';
import { OrderStatus, Role } from '../../../generated/prisma/enums';
import { FINAL_STATUSES } from '../../orders/order-list-scope';
import { orderInclude } from '../../orders/order-presenter';
import { OrdersService } from '../../orders/orders.service';
import { OrderStatusService } from '../../orders/status/order-status.service';
import { groupAdminBoard, toAdminOrder } from './admin-order-presenter';
import { AdminOrdersQueryDto } from './admin-orders.dto';

/** Tope del tablero: pedidos en curso de todas las ciudades a la vez. */
const BOARD_LIMIT = 300;

/** Pedidos de todas las ciudades para el equipo de operación. */
@Injectable()
export class AdminOrdersService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly orders: OrdersService,
    private readonly status: OrderStatusService,
  ) {}

  /** Pedidos en curso por columna, los que esperan respuesta y el resumen de hoy. */
  async board(cityId: string | undefined, now = new Date()) {
    const city = cityId ? { cityId } : {};
    const active = await this.prisma.order.findMany({
      where: { ...city, status: { notIn: FINAL_STATUSES } },
      orderBy: { createdAt: 'asc' },
      take: BOARD_LIMIT,
      include: orderInclude,
    });
    const items = active.map((order) => toAdminOrder(order, now));
    const { start, end } = zonedTime.dayRange(zonedTime.localDate(now, DEFAULT_TIMEZONE), DEFAULT_TIMEZONE);
    const today = await this.prisma.order.groupBy({
      by: ['status'],
      where: { ...city, createdAt: { gte: start, lt: end } },
      _count: { _all: true },
      _sum: { total: true },
    });
    const count = (status: OrderStatus) => today.find((row) => row.status === status)?._count._all ?? 0;
    return {
      generatedAt: now.toISOString(),
      columns: groupAdminBoard(items),
      lateCount: items.filter((order) => order.alert).length,
      today: {
        placed: today.reduce((sum, row) => sum + row._count._all, 0),
        delivered: count(OrderStatus.DELIVERED),
        cancelled: count(OrderStatus.CANCELLED),
        sales: money(today.find((row) => row.status === OrderStatus.DELIVERED)?._sum.total ?? 0),
      },
    };
  }

  /** Historial de un día, con filtros; el más reciente primero. */
  async list(query: AdminOrdersQueryDto, now = new Date()) {
    const date = query.date ?? zonedTime.localDate(now, DEFAULT_TIMEZONE);
    const { start, end } = zonedTime.dayRange(date, DEFAULT_TIMEZONE);
    const search = query.q?.trim().replace(/^#/, '');
    const where: Prisma.OrderWhereInput = {
      createdAt: { gte: start, lt: end },
      ...(query.cityId && { cityId: query.cityId }),
      ...(query.status && { status: query.status }),
      ...(search && {
        OR: [{ code: { contains: search } }, { customer: { phone: { contains: search } } }],
      }),
    };
    const { orders, nextCursor } = await this.orders.page(where, query);
    return { items: orders.map((order) => toAdminOrder(order, now)), nextCursor };
  }

  async detail(userId: string, orderId: string) {
    return toAdminOrder(await this.status.find({ userId, role: Role.ADMIN }, orderId), new Date());
  }

  /** El admin puede cancelar hasta que el pedido sale en camino. */
  async cancel(userId: string, orderId: string, reason: string) {
    return toAdminOrder(await this.status.cancel({ userId, role: Role.ADMIN }, orderId, reason), new Date());
  }
}
