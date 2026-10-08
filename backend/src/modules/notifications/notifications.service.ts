import { Injectable } from '@nestjs/common';
import type { CursorQueryDto } from '../../common/dto/cursor-query.dto';
import { PrismaService } from '../../database/prisma.service';
import type { Notification, Prisma } from '../../generated/prisma/client';
import { NotificationType } from '../../generated/prisma/enums';
import { DEFAULT_TIMEZONE, zonedTime } from '../../common/time';
import { buildNoticeFeed, NoticeFilter } from './notice-feed';
import { NoticeData, NoticeKind, OrderNotice } from './order-notices';

/** Aviso como lo lee la app (`Notice`). */
function toNoticeResponse(n: Notification) {
  const data = (n.data ?? {}) as Partial<NoticeData>;
  return {
    id: n.id,
    kind: data.kind ?? (n.type === NotificationType.PROMOTION ? NoticeKind.PROMOTION : NoticeKind.ORDER_CONFIRMED),
    title: n.title,
    body: n.body,
    at: n.createdAt.toISOString(),
    read: n.readAt !== null,
    orderId: data.orderId ?? null,
    storeId: data.storeId ?? null,
  };
}

@Injectable()
export class NotificationsService {
  constructor(private readonly prisma: PrismaService) {}

  async list(userId: string, query: CursorQueryDto) {
    const rows = await this.prisma.notification.findMany({
      where: { userId },
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
      take: query.limit + 1,
      ...(query.cursor && { cursor: { id: query.cursor }, skip: 1 }),
    });
    const page = rows.slice(0, query.limit);
    const unreadCount = await this.prisma.notification.count({ where: { userId, readAt: null } });
    return {
      items: page.map(toNoticeResponse),
      nextCursor: rows.length > query.limit ? page[page.length - 1].id : null,
      unreadCount,
    };
  }

  /** Avisos que trae el centro de avisos (los más recientes). */
  static readonly FEED_LIMIT = 50;

  /**
   * El centro de avisos armado para una pestaña: el hilo del pedido en curso,
   * el resto por día (hora de Lima) y cuántos hay sin leer.
   */
  async feed(userId: string, filter: NoticeFilter, now = new Date()) {
    const [rows, unreadCount] = await Promise.all([
      this.prisma.notification.findMany({
        where: { userId },
        orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
        take: NotificationsService.FEED_LIMIT,
      }),
      this.prisma.notification.count({ where: { userId, readAt: null } }),
    ]);
    const today = zonedTime.localDate(now, DEFAULT_TIMEZONE);
    const yesterday = zonedTime.localDate(new Date(now.getTime() - 24 * 60 * 60_000), DEFAULT_TIMEZONE);
    const feed = buildNoticeFeed(rows.map(toNoticeResponse), filter, today, yesterday, (at) =>
      zonedTime.localDate(new Date(at), DEFAULT_TIMEZONE),
    );
    return { ...feed, unreadCount, total: rows.length };
  }

  async markAllRead(userId: string): Promise<void> {
    await this.prisma.notification.updateMany({ where: { userId, readAt: null }, data: { readAt: new Date() } });
  }

  /** Crea el aviso del pedido dentro de la misma transacción que el cambio de estado. */
  async notifyOrder(tx: Prisma.TransactionClient, userId: string, notice: OrderNotice): Promise<void> {
    await tx.notification.create({
      data: {
        userId,
        type: NotificationType.ORDER_STATUS,
        title: notice.title,
        body: notice.body,
        data: { ...notice.data },
      },
    });
  }
}
