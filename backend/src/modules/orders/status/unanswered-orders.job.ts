import { Injectable, Logger } from '@nestjs/common';
import { ConfigService } from '@nestjs/config';
import { Interval } from '@nestjs/schedule';
import type { Env } from '../../../config/env';
import { PrismaService } from '../../../database/prisma.service';
import { OrderStatus } from '../../../generated/prisma/enums';
import { expiredBefore, UNANSWERED_REASON } from '../response-deadline';
import { OrderStatusService } from './order-status.service';

/** Cada 30 s cancela los pedidos que el negocio no respondió en 8 minutos (OPERACION §2). */
@Injectable()
export class UnansweredOrdersJob {
  private readonly logger = new Logger(UnansweredOrdersJob.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly status: OrderStatusService,
    private readonly config: ConfigService<Env, true>,
  ) {}

  @Interval('expire-unanswered-orders', 30_000)
  async tick() {
    // En las pruebas lo llaman ellas, con su propio reloj.
    if (this.config.get('NODE_ENV', { infer: true }) === 'test') return;
    await this.expire();
  }

  async expire(now = new Date()): Promise<number> {
    const expired = await this.prisma.order.findMany({
      where: { status: OrderStatus.RECEIVED, ...expiredBefore(now) },
      select: { id: true, code: true },
      take: 50,
    });
    let cancelled = 0;
    for (const order of expired) {
      if (await this.status.expireUnanswered(order.id, UNANSWERED_REASON)) {
        cancelled++;
        this.logger.warn(`Pedido ${order.code} cancelado: el negocio no respondió en 8 minutos`);
      }
    }
    return cancelled;
  }
}
