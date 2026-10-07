import { HttpStatus, Injectable } from '@nestjs/common';
import { AppException, ErrorCode } from '../../common/exceptions/app.exception';
import { DEFAULT_TIMEZONE, zonedTime } from '../../common/time';
import { money } from '../../common/utils/money';
import { PrismaService } from '../../database/prisma.service';
import { CourierStatus, OrderStatus } from '../../generated/prisma/enums';
import { OrderStatusService } from '../orders/status/order-status.service';
import { sumCollected } from './courier-summary';

/** Lo que el repartidor puede elegir; BUSY lo pone el sistema al tomar un pedido. */
export type CourierToggle = typeof CourierStatus.AVAILABLE | typeof CourierStatus.OFFLINE;

/** Perfil, disponibilidad y resumen del día del repartidor. */
@Injectable()
export class CouriersService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly status: OrderStatusService,
  ) {}

  /** `Courier` del contrato: perfil, vehículo, estado y pedido en curso. */
  async me(userId: string) {
    const courier = await this.prisma.courier.findUnique({
      where: { userId },
      include: { user: { select: { firstName: true, lastName: true, phone: true } } },
    });
    if (!courier) throw AppException.notFound('No tienes perfil de repartidor.');
    return {
      id: courier.id,
      name: `${courier.user.firstName} ${courier.user.lastName}`.trim(),
      phone: courier.user.phone,
      vehicleLabel: courier.vehicleLabel,
      status: courier.status,
      activeOrderId: await this.status.activeOrderId(courier.id),
    };
  }

  /**
   * Conectarse o desconectarse. Con un pedido en curso sigue BUSY: no puede
   * desconectarse (409) y "conectarse" no cambia nada. El update es
   * condicional sobre "no BUSY" para no pisar un `accept` simultáneo.
   */
  async setStatus(userId: string, status: CourierToggle) {
    const courier = await this.status.courierFor(userId);
    const hasActiveOrder = async () => (await this.status.activeOrderId(courier.id)) !== null;
    const activeOrderError = () =>
      new AppException(
        ErrorCode.COURIER_HAS_ACTIVE_ORDER,
        HttpStatus.CONFLICT,
        'Termina tu entrega antes de desconectarte.',
      );

    if (status === CourierStatus.OFFLINE && (await hasActiveOrder())) throw activeOrderError();

    const { count } = await this.prisma.courier.updateMany({
      where: { id: courier.id, status: { not: CourierStatus.BUSY } },
      data: { status },
    });
    if (count === 0) {
      // Estaba BUSY. Con pedido en curso, manda el pedido; si no, era un BUSY colgado.
      if (await hasActiveOrder()) {
        if (status === CourierStatus.OFFLINE) throw activeOrderError();
      } else {
        await this.prisma.courier.update({ where: { id: courier.id }, data: { status } });
      }
    }
    return this.me(userId);
  }

  /** Entregas de ese día (hora local) y lo cobrado, por método. */
  async summary(userId: string, date: string | undefined, now = new Date()) {
    const courier = await this.status.courierFor(userId);
    const day = date ?? zonedTime.localDate(now, DEFAULT_TIMEZONE);
    const { start, end } = zonedTime.dayRange(day, DEFAULT_TIMEZONE);
    const orders = await this.prisma.order.findMany({
      where: { courierId: courier.id, status: OrderStatus.DELIVERED, deliveredAt: { gte: start, lt: end } },
      select: { payment: { select: { collectedMethod: true, collectedAmount: true } } },
    });
    const totals = sumCollected(orders.flatMap((o) => (o.payment ? [o.payment] : [])));
    return {
      date: day,
      deliveredCount: orders.length,
      collected: {
        total: money(totals.total),
        CASH: money(totals.CASH),
        YAPE: money(totals.YAPE),
        PLIN: money(totals.PLIN),
      },
    };
  }
}
