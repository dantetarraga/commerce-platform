import { HttpStatus, Injectable } from '@nestjs/common';
import { AppException, ErrorCode } from '../../../common/exceptions/app.exception';
import { PrismaService } from '../../../database/prisma.service';
import { Prisma } from '../../../generated/prisma/client';
import { OrderStatus, PaymentStatus, Role } from '../../../generated/prisma/enums';
import { orderInclude, OrderWithDetails } from '../order-presenter';
import { canTransition } from './order-status.machine';

/** Quién actúa y con qué rol (el de la ruta: cliente, negocio, courier o admin). */
export interface OrderActor {
  userId: string;
  role: Role;
}

const ORDER_NOT_FOUND = 'No encontramos ese pedido.';

/** Pedidos que el actor puede ver y tocar. Uno ajeno responde 404. */
export function scopeFor(actor: OrderActor): Prisma.OrderWhereInput {
  switch (actor.role) {
    case Role.CUSTOMER:
      return { customerId: actor.userId };
    case Role.MERCHANT:
      return { store: { ownerId: actor.userId } };
    case Role.COURIER:
      return { courier: { userId: actor.userId } };
    case Role.ADMIN:
      return {};
  }
}

/**
 * Cambios de estado del pedido. Cada uno va en una transacción, con update
 * condicional sobre el estado actual (dos personas no avanzan el mismo pedido
 * a la vez), historial y sus efectos: cobrar al entregar, restaurar stock y
 * cupón al cancelar.
 */
@Injectable()
export class OrderStatusService {
  constructor(private readonly prisma: PrismaService) {}

  async find(actor: OrderActor, orderId: string): Promise<OrderWithDetails> {
    const order = await this.prisma.order.findFirst({
      where: { id: orderId, ...scopeFor(actor) },
      include: orderInclude,
    });
    if (!order) throw AppException.notFound(ORDER_NOT_FOUND);
    return order;
  }

  async advance(actor: OrderActor, orderId: string, to: OrderStatus, note?: string): Promise<OrderWithDetails> {
    const order = await this.find(actor, orderId);
    if (to === OrderStatus.CANCELLED || !canTransition(order.status, to, actor.role)) {
      throw invalidTransition(order.status, to);
    }
    await this.prisma.$transaction(async (tx) => {
      const data = to === OrderStatus.DELIVERED ? { deliveredAt: new Date() } : {};
      await this.move(tx, actor, order.id, order.status, to, note, data);
      if (to === OrderStatus.DELIVERED) {
        await tx.payment.updateMany({ where: { orderId: order.id }, data: { status: PaymentStatus.PAID } });
        await tx.store.update({ where: { id: order.storeId }, data: { popularityScore: { increment: 1 } } });
      }
    });
    return this.find(actor, orderId);
  }

  /**
   * El courier toma un pedido listo de su ciudad. Condicional: si dos
   * repartidores aceptan a la vez, solo uno se lo lleva.
   */
  async courierFor(userId: string) {
    const courier = await this.prisma.courier.findUnique({ where: { userId } });
    if (!courier) throw AppException.notFound('No tienes perfil de repartidor.');
    return courier;
  }

  async accept(courierUserId: string, orderId: string): Promise<OrderWithDetails> {
    const courier = await this.courierFor(courierUserId);

    await this.prisma.$transaction(async (tx) => {
      const { count } = await tx.order.updateMany({
        where: { id: orderId, cityId: courier.cityId, status: OrderStatus.READY, courierId: null },
        data: { status: OrderStatus.COURIER_ASSIGNED, courierId: courier.id },
      });
      if (count === 0) {
        throw new AppException(
          ErrorCode.ORDER_ALREADY_TAKEN,
          HttpStatus.CONFLICT,
          'Este pedido ya no está disponible para tomar.',
        );
      }
      await tx.orderStatusHistory.create({
        data: {
          orderId,
          fromStatus: OrderStatus.READY,
          toStatus: OrderStatus.COURIER_ASSIGNED,
          changedById: courierUserId,
          changedByRole: Role.COURIER,
        },
      });
    });
    return this.find({ userId: courierUserId, role: Role.COURIER }, orderId);
  }

  async cancel(actor: OrderActor, orderId: string, reason?: string): Promise<OrderWithDetails> {
    const order = await this.find(actor, orderId);
    if (!canTransition(order.status, OrderStatus.CANCELLED, actor.role)) {
      throw new AppException(
        ErrorCode.INVALID_STATUS_TRANSITION,
        HttpStatus.CONFLICT,
        actor.role === Role.CUSTOMER
          ? 'El negocio ya está preparando tu pedido: escríbenos para cancelarlo.'
          : 'Este pedido ya no se puede cancelar.',
        { status: order.status },
      );
    }

    await this.prisma.$transaction(async (tx) => {
      await this.move(tx, actor, order.id, order.status, OrderStatus.CANCELLED, reason, {
        cancelReason: reason || null,
        cancelledBy: actor.role,
      });
      // Devuelve el stock reservado (solo productos con stock controlado).
      for (const item of order.items) {
        if (!item.productId) continue;
        await tx.product.updateMany({
          where: { id: item.productId, stock: { not: null } },
          data: { stock: { increment: item.quantity } },
        });
      }
      // Libera el cupón: vuelve a contar para el cupo y para el cliente.
      if (order.couponId) {
        const { count } = await tx.couponRedemption.deleteMany({ where: { orderId: order.id } });
        if (count > 0) {
          await tx.coupon.updateMany({
            where: { id: order.couponId, usedCount: { gt: 0 } },
            data: { usedCount: { decrement: 1 } },
          });
        }
      }
      await tx.payment.updateMany({ where: { orderId: order.id }, data: { status: PaymentStatus.CANCELLED } });
    });
    return this.find(actor, orderId);
  }

  private async move(
    tx: Prisma.TransactionClient,
    actor: OrderActor,
    orderId: string,
    from: OrderStatus,
    to: OrderStatus,
    note: string | undefined,
    data: Prisma.OrderUpdateManyMutationInput,
  ) {
    const { count } = await tx.order.updateMany({
      where: { id: orderId, status: from },
      data: { ...data, status: to },
    });
    // Otra persona lo cambió entre la lectura y este update.
    if (count === 0) throw invalidTransition(from, to);
    await tx.orderStatusHistory.create({
      data: {
        orderId,
        fromStatus: from,
        toStatus: to,
        changedById: actor.userId,
        changedByRole: actor.role,
        note: note || null,
      },
    });
  }
}

function invalidTransition(from: OrderStatus, to: OrderStatus) {
  return new AppException(
    ErrorCode.INVALID_STATUS_TRANSITION,
    HttpStatus.CONFLICT,
    'El pedido cambió de estado. Actualiza para ver cómo va.',
    { from, to },
  );
}
