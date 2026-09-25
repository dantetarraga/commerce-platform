import { HttpStatus, Injectable } from '@nestjs/common';
import { AppException, ErrorCode } from '../../common/exceptions/app.exception';
import { GeoPoint } from '../../common/utils/geo';
import { money, Money } from '../../common/utils/money';
import { PrismaService } from '../../database/prisma.service';
import type { Coupon, Prisma } from '../../generated/prisma/client';
import { OrderStatus } from '../../generated/prisma/enums';
import { storeDelivery } from '../stores/store-presenter';
import { StoresService } from '../stores/stores.service';
import { couponDiscount } from './coupon-discount';

type Db = Prisma.TransactionClient;

export interface CouponCheck {
  code: string;
  userId: string;
  storeId: string;
  cityId: string;
  subtotal: number;
  deliveryFee: number;
}

/** `POST /coupons/validate` → lo que la app guarda en la bolsa. */
export interface CouponQuote {
  code: string;
  discount: Money;
  label: string;
}

const formatSoles = (cents: number) => `S/ ${(cents / 100).toFixed(2)}`;

@Injectable()
export class CouponsService {
  constructor(
    private readonly prisma: PrismaService,
    private readonly stores: StoresService,
  ) {}

  /** Vista previa para la bolsa. El pedido vuelve a validar todo al crearse. */
  async quote(userId: string, code: string, storeId: string, subtotal: number, point?: GeoPoint): Promise<CouponQuote> {
    const { store, city } = await this.stores.load(storeId);
    const deliveryFee = storeDelivery(store, city, point ?? city.center).fee;
    const { coupon, discount } = await this.evaluate(this.prisma, {
      code,
      userId,
      storeId,
      cityId: city.id,
      subtotal,
      deliveryFee,
    });
    return { code: coupon.code, discount: money(discount, city.currency), label: coupon.label };
  }

  /**
   * Reglas del cupón, compartidas por la vista previa y la creación del
   * pedido: vigencia, ciudad y negocio, mínimo, límites global y por usuario,
   * y "solo primer pedido". `db` puede ser la transacción del pedido.
   */
  async evaluate(db: Db, check: CouponCheck, now = new Date()): Promise<{ coupon: Coupon; discount: number }> {
    const coupon = await db.coupon.findUnique({ where: { code: check.code.trim().toUpperCase() } });
    if (!coupon?.isActive || coupon.startsAt > now || coupon.endsAt < now) {
      throw couponError(ErrorCode.COUPON_INVALID, 'Ese cupón no existe o ya venció.');
    }
    if ((coupon.cityId && coupon.cityId !== check.cityId) || (coupon.storeId && coupon.storeId !== check.storeId)) {
      throw couponError(ErrorCode.COUPON_NOT_APPLICABLE, `${coupon.code} no aplica en este negocio.`);
    }
    if (check.subtotal < coupon.minOrderAmount) {
      throw couponError(
        ErrorCode.COUPON_MIN_NOT_REACHED,
        `${coupon.code} aplica desde ${formatSoles(coupon.minOrderAmount)} en productos.`,
      );
    }
    if (coupon.usageLimit !== null && coupon.usedCount >= coupon.usageLimit) {
      throw couponError(ErrorCode.COUPON_EXHAUSTED, 'Este cupón ya se agotó.');
    }

    const used = await db.couponRedemption.count({ where: { couponId: coupon.id, userId: check.userId } });
    if (used >= coupon.perUserLimit) {
      throw couponError(ErrorCode.COUPON_ALREADY_USED, 'Ya usaste este cupón.');
    }
    if (coupon.firstOrderOnly) {
      const previous = await db.order.count({
        where: { customerId: check.userId, status: { not: OrderStatus.CANCELLED } },
      });
      if (previous > 0) {
        throw couponError(ErrorCode.COUPON_FIRST_ORDER_ONLY, 'Este cupón es solo para tu primer pedido.');
      }
    }

    return { coupon, discount: couponDiscount(coupon, check) };
  }

  /**
   * Suma un uso solo si queda cupo (incremento condicional: dos pedidos
   * simultáneos no pasan el límite). Va dentro de la transacción del pedido.
   */
  async redeem(db: Db, couponId: string): Promise<void> {
    const updated = await db.$executeRaw`
      UPDATE "Coupon" SET "usedCount" = "usedCount" + 1
      WHERE "id" = ${couponId} AND ("usageLimit" IS NULL OR "usedCount" < "usageLimit")`;
    if (updated === 0) throw couponError(ErrorCode.COUPON_EXHAUSTED, 'Este cupón ya se agotó.');
  }
}

function couponError(code: ErrorCode, message: string) {
  return new AppException(code, HttpStatus.UNPROCESSABLE_ENTITY, message);
}
