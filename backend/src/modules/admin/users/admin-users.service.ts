import { HttpStatus, Injectable } from '@nestjs/common';
import { AppException, ErrorCode } from '../../../common/exceptions/app.exception';
import { money } from '../../../common/utils/money';
import { PrismaService } from '../../../database/prisma.service';
import { Prisma } from '../../../generated/prisma/client';
import { OrderStatus, Role } from '../../../generated/prisma/enums';
import { TokensService } from '../../auth/tokens/tokens.service';
import { FINAL_STATUSES } from '../../orders/order-list-scope';
import { PartnerRole } from '../partners/partners.dto';
import { recordAdminAction } from './admin-actions';
import { ListUsersQueryDto } from './admin-users.dto';
import { courierPerformance, merchantPerformance, PERFORMANCE_DAYS } from './partner-performance';

const DAY_MS = 24 * 60 * 60 * 1000;
const PARTNER_OR_ADMIN: Role[] = [Role.MERCHANT, Role.COURIER, Role.ADMIN];
/** Las cuentas eliminadas quedan anonimizadas con este prefijo en el celular. */
const DELETED_PREFIX = 'deleted:';

const rowInclude = {
  roles: { select: { role: true } },
  ownedStores: { where: { deletedAt: null }, select: { id: true, name: true } },
  courier: { select: { vehicleLabel: true, status: true } },
  _count: { select: { orders: true } },
  orders: { orderBy: { createdAt: 'desc' }, take: 1, select: { createdAt: true } },
} satisfies Prisma.UserInclude;

type UserRow = Prisma.UserGetPayload<{ include: typeof rowInclude }>;

const toRow = (user: UserRow) => ({
  id: user.id,
  phone: user.phone,
  firstName: user.firstName,
  lastName: user.lastName,
  isActive: user.isActive,
  roles: user.roles.map((r) => r.role),
  createdAt: user.createdAt,
  orders: user._count.orders,
  lastOrderAt: user.orders[0]?.createdAt ?? null,
  stores: user.ownedStores,
  courier: user.courier,
});

