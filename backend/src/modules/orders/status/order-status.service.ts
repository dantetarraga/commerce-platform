import { HttpStatus, Injectable } from '@nestjs/common';
import { EventEmitter2 } from '@nestjs/event-emitter';
import { AppException, ErrorCode } from '../../../common/exceptions/app.exception';
import { PrismaService } from '../../../database/prisma.service';
import { Prisma } from '../../../generated/prisma/client';
import { CourierStatus, OrderStatus, PaymentMethodType, PaymentStatus, Role } from '../../../generated/prisma/enums';
import { estimateAfterAccept, estimateOnTheWay } from '../../delivery/delivery';
import { NotificationsService } from '../../notifications/notifications.service';
import { orderNotice } from '../../notifications/order-notices';
import { ORDER_CHANGED, OrderChangedEvent } from '../../realtime/realtime.events';
import { orderInclude, OrderWithDetails } from '../order-presenter';
import { canTransition } from './order-status.machine';

/** Quién actúa y con qué rol (el de la ruta: cliente, negocio, courier o admin). */
export interface OrderActor {
  userId: string;
  role: Role;
}

const ORDER_NOT_FOUND = 'No encontramos ese pedido.';

/** Estados en que el pedido está en manos del repartidor. */
export const COURIER_ACTIVE_STATUSES = [OrderStatus.COURIER_ASSIGNED, OrderStatus.ON_THE_WAY];

/** Lo que el repartidor cobró al entregar (contraentrega). */
export interface Collection {
  method: PaymentMethodType;
  amount: number;
}

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
 * a la vez), historial, el aviso al cliente y sus efectos: cobrar al
 * entregar, restaurar stock y cupón al cancelar.
 */
