import { HttpStatus, Injectable } from '@nestjs/common';
import { AppException, ErrorCode } from '../../../common/exceptions/app.exception';
import { DEFAULT_TIMEZONE, zonedTime } from '../../../common/time';
import { money } from '../../../common/utils/money';
import { PrismaService } from '../../../database/prisma.service';
import { Prisma } from '../../../generated/prisma/client';
import { OrderStatus } from '../../../generated/prisma/enums';
import { effectiveRateBps, FALLBACK_RATE_BPS } from './commission';
import { SettlementWeek, settlementWeek, weekStartDate, weekStartOf } from './settlement-week';
import { owedTo, settlementStatus, settleWeek, WeeklySettlement } from './weekly-settlement';

const SETTINGS_ID = 1;

const userName = (user: { id: string; firstName: string; lastName: string } | null) =>
  user && { id: user.id, name: `${user.firstName} ${user.lastName}`.trim() };

const byWhom = { select: { id: true, firstName: true, lastName: true } } as const;

export interface SettlementScope {
  cityId?: string;
  /** El dueño: solo sus negocios, y aparecen aunque no hayan vendido esa semana. */
  ownerId?: string;
  storeId?: string;
}

/**
 * Comisión de Apamuy (por defecto y por negocio) y liquidaciones semanales:
 * vendido − comisión − lo que cobró el propio negocio = saldo de cada semana.
 */
@Injectable()
export class AdminSettlementsService {
  constructor(private readonly prisma: PrismaService) {}

  async defaultRate(): Promise<number> {
    const settings = await this.prisma.platformSettings.findUnique({
      where: { id: SETTINGS_ID },
      select: { commissionRateBps: true },
    });
    return settings?.commissionRateBps ?? FALLBACK_RATE_BPS;
  }

  async commissionSettings() {
    const settings = await this.prisma.platformSettings.findUnique({
      where: { id: SETTINGS_ID },
      select: { commissionRateBps: true, updatedAt: true, updatedBy: byWhom },
    });
    return {
      rateBps: settings?.commissionRateBps ?? FALLBACK_RATE_BPS,
      updatedAt: settings?.updatedAt ?? null,
      updatedBy: userName(settings?.updatedBy ?? null),
    };
  }

  /** Solo afecta a los pedidos nuevos: cada pedido guarda la comisión con la que se creó. */
  async setDefaultRate(rateBps: number, adminId: string) {
    await this.prisma.platformSettings.upsert({
      where: { id: SETTINGS_ID },
      create: { id: SETTINGS_ID, commissionRateBps: rateBps, updatedById: adminId },
      update: { commissionRateBps: rateBps, updatedById: adminId },
    });
    return this.commissionSettings();
  }

  async storeCommission(storeId: string) {
    const store = await this.prisma.store.findFirst({
      where: { id: storeId, deletedAt: null },
      select: { commissionRateBps: true },
    });
    if (!store) throw AppException.notFound('No encontramos ese negocio.');
    const defaultRateBps = await this.defaultRate();
    return {
      storeId,
      rateBps: store.commissionRateBps,
      defaultRateBps,
      effectiveRateBps: effectiveRateBps(store.commissionRateBps, defaultRateBps),
    };
  }

  async setStoreCommission(storeId: string, rateBps: number | null) {
    const { count } = await this.prisma.store.updateMany({
      where: { id: storeId, deletedAt: null },
      data: { commissionRateBps: rateBps },
    });
    if (count === 0) throw AppException.notFound('No encontramos ese negocio.');
    return this.storeCommission(storeId);
  }

  /** Una fila por negocio con lo de esa semana. Sin `ownerId` (admin), solo los que vendieron o se liquidaron. */
  async week(date: string | undefined, scope: SettlementScope, now = new Date()) {
    const week = this.weekOf(date, now);
    if (scope.storeId && scope.ownerId) await this.assertOwned(scope.storeId, scope.ownerId);
    const rows = await this.rows(week, scope, now);
    const sum = (pick: (row: (typeof rows)[number]) => number) => rows.reduce((total, row) => total + pick(row), 0);
    return {
      week,
      totals: {
        delivered: sum((r) => r.delivered),
        sales: money(sum((r) => r.sales)),
        commission: money(sum((r) => r.commission)),
        collectedByStore: money(sum((r) => r.collectedByStore)),
        toStores: money(sum((r) => Math.max(r.balance, 0))),
        toApamuy: money(sum((r) => Math.max(-r.balance, 0))),
        pendingCount: rows.filter((r) => r.status === 'PENDING').length,
      },
      stores: rows.map(rowJson),
    };
  }

  /** La semana de un negocio con sus pedidos y la comisión de cada uno. */
  async detail(storeId: string, date: string | undefined, ownerId?: string, now = new Date()) {
    const week = this.weekOf(date, now);
    if (ownerId) await this.assertOwned(storeId, ownerId);
    const row = await this.storeRow(week, storeId, now);
    return {
      week,
      ...rowJson(row),
      orders: row.orders.map((order) => ({
        id: order.id,
        code: order.code,
        deliveredAt: order.deliveredAt,
        subtotal: money(order.subtotal),
        rateBps: order.rateBps,
        commission: money(order.commission),
        collectedByStore: money(order.collectedByStore),
      })),
    };
  }