/** Las cuentas desde el panel: buscar, ver su actividad y gestionar el acceso. */
@Injectable()
export class AdminUsersService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly tokens: TokensService,
  ) {}

  async list(query: ListUsersQueryDto) {
    const page = query.page ?? 1;
    const pageSize = query.pageSize ?? 25;
    const where = this.where(query);
    const [total, users] = await Promise.all([
      this.prisma.user.count({ where }),
      this.prisma.user.findMany({
        where,
        include: rowInclude,
        orderBy: { createdAt: 'desc' },
        skip: (page - 1) * pageSize,
        take: pageSize,
      }),
    ]);
    return { items: users.map(toRow), page, pageSize, total };
  }

  async detail(userId: string, now = new Date()) {
    const user = await this.prisma.user.findUnique({
      where: { id: userId },
      include: {
        ...rowInclude,
        ownedStores: { where: { deletedAt: null }, select: { id: true, name: true, isAcceptingOrders: true } },
        courier: { select: { id: true, vehicleType: true, vehicleLabel: true, plate: true, status: true } },
        devices: { select: { platform: true, app: true, updatedAt: true }, orderBy: { updatedAt: 'desc' } },
        _count: { select: { orders: true, addresses: { where: { deletedAt: null } } } },
      },
    });
    if (!user) throw AppException.notFound('No encontramos ese usuario.');

    const since = new Date(now.getTime() - PERFORMANCE_DAYS * DAY_MS);
    const storeIds = user.ownedStores.map((s) => s.id);
    const [stats, recentOrders, sessions, history, merchantOrders, courierOrders] = await Promise.all([
      this.customerStats(userId),
      this.prisma.order.findMany({
        where: { customerId: userId },
        orderBy: { createdAt: 'desc' },
        take: 10,
        select: { id: true, code: true, storeName: true, status: true, total: true, currency: true, createdAt: true },
      }),
      this.prisma.refreshToken.count({ where: { userId, revokedAt: null, expiresAt: { gt: now } } }),
      this.prisma.adminAction.findMany({
        where: { userId },
        orderBy: { createdAt: 'desc' },
        take: 20,
        select: {
          id: true,
          action: true,
          details: true,
          createdAt: true,
          admin: { select: { firstName: true, lastName: true } },
        },
      }),
      storeIds.length
        ? this.prisma.order.findMany({
            where: { storeId: { in: storeIds }, createdAt: { gte: since } },
            select: { status: true, createdAt: true, acceptedAt: true, cancelledBy: true },
          })
        : Promise.resolve([]),
      user.courier
        ? this.prisma.order.findMany({
            where: { courierId: user.courier.id, createdAt: { gte: since } },
            select: { status: true, readyAt: true, deliveredAt: true, payment: { select: { collectedAmount: true } } },
          })
        : Promise.resolve([]),
    ]);

    const courier = courierPerformance(
      courierOrders.map((o) => ({ ...o, collectedAmount: o.payment?.collectedAmount ?? null })),
    );
    return {
      ...toRow(user),
      email: user.email,
      addresses: user._count.addresses,
      stores: user.ownedStores,
      courier: user.courier,
      devices: user.devices,
      activeSessions: sessions,
      stats,
      recentOrders: recentOrders.map(({ total, currency, ...order }) => ({ ...order, total: money(total, currency) })),
      performance: {
        days: PERFORMANCE_DAYS,
        merchant: storeIds.length ? merchantPerformance(merchantOrders) : null,
        courier: user.courier ? { ...courier, collected: money(courier.collected) } : null,
      },
      history: history.map(({ admin, ...entry }) => ({
        ...entry,
        by: admin ? `${admin.firstName} ${admin.lastName}`.trim() : null,
      })),
    };
  }

  /** No entra más: se cierran sus sesiones. Un pedido en curso se resuelve antes. */
  async block(adminId: string, userId: string, reason?: string) {
    if (adminId === userId) throw cannotChangeSelf();
    await this.prisma.$transaction(async (tx) => {
      const user = await this.find(tx, userId);
      if (user.roles.some((r) => r.role === Role.ADMIN)) {
        throw new AppException(ErrorCode.ADMIN_ACCOUNT, HttpStatus.CONFLICT, 'Quítale primero el acceso de admin.');
      }
      const active = await tx.order.count({
        where: {
          status: { notIn: FINAL_STATUSES },
          OR: [{ customerId: userId }, { courier: { userId } }, { store: { ownerId: userId } }],
        },
      });
      if (active > 0) {
        throw new AppException(
          ErrorCode.ACCOUNT_HAS_ACTIVE_ORDER,
          HttpStatus.CONFLICT,
          'Tiene un pedido en curso. Espera a que termine o cancélalo antes de bloquearlo.',
        );
      }
      await tx.user.update({ where: { id: userId }, data: { isActive: false } });
      await tx.store.updateMany({ where: { ownerId: userId }, data: { isAcceptingOrders: false } });
      await tx.courier.updateMany({ where: { userId }, data: { status: 'OFFLINE' } });
      await recordAdminAction(tx, adminId, userId, 'BLOCKED', reason ? { reason } : undefined);
    });
    await this.tokens.revokeAllForUser(userId);
    return this.detail(userId);
  }

  async unblock(adminId: string, userId: string) {
    await this.prisma.$transaction(async (tx) => {
      const user = await this.find(tx, userId);
      if (user.phone.startsWith(DELETED_PREFIX)) throw AppException.notFound('Esa cuenta fue eliminada.');
      await tx.user.update({ where: { id: userId }, data: { isActive: true } });
      await recordAdminAction(tx, adminId, userId, 'UNBLOCKED');
    });
    return this.detail(userId);
  }

  /** Devuelve roles de socio quitados con la suspensión. Sus negocios siguen en pausa hasta que el dueño los abra. */
  async restorePartner(adminId: string, userId: string, roles: readonly PartnerRole[]) {
    await this.prisma.$transaction(async (tx) => {
      const user = await this.find(tx, userId);
      if (!user.isActive) {
        throw new AppException(
          ErrorCode.USER_DISABLED,
          HttpStatus.CONFLICT,
          'La cuenta está bloqueada. Desbloquéala primero.',
        );
      }
      if (roles.includes(Role.COURIER) && !(await tx.courier.findUnique({ where: { userId }, select: { id: true } }))) {
        throw new AppException(
          ErrorCode.COURIER_NOT_REGISTERED,
          HttpStatus.CONFLICT,
          'No tiene vehículo registrado. Dalo de alta como repartidor.',
        );
      }
      for (const role of roles) {
        await tx.userRole.upsert({ where: { userId_role: { userId, role } }, create: { userId, role }, update: {} });
      }
      await recordAdminAction(tx, adminId, userId, 'PARTNER_RESTORED', { roles: [...roles] });
    });
    return this.detail(userId);
  }

  async revokeSessions(adminId: string, userId: string) {
    await this.find(this.prisma, userId);
    await this.tokens.revokeAllForUser(userId);
    await recordAdminAction(this.prisma, adminId, userId, 'SESSIONS_REVOKED');
    return this.detail(userId);
  }

  async setAdmin(adminId: string, userId: string, isAdmin: boolean) {
    if (adminId === userId && !isAdmin) throw cannotChangeSelf();
    await this.prisma.$transaction(async (tx) => {
      const user = await this.find(tx, userId);
      if (isAdmin && !user.isActive) {
        throw new AppException(ErrorCode.USER_DISABLED, HttpStatus.CONFLICT, 'La cuenta está bloqueada.');
      }
      if (isAdmin) {
        await tx.userRole.upsert({
          where: { userId_role: { userId, role: Role.ADMIN } },
          create: { userId, role: Role.ADMIN },
          update: {},
        });
      } else {
        await tx.userRole.deleteMany({ where: { userId, role: Role.ADMIN } });
      }
      await recordAdminAction(tx, adminId, userId, isAdmin ? 'ADMIN_GRANTED' : 'ADMIN_REVOKED');
    });
    // Sin el rol, su sesión del panel deja de servir al renovar el token.
    if (!isAdmin) await this.tokens.revokeAllForUser(userId);
    return this.detail(userId);
  }

  private where(query: ListUsersQueryDto): Prisma.UserWhereInput {
    const and: Prisma.UserWhereInput[] = [{ NOT: { phone: { startsWith: DELETED_PREFIX } } }];
    const q = query.q;
    if (q) {
      const digits = q.replace(/\D/g, '');
      and.push({
        OR: [
          ...(digits.length >= 3 ? [{ phone: { startsWith: digits } }] : []),
          ...q
            .split(/\s+/)
            .filter(Boolean)
            .map((word) => ({
              OR: [
                { firstName: { contains: word, mode: 'insensitive' as const } },
                { lastName: { contains: word, mode: 'insensitive' as const } },
              ],
            })),
        ],
      });
    }
    if (query.role === Role.CUSTOMER) {
      and.push({ roles: { none: { role: { in: PARTNER_OR_ADMIN } } } });
    } else if (query.role) {
      and.push({ roles: { some: { role: query.role } } });
    }
    if (query.status) and.push({ isActive: query.status === 'active' });
    return { AND: and };
  }

  private async customerStats(userId: string) {
    const [byStatus, delivered, first] = await Promise.all([
      this.prisma.order.groupBy({ by: ['status'], where: { customerId: userId }, _count: true }),
      this.prisma.order.aggregate({
        where: { customerId: userId, status: OrderStatus.DELIVERED },
        _sum: { total: true },
        _count: true,
      }),
      this.prisma.order.findFirst({
        where: { customerId: userId },
        orderBy: { createdAt: 'asc' },
        select: { createdAt: true },
      }),
    ]);
    const count = (status: OrderStatus) => byStatus.find((s) => s.status === status)?._count ?? 0;
    const spent = delivered._sum.total ?? 0;
    return {
      orders: byStatus.reduce((sum, s) => sum + s._count, 0),
      delivered: count(OrderStatus.DELIVERED),
      cancelled: count(OrderStatus.CANCELLED),
      spent: money(spent),
      avgTicket: money(delivered._count ? Math.round(spent / delivered._count) : 0),
      firstOrderAt: first?.createdAt ?? null,
    };
  }

  private async find(db: Prisma.TransactionClient, userId: string) {
    const user = await db.user.findUnique({
      where: { id: userId },
      select: { id: true, phone: true, isActive: true, roles: { select: { role: true } } },
    });
    if (!user) throw AppException.notFound('No encontramos ese usuario.');
    return user;
  }
}

const cannotChangeSelf = () =>
  new AppException(ErrorCode.CANNOT_CHANGE_SELF, HttpStatus.CONFLICT, 'No puedes hacer eso con tu propia cuenta.');