@Injectable()
export class OrderStatusService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly notifications: NotificationsService,
    private readonly events: EventEmitter2,
  ) {}

  async find(actor: OrderActor, orderId: string): Promise<OrderWithDetails> {
    const order = await this.prisma.order.findFirst({
      where: { id: orderId, ...scopeFor(actor) },
      include: orderInclude,
    });
    if (!order) throw AppException.notFound(ORDER_NOT_FOUND);
    return order;
  }

  /**
   * Un paso adelante. Al entregar, el repartidor dice cómo pagó el cliente y
   * cuánto cobró (`collection`); queda en el pago aunque no coincida con el
   * total, y el repartidor vuelve a estar disponible.
   */
  async advance(
    actor: OrderActor,
    orderId: string,
    to: OrderStatus,
    note?: string,
    collection?: Collection,
  ): Promise<OrderWithDetails> {
    const order = await this.find(actor, orderId);
    if (to === OrderStatus.CANCELLED || !canTransition(order.status, to, actor.role)) {
      throw invalidTransition(order.status, to);
    }
    if (to === OrderStatus.DELIVERED && actor.role === Role.COURIER && !collection) {
      throw new AppException(
        ErrorCode.COLLECTION_REQUIRED,
        HttpStatus.UNPROCESSABLE_ENTITY,
        'Indica cómo pagó el cliente y cuánto cobraste.',
      );
    }
    // La hora estimada de creación incluía la preparación; al salir solo queda el viaje.
    const city =
      to === OrderStatus.ON_THE_WAY
        ? await this.prisma.city.findUniqueOrThrow({ where: { id: order.cityId }, select: { avgSpeedKmh: true } })
        : null;
    await this.prisma.$transaction(async (tx) => {
      const now = new Date();
      const data =
        to === OrderStatus.DELIVERED
          ? { deliveredAt: now }
          : city
            ? {
                estimatedAt: estimateOnTheWay({
                  now,
                  distanceMeters: order.distanceMeters,
                  avgSpeedKmh: city.avgSpeedKmh,
                }),
              }
            : {};
      await this.move(tx, actor, order.id, order.status, to, note, data);
      if (to === OrderStatus.DELIVERED) {
        await tx.payment.updateMany({
          where: { orderId: order.id },
          data: {
            status: PaymentStatus.PAID,
            ...(collection && {
              collectedById: actor.userId,
              collectedMethod: collection.method,
              collectedAmount: collection.amount,
              collectedAt: now,
            }),
          },
        });
        await tx.store.update({ where: { id: order.storeId }, data: { popularityScore: { increment: 1 } } });
        if (order.courierId) await this.releaseCourier(tx, order.courierId);
      }
      const courier = order.courier && {
        firstName: order.courier.user.firstName,
        vehicleLabel: order.courier.vehicleLabel,
      };
      await this.notifyCustomer(tx, order, to, { courier });
    });
    this.changed(order, to);
    return this.find(actor, orderId);
  }

  /**
   * El negocio acepta un pedido nuevo y dice en cuántos minutos lo tiene: en
   * una transacción pasa RECEIVED → CONFIRMED → PREPARING (dos filas de
   * historial), recalcula la hora estimada y avisa al cliente una sola vez.
   */
  async acceptByMerchant(actor: OrderActor, orderId: string, prepMinutes: number): Promise<OrderWithDetails> {
    const order = await this.find(actor, orderId);
    if (!canTransition(order.status, OrderStatus.CONFIRMED, actor.role)) {
      throw invalidTransition(order.status, OrderStatus.PREPARING);
    }
    const city = await this.prisma.city.findUniqueOrThrow({
      where: { id: order.cityId },
      select: { avgSpeedKmh: true },
    });

    await this.prisma.$transaction(async (tx) => {
      await this.move(tx, actor, order.id, OrderStatus.RECEIVED, OrderStatus.CONFIRMED, undefined, {});
      const estimatedAt = estimateAfterAccept({
        now: new Date(),
        prepMinutes,
        distanceMeters: order.distanceMeters,
        avgSpeedKmh: city.avgSpeedKmh,
        scheduledFor: order.scheduledFor,
      });
      const note = `Listo en ${prepMinutes} min`;
      await this.move(tx, actor, order.id, OrderStatus.CONFIRMED, OrderStatus.PREPARING, note, { estimatedAt });
      await this.notifyCustomer(tx, order, OrderStatus.PREPARING, {});
    });
    this.changed(order, OrderStatus.PREPARING);
    return this.find(actor, orderId);
  }

  async courierFor(userId: string) {
    const courier = await this.prisma.courier.findUnique({
      where: { userId },
      include: { user: { select: { firstName: true } } },
    });
    if (!courier) throw AppException.notFound('No tienes perfil de repartidor.');
    return courier;
  }

  /** Id del pedido que el repartidor tiene en curso, o null. */
  async activeOrderId(courierId: string, client: Prisma.TransactionClient = this.prisma): Promise<string | null> {
    const order = await client.order.findFirst({
      where: { courierId, status: { in: COURIER_ACTIVE_STATUSES } },
      select: { id: true },
    });
    return order?.id ?? null;
  }

  /**
   * El courier toma un pedido listo de su ciudad. Tiene que estar conectado
   * (AVAILABLE) y sin otro pedido; pasa a BUSY en la misma transacción.
   * Condicional: si dos repartidores aceptan a la vez, solo uno se lo lleva
   * (el otro recibe ORDER_ALREADY_TAKEN y su BUSY se revierte).
   */
  async accept(courierUserId: string, orderId: string): Promise<OrderWithDetails> {
    const courier = await this.courierFor(courierUserId);

    const taken = await this.prisma.$transaction(async (tx) => {
      const busy = await tx.courier.updateMany({
        where: { id: courier.id, status: CourierStatus.AVAILABLE },
        data: { status: CourierStatus.BUSY },
      });
      if (busy.count === 0 || (await this.activeOrderId(courier.id, tx))) {
        throw new AppException(
          ErrorCode.COURIER_NOT_AVAILABLE,
          HttpStatus.CONFLICT,
          'Conéctate y termina tu entrega actual antes de tomar otro pedido.',
        );
      }

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
      const order = await tx.order.findUniqueOrThrow({
        where: { id: orderId },
        select: { id: true, code: true, storeId: true, storeName: true, customerId: true },
      });
      await this.notifyCustomer(tx, order, OrderStatus.COURIER_ASSIGNED, {
        courier: { firstName: courier.user.firstName, vehicleLabel: courier.vehicleLabel },
      });
      return order;
    });
    this.changed({ ...taken, cityId: courier.cityId }, OrderStatus.COURIER_ASSIGNED);
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

    await this.cancelLoaded(order, actor, reason);
    return this.find(actor, orderId);
  }

  /**
   * El negocio no respondió a tiempo (OPERACION §2): Apamuy cancela el pedido y queda
   * sin autor (`cancelledBy = null`). `false` si mientras tanto el negocio lo aceptó.
   */
  async expireUnanswered(orderId: string, reason: string): Promise<boolean> {
    const order = await this.prisma.order.findUnique({ where: { id: orderId }, include: orderInclude });
    if (order?.status !== OrderStatus.RECEIVED) return false;
    try {
      await this.cancelLoaded(order, null, reason);
      return true;
    } catch (error) {
      if (error instanceof AppException && error.code === ErrorCode.INVALID_STATUS_TRANSITION) return false;
      throw error;
    }
  }

  /** Cancela con sus efectos. `actor` nulo: lo hizo Apamuy, no una persona. */
  private async cancelLoaded(order: OrderWithDetails, actor: OrderActor | null, reason?: string) {
    await this.prisma.$transaction(async (tx) => {
      await this.move(tx, actor, order.id, order.status, OrderStatus.CANCELLED, reason, {
        cancelReason: reason || null,
        cancelledBy: actor?.role ?? null,
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
      if (order.courierId) await this.releaseCourier(tx, order.courierId);
      // Si canceló el propio cliente, ya lo sabe.
      if (actor?.role !== Role.CUSTOMER) {
        await this.notifyCustomer(tx, order, OrderStatus.CANCELLED, { cancelReason: reason });
      }
    });
    this.changed(order, OrderStatus.CANCELLED);
  }

  /** Avisa por WebSocket (después del commit). */
  private changed(order: { id: string; storeId: string; cityId: string }, status: OrderStatus) {
    this.events.emit(ORDER_CHANGED, {
      orderId: order.id,
      storeId: order.storeId,
      cityId: order.cityId,
      status,
    } satisfies OrderChangedEvent);
  }

  /** El repartidor terminó (entregó o se canceló su pedido): vuelve a estar disponible. */
  private async releaseCourier(tx: Prisma.TransactionClient, courierId: string) {
    await tx.courier.updateMany({
      where: { id: courierId, status: CourierStatus.BUSY },
      data: { status: CourierStatus.AVAILABLE },
    });
  }

  private async notifyCustomer(
    tx: Prisma.TransactionClient,
    order: { id: string; code: string; storeId: string; storeName: string; customerId: string },
    to: OrderStatus,
    extra: { courier?: { firstName: string; vehicleLabel: string } | null; cancelReason?: string },
  ) {
    const notice = orderNotice(to, {
      orderId: order.id,
      code: order.code,
      storeId: order.storeId,
      storeName: order.storeName,
      ...extra,
    });
    if (notice) await this.notifications.notifyOrder(tx, order.customerId, notice);
  }

  private async move(
    tx: Prisma.TransactionClient,
    actor: OrderActor | null,
    orderId: string,
    from: OrderStatus,
    to: OrderStatus,
    note: string | undefined,
    data: Prisma.OrderUpdateManyMutationInput,
  ) {
    // Horas para el resumen del negocio (tiempo de preparación).
    const stamp =
      to === OrderStatus.CONFIRMED
        ? { acceptedAt: new Date() }
        : to === OrderStatus.READY
          ? { readyAt: new Date() }
          : {};
    const { count } = await tx.order.updateMany({
      where: { id: orderId, status: from },
      data: { ...data, ...stamp, status: to },
    });
    // Otra persona lo cambió entre la lectura y este update.
    if (count === 0) throw invalidTransition(from, to);
    await tx.orderStatusHistory.create({
      data: {
        orderId,
        fromStatus: from,
        toStatus: to,
        changedById: actor?.userId ?? null,
        changedByRole: actor?.role ?? null,
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