  /** Registra que la semana ya se pagó, con las cifras de ese momento. */
  async markPaid(storeId: string, date: string, adminId: string, now = new Date()) {
    const week = this.weekOf(date, now);
    const row = await this.storeRow(week, storeId, now);
    if (row.status === 'PAID') throw alreadyPaid();
    if (row.status === 'OPEN') {
      throw new AppException(
        ErrorCode.SETTLEMENT_WEEK_OPEN,
        HttpStatus.UNPROCESSABLE_ENTITY,
        'La semana aún no termina: se liquida desde el lunes siguiente.',
      );
    }
    if (row.status === 'EMPTY') {
      throw new AppException(
        ErrorCode.SETTLEMENT_EMPTY,
        HttpStatus.UNPROCESSABLE_ENTITY,
        'Ese negocio no tuvo pedidos entregados esa semana.',
      );
    }
    try {
      await this.prisma.storeSettlement.create({
        data: {
          storeId,
          weekStart: weekStartDate(week.start),
          deliveredCount: row.delivered,
          sales: row.sales,
          commission: row.commission,
          collectedByStore: row.collectedByStore,
          balance: row.balance,
          currency: money(0).currency,
          paidById: adminId,
          paidAt: now,
        },
      });
    } catch (error) {
      if (error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2002') throw alreadyPaid();
      throw error;
    }
    return this.detail(storeId, week.start, undefined, now);
  }

  /** `current`: la semana en curso, para que el panel no deje avanzar más. */
  private weekOf(date: string | undefined, now: Date): SettlementWeek & { current: boolean } {
    const today = zonedTime.localDate(now, DEFAULT_TIMEZONE);
    const week = settlementWeek(date ?? today);
    return { ...week, current: week.start === weekStartOf(today) };
  }

  private async assertOwned(storeId: string, ownerId: string) {
    const count = await this.prisma.store.count({ where: { id: storeId, ownerId, deletedAt: null } });
    if (count === 0) throw AppException.notFound('No encontramos ese negocio.');
  }

  private async storeRow(week: SettlementWeek, storeId: string, now: Date) {
    const [row] = await this.rows(week, { storeId }, now);
    if (!row) throw AppException.notFound('No encontramos ese negocio.');
    return row;
  }

  private async rows(week: SettlementWeek, scope: SettlementScope, now: Date) {
    const start = zonedTime.dayRange(week.start, DEFAULT_TIMEZONE).start;
    const end = zonedTime.dayRange(week.next, DEFAULT_TIMEZONE).start;
    const storeWhere: Prisma.StoreWhereInput = {
      ...(scope.cityId && { cityId: scope.cityId }),
      ...(scope.ownerId && { ownerId: scope.ownerId }),
      ...(scope.storeId && { id: scope.storeId }),
    };
    const [orders, paid, idle, defaultRateBps] = await Promise.all([
      this.prisma.order.findMany({
        where: { status: OrderStatus.DELIVERED, deliveredAt: { gte: start, lt: end }, store: storeWhere },
        select: {
          id: true,
          code: true,
          storeId: true,
          subtotal: true,
          commissionRateBps: true,
          deliveredAt: true,
          payment: { select: { collectedById: true, collectedAmount: true } },
        },
      }),
      this.prisma.storeSettlement.findMany({
        where: { weekStart: weekStartDate(week.start), store: storeWhere },
        select: { storeId: true, balance: true, paidAt: true, paidBy: byWhom },
      }),
      scope.ownerId || scope.storeId
        ? this.prisma.store.findMany({ where: { ...storeWhere, deletedAt: null }, select: { id: true } })
        : [],
      this.defaultRate(),
    ]);

    const storeIds = [
      ...new Set([...orders.map((o) => o.storeId), ...paid.map((p) => p.storeId), ...idle.map((s) => s.id)]),
    ];
    const stores = await this.prisma.store.findMany({
      where: { id: { in: storeIds } },
      select: { id: true, name: true, ownerId: true, commissionRateBps: true },
    });
    return stores
      .map((store) => {
        const settlement = settleWeek(
          orders.flatMap((o) =>
            o.storeId === store.id && o.deliveredAt
              ? [
                  {
                    id: o.id,
                    code: o.code,
                    deliveredAt: o.deliveredAt,
                    subtotal: o.subtotal,
                    commissionRateBps: o.commissionRateBps,
                    collectedById: o.payment?.collectedById ?? null,
                    collectedAmount: o.payment?.collectedAmount ?? null,
                  },
                ]
              : [],
          ),
          { ownerId: store.ownerId, fallbackRateBps: effectiveRateBps(store.commissionRateBps, defaultRateBps) },
        );
        const record = paid.find((p) => p.storeId === store.id) ?? null;
        return {
          storeId: store.id,
          name: store.name,
          ...settlement,
          status: settlementStatus(end, now, record !== null, settlement.delivered),
          paid: record && { at: record.paidAt, by: userName(record.paidBy), balance: record.balance },
        };
      })
      .sort((a, b) => b.sales - a.sales || a.name.localeCompare(b.name, 'es'));
  }
}

type Row = WeeklySettlement & {
  storeId: string;
  name: string;
  status: ReturnType<typeof settlementStatus>;
  paid: { at: Date; by: { id: string; name: string } | null; balance: number } | null;
};

function rowJson(row: Row) {
  return {
    storeId: row.storeId,
    name: row.name,
    delivered: row.delivered,
    sales: money(row.sales),
    commission: money(row.commission),
    collectedByStore: money(row.collectedByStore),
    balance: money(row.balance),
    owedTo: owedTo(row.balance),
    status: row.status,
    paid: row.paid && { at: row.paid.at, by: row.paid.by, balance: money(row.paid.balance) },
  };
}

const alreadyPaid = () =>
  new AppException(ErrorCode.SETTLEMENT_ALREADY_PAID, HttpStatus.CONFLICT, 'Esa semana ya se marcó como pagada.');
