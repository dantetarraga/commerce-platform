import { Injectable, Logger } from '@nestjs/common';
import { OnEvent } from '@nestjs/event-emitter';
import { PrismaService } from '../../database/prisma.service';
import { CourierStatus } from '../../generated/prisma/enums';
import { ORDER_CHANGED, type OrderChangedEvent } from '../realtime/realtime.events';
import { orderPushes, type PushAudience } from './order-pushes';
import { PushSender, type PushMessage } from './push-sender';

export type PushApp = 'customer' | 'partner';

/** Dispositivos registrados y envío de push. Lo de pedidos se dispara solo, tras el commit. */
@Injectable()
export class PushService {
  private readonly logger = new Logger(PushService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly sender: PushSender,
  ) {}

  /** Un token pertenece a un solo usuario: si el teléfono cambió de cuenta, pasa a la nueva. */
  async register(userId: string, pushToken: string, platform: string, app: PushApp) {
    await this.prisma.device.upsert({
      where: { pushToken },
      create: { userId, pushToken, platform, app },
      update: { userId, platform, app },
    });
  }

  /** Al cerrar sesión: ese teléfono deja de recibir avisos de la cuenta. */
  async unregister(userId: string, pushToken: string) {
    await this.prisma.device.deleteMany({ where: { userId, pushToken } });
  }

  async sendToUsers(userIds: readonly string[], app: PushApp, message: PushMessage) {
    if (userIds.length === 0) return;
    const devices = await this.prisma.device.findMany({
      where: { userId: { in: [...userIds] }, app },
      select: { pushToken: true },
    });
    const { invalidTokens } = await this.sender.send(
      devices.map((device) => device.pushToken),
      message,
    );
    if (invalidTokens.length > 0) {
      await this.prisma.device.deleteMany({ where: { pushToken: { in: invalidTokens } } });
    }
  }

  /** Un push que falla nunca rompe el cambio de estado del pedido: se loguea y sigue. */
  @OnEvent(ORDER_CHANGED, { async: true })
  async onOrderChanged(event: OrderChangedEvent) {
    try {
      await this.sendOrderPushes(event);
    } catch (error) {
      this.logger.error(`No se pudo enviar el push del pedido ${event.orderId}: ${(error as Error).message}`);
    }
  }

  private async sendOrderPushes(event: OrderChangedEvent) {
    const order = await this.prisma.order.findUnique({
      where: { id: event.orderId },
      select: {
        id: true,
        code: true,
        storeId: true,
        storeName: true,
        cancelReason: true,
        cancelledBy: true,
        customerId: true,
        store: { select: { ownerId: true } },
        courier: { select: { vehicleLabel: true, user: { select: { firstName: true } } } },
      },
    });
    if (!order) return;
    const pushes = orderPushes(
      {
        ...order,
        courier: order.courier && {
          firstName: order.courier.user.firstName,
          vehicleLabel: order.courier.vehicleLabel,
        },
      },
      event.status,
    );
    for (const push of pushes) {
      const [userIds, app] = await this.recipients(push.audience, order, event.cityId);
      await this.sendToUsers(userIds, app, push.message);
    }
  }

  private async recipients(
    audience: PushAudience,
    order: { customerId: string; store: { ownerId: string } },
    cityId: string,
  ): Promise<[string[], PushApp]> {
    switch (audience) {
      case 'customer':
        return [[order.customerId], 'customer'];
      case 'owner':
        return [[order.store.ownerId], 'partner'];
      case 'couriers': {
        const couriers = await this.prisma.courier.findMany({
          where: { cityId, status: CourierStatus.AVAILABLE },
          select: { userId: true },
        });
        return [couriers.map((courier) => courier.userId), 'partner'];
      }
    }
  }
}
