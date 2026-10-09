import { Logger } from '@nestjs/common';
import { OnEvent } from '@nestjs/event-emitter';
import {
  ConnectedSocket,
  MessageBody,
  OnGatewayConnection,
  OnGatewayInit,
  SubscribeMessage,
  WebSocketGateway,
  WebSocketServer,
} from '@nestjs/websockets';
import type { Namespace, Socket } from 'socket.io';
import type { AuthUser } from '../../common/decorators/auth.decorators';
import { PrismaService } from '../../database/prisma.service';
import { OrderStatus, Role } from '../../generated/prisma/enums';
import { TokensService } from '../auth/tokens/tokens.service';
import { COURIER_MOVED, ORDER_CHANGED } from './realtime.events';
import type { CourierMovedEvent, OrderChangedEvent } from './realtime.events';

/** Estados que cambian la lista de pedidos para tomar de los repartidores. */
const COURIER_BOARD_STATUSES: OrderStatus[] = [OrderStatus.READY, OrderStatus.COURIER_ASSIGNED, OrderStatus.CANCELLED];

export const rooms = {
  order: (id: string) => `order:${id}`,
  store: (id: string) => `store:${id}`,
  couriers: (cityId: string) => `couriers:${cityId}`,
  /** Todos los ADMIN conectados: el tablero de pedidos en vivo. */
  admin: 'admin',
};

type Ack = { ok: true } | { ok: false; code: string };

/** Lo que el middleware deja en `socket.data` al conectar. */
interface SocketData {
  user: AuthUser;
}

const userOf = (socket: Socket) => (socket.data as SocketData).user;

/**
 * Tiempo real en `/ws` (Socket.IO). El token de acceso va en `auth.token` del
 * handshake y se valida solo al conectar: sin token válido la conexión falla
 * con `connect_error` "UNAUTHORIZED" y la app reconecta con uno nuevo. Los eventos solo avisan qué cambió: la app vuelve a pedir el detalle
 * por REST, que sigue siendo la única fuente de verdad.
 *
 * - Cliente: `order.subscribe { orderId }` → `order.updated` y `courier.location`.
 * - Negocio: entra solo a `store:{id}` de sus negocios → `store.orders.changed`.
 * - Repartidor: entra a `couriers:{ciudad}` → `courier.orders.changed`.
 */
@WebSocketGateway({ namespace: '/ws' })
export class RealtimeGateway implements OnGatewayInit, OnGatewayConnection {
  private readonly logger = new Logger(RealtimeGateway.name);

  @WebSocketServer() private readonly server!: Namespace;

  constructor(
    private readonly tokens: TokensService,
    private readonly prisma: PrismaService,
  ) {}

  afterInit(namespace: Namespace) {
    namespace.use((socket, next) => {
      const token: unknown = (socket.handshake.auth as { token?: unknown }).token;
      if (typeof token !== 'string' || !token) return next(new Error('UNAUTHORIZED'));
      this.tokens
        .verifyAccess(token)
        .then((user) => {
          (socket.data as SocketData).user = user;
          next();
        })
        .catch(() => next(new Error('UNAUTHORIZED')));
    });
  }

  async handleConnection(socket: Socket) {
    const user = userOf(socket);

    const [stores, courier] = await Promise.all([
      this.prisma.store.findMany({ where: { ownerId: user.id }, select: { id: true } }),
      user.roles.includes(Role.COURIER)
        ? this.prisma.courier.findUnique({ where: { userId: user.id }, select: { cityId: true } })
        : null,
    ]);
    await socket.join([
      ...stores.map((s) => rooms.store(s.id)),
      ...(courier ? [rooms.couriers(courier.cityId)] : []),
      ...(user.roles.includes(Role.ADMIN) ? [rooms.admin] : []),
    ]);
  }

  @SubscribeMessage('order.subscribe')
  async subscribe(@ConnectedSocket() socket: Socket, @MessageBody() body: { orderId?: unknown }): Promise<Ack> {
    const user = userOf(socket);
    const orderId = body?.orderId;
    if (typeof orderId !== 'string') return { ok: false, code: 'VALIDATION_ERROR' };
    const visible = user.roles.includes(Role.ADMIN)
      ? await this.prisma.order.count({ where: { id: orderId } })
      : await this.prisma.order.count({
          where: {
            id: orderId,
            OR: [{ customerId: user.id }, { store: { ownerId: user.id } }, { courier: { userId: user.id } }],
          },
        });
    if (visible === 0) return { ok: false, code: 'NOT_FOUND' };
    await socket.join(rooms.order(orderId));
    return { ok: true };
  }

  @SubscribeMessage('order.unsubscribe')
  async unsubscribe(@ConnectedSocket() socket: Socket, @MessageBody() body: { orderId?: unknown }): Promise<Ack> {
    if (typeof body?.orderId === 'string') await socket.leave(rooms.order(body.orderId));
    return { ok: true };
  }

  @OnEvent(ORDER_CHANGED)
  onOrderChanged(event: OrderChangedEvent) {
    const payload = { orderId: event.orderId, status: event.status };
    this.server.to(rooms.order(event.orderId)).emit('order.updated', payload);
    this.server.to(rooms.store(event.storeId)).emit('store.orders.changed', payload);
    // El tablero del admin filtra por ciudad en el cliente.
    this.server.to(rooms.admin).emit('admin.orders.changed', { ...payload, cityId: event.cityId });
    if (COURIER_BOARD_STATUSES.includes(event.status)) {
      this.server.to(rooms.couriers(event.cityId)).emit('courier.orders.changed', payload);
    }
    this.logger.debug(`order.updated ${event.orderId} → ${event.status}`);
  }

  @OnEvent(COURIER_MOVED)
  onCourierMoved(event: CourierMovedEvent) {
    this.server.to(rooms.order(event.orderId)).emit('courier.location', {
      orderId: event.orderId,
      lat: event.lat,
      lng: event.lng,
      at: event.at.toISOString(),
    });
  }
}
