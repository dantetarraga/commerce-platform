import { HttpStatus, Injectable, Logger } from '@nestjs/common';
import type { CursorQueryDto } from '../../common/dto/cursor-query.dto';
import { AppException, ErrorCode } from '../../common/exceptions/app.exception';
import { zonedTime } from '../../common/time';
import { isOpenAt } from '../../common/utils/schedule';
import { PrismaService } from '../../database/prisma.service';
import { Prisma } from '../../generated/prisma/client';
import { OrderStatus, PaymentMethodType, Role } from '../../generated/prisma/enums';
import { inCoverage, type CityContext } from '../cities/cities.service';
import { CouponsService } from '../coupons/coupons.service';
import { isStoreOpen, StoreForSummary, storeDelivery } from '../stores/store-presenter';
import { StoresService } from '../stores/stores.service';
import type { RateOrderDto } from './dto/order-queries.dto';
import type { PlaceOrderDto } from './dto/place-order.dto';
import { MAX_TIP } from './dto/place-order.dto';
import { orderTotals, priceItem, PricedItem, unavailable } from './order-pricing';
import { orderInclude, toOrderResponse } from './order-presenter';

const MAX_SCHEDULE_DAYS = 7;
const DAY_MS = 24 * 60 * 60 * 1000;
const ORDER_NOT_FOUND = 'No encontramos ese pedido.';

const productForPricing = {
  variants: true,
  options: { include: { values: true } },
} satisfies Prisma.ProductInclude;

@Injectable()
export class OrdersService {
  private readonly logger = new Logger(OrdersService.name);

  constructor(
    private readonly prisma: PrismaService,
    private readonly stores: StoresService,
    private readonly coupons: CouponsService,
  ) {}

  /**
   * Crea el pedido a partir de la bolsa del dispositivo. Todo se recalcula
   * aquí: disponibilidad, horario, cobertura, precios, cupón y totales.
   * Con `Idempotency-Key`, repetir la misma request devuelve el mismo pedido.
   */
  async place(userId: string, dto: PlaceOrderDto, idempotencyKey?: string, now = new Date()) {
    if (idempotencyKey) {
      const existing = await this.findByIdempotencyKey(userId, idempotencyKey);
      if (existing) return existing;
    }

    // Por ahora solo contraentrega: sin pasarela, la tarjeta no se puede cobrar.
    if (dto.payment.type === PaymentMethodType.CARD) {
      throw new AppException(
        ErrorCode.PAYMENT_METHOD_UNAVAILABLE,
        HttpStatus.UNPROCESSABLE_ENTITY,
        'Por ahora solo aceptamos efectivo, Yape o Plin al recibir.',
      );
    }

    const { store, city } = await this.stores.load(dto.storeId);
    const scheduledFor = this.checkSchedule(store, city, dto.scheduledFor, now);

    const destination = { lat: dto.address.latitude, lng: dto.address.longitude };
    if (!inCoverage(city, destination)) {
      throw new AppException(
        ErrorCode.ADDRESS_OUT_OF_COVERAGE,
        HttpStatus.UNPROCESSABLE_ENTITY,
        `Esa dirección está fuera de la zona de reparto de ${city.name}.`,
      );
    }
    const delivery = storeDelivery(store, city, destination);
    if (!delivery.deliversToYou) {
      throw new AppException(
        ErrorCode.ADDRESS_OUT_OF_COVERAGE,
        HttpStatus.UNPROCESSABLE_ENTITY,
        `${store.name} todavía no llega a esa dirección.`,
      );
    }

    const lines = await this.priceLines(store.id, dto);
    const subtotal = lines.reduce((sum, line) => sum + line.subtotal, 0);
    if (subtotal < store.minOrderAmount) {
      throw new AppException(
        ErrorCode.MIN_ORDER_NOT_REACHED,
        HttpStatus.UNPROCESSABLE_ENTITY,
        'Aún no llegas al pedido mínimo.',
        { minOrderAmount: store.minOrderAmount },
      );
    }

    const tip = Math.min(dto.tip?.amount ?? 0, MAX_TIP);
    const coupon = dto.couponCode
      ? await this.coupons.evaluate(this.prisma, {
          code: dto.couponCode,
          userId,
          storeId: store.id,
          cityId: city.id,
          subtotal,
          deliveryFee: delivery.fee,
        })
      : null;
    const discount = coupon?.discount ?? 0;
    const { total, tax } = orderTotals({ subtotal, deliveryFee: delivery.fee, discount, tip });

    const cashChangeFor = dto.payment.type === PaymentMethodType.CASH ? (dto.payment.changeFor?.amount ?? null) : null;
    if (cashChangeFor !== null && cashChangeFor < total) {
      throw new AppException(
        ErrorCode.CASH_CHANGE_TOO_LOW,
        HttpStatus.UNPROCESSABLE_ENTITY,
        'El monto con el que pagas debe cubrir el total.',
      );
    }

    const startsAt = scheduledFor ?? now;
    try {
      const orderId = await this.prisma.$transaction(async (tx) => {
        await this.reserveStock(tx, lines);
        if (coupon) await this.coupons.redeem(tx, coupon.coupon.id);

        const [{ code }] = await tx.$queryRaw<{ code: string }[]>`SELECT '#' || nextval('order_code_seq') AS code`;
        const order = await tx.order.create({
          data: {
            code,
            idempotencyKey,
            customerId: userId,
            storeId: store.id,
            cityId: city.id,
            addressTitle: dto.address.title,
            addressStreet: dto.address.street,
            addressRef: dto.address.reference || null,
            deliveryLat: dto.address.latitude,
            deliveryLng: dto.address.longitude,
            storeName: store.name,
            subtotal,
            deliveryFee: delivery.fee,
            discountTotal: discount,
            tip,
            taxTotal: tax,
            total,
            currency: city.currency,
            distanceMeters: Math.round(delivery.distanceKm * 1000),
            couponId: coupon?.coupon.id,
            couponCode: coupon?.coupon.code,
            paymentMethod: dto.payment.type,
            cashChangeFor,
            notes: dto.notes || null,
            scheduledFor,
            estimatedAt: new Date(startsAt.getTime() + delivery.etaMinutes * 60_000),
            items: {
              create: lines.map((line) => ({
                productId: line.product.id,
                variantId: line.priced.variantId,
                productName: line.product.name,
                variantName: line.priced.variantName,
                imageUrl: line.product.imageUrl,
                unitPrice: line.priced.unitPrice,
                quantity: line.quantity,
                subtotal: line.subtotal,
                notes: line.notes,
                options: { create: line.priced.options },
              })),
            },
            statusHistory: {
              create: { toStatus: OrderStatus.RECEIVED, changedById: userId, changedByRole: Role.CUSTOMER },
            },
            // Efectivo, Yape y Plin se pagan al recibir el pedido.
            payment: {
              create: {
                method: dto.payment.type,
                provider: 'on_delivery',
                amount: total,
                currency: city.currency,
              },
            },
          },
          select: { id: true },
        });
        if (coupon) {
          await tx.couponRedemption.create({ data: { couponId: coupon.coupon.id, userId, orderId: order.id } });
        }
        return order.id;
      });
      return this.detail(userId, orderId);
    } catch (error) {
      // Dos requests con la misma key a la vez: gana una y la otra devuelve ese pedido.
      if (idempotencyKey && isUniqueViolation(error)) {
        const existing = await this.findByIdempotencyKey(userId, idempotencyKey);
        if (existing) return existing;
      }
      throw error;
    }
  }

  async list(userId: string, query: CursorQueryDto) {
    const { orders, nextCursor } = await this.page({ customerId: userId }, query);
    return { items: orders.map(toOrderResponse), nextCursor };
  }

  /** Página por cursor, del más reciente al más antiguo. La usan también negocio y courier. */
  async page(where: Prisma.OrderWhereInput, query: CursorQueryDto) {
    const orders = await this.prisma.order.findMany({
      where,
      orderBy: [{ createdAt: 'desc' }, { id: 'desc' }],
      take: query.limit + 1,
      ...(query.cursor && { cursor: { id: query.cursor }, skip: 1 }),
      include: orderInclude,
    });
    const page = orders.slice(0, query.limit);
    return { orders: page, nextCursor: orders.length > query.limit ? page[page.length - 1].id : null };
  }

  /** Solo pedidos del usuario; uno ajeno responde 404 para no revelar que existe. */
  async detail(userId: string, orderId: string) {
    const order = await this.prisma.order.findFirst({
      where: { id: orderId, customerId: userId },
      include: orderInclude,
    });
    if (!order) throw AppException.notFound(ORDER_NOT_FOUND);
    return toOrderResponse(order);
  }

  /** Una calificación por pedido entregado; actualiza el rating del negocio. */
  async rate(userId: string, orderId: string, dto: RateOrderDto) {
    const order = await this.prisma.order.findFirst({
      where: { id: orderId, customerId: userId },
      select: { id: true, storeId: true, status: true, review: { select: { id: true } } },
    });
    if (!order) throw AppException.notFound(ORDER_NOT_FOUND);
    if (order.status !== OrderStatus.DELIVERED) {
      throw new AppException(
        ErrorCode.ORDER_NOT_DELIVERED,
        HttpStatus.CONFLICT,
        'Podrás calificar cuando llegue tu pedido.',
      );
    }
    if (order.review) throw alreadyRated();

    try {
      await this.prisma.$transaction(async (tx) => {
        await tx.review.create({
          data: { orderId, userId, storeId: order.storeId, rating: dto.rating, comment: dto.comment || null },
        });
        // Promedio incremental en SQL: dos calificaciones simultáneas no se pisan.
        await tx.$executeRaw`
          UPDATE "Store"
          SET "ratingAvg" = round((("ratingAvg" * "ratingCount") + ${dto.rating}) / ("ratingCount" + 1), 1),
              "ratingCount" = "ratingCount" + 1
          WHERE "id" = ${order.storeId}`;
      });
    } catch (error) {
      if (isUniqueViolation(error)) throw alreadyRated();
      throw error;
    }
    return this.detail(userId, orderId);
  }

  /**
   * Sin `scheduledFor`, el negocio tiene que estar abierto ahora. Programado:
   * a futuro, hasta 7 días, y en un horario en que el negocio atiende.
   */
  private checkSchedule(store: StoreForSummary, city: CityContext, raw: string | null | undefined, now: Date) {
    const closed = () =>
      new AppException(
        ErrorCode.STORE_CLOSED,
        HttpStatus.CONFLICT,
        'El negocio cerró hace un momento. Tu bolsa sigue guardada.',
      );
    if (!store.isAcceptingOrders) throw closed();
    if (!raw) {
      if (!isStoreOpen(store, city, now)) throw closed();
      return null;
    }

    const at = new Date(raw);
    const invalid = (message: string) =>
      new AppException(ErrorCode.SCHEDULE_INVALID, HttpStatus.UNPROCESSABLE_ENTITY, message);
    if (at <= now) throw invalid('Esa hora ya pasó. Elige otra.');
    if (at.getTime() - now.getTime() > MAX_SCHEDULE_DAYS * DAY_MS) {
      throw invalid('Puedes programar hasta 7 días antes.');
    }
    if (!isOpenAt(store.schedules, zonedTime.localTime(at, city.timezone))) {
      throw invalid(`${store.name} no atiende a esa hora.`);
    }
    return at;
  }

  private async priceLines(storeId: string, dto: PlaceOrderDto) {
    const ids = [...new Set(dto.items.map((item) => item.productId))];
    const products = await this.prisma.product.findMany({
      where: { id: { in: ids }, storeId, deletedAt: null },
      include: productForPricing,
    });
    const byId = new Map(products.map((p) => [p.id, p]));

    return dto.items.map((item) => {
      const product = byId.get(item.productId);
      if (!product) {
        throw new AppException(
          ErrorCode.PRODUCT_UNAVAILABLE,
          HttpStatus.CONFLICT,
          'Un producto de tu bolsa ya no está disponible.',
          { productId: item.productId },
        );
      }
      if (!product.isAvailable || product.stock === 0) throw unavailable(product);
      const priced: PricedItem = priceItem(product, item);
      return {
        product,
        priced,
        quantity: item.quantity,
        subtotal: priced.unitPrice * item.quantity,
        notes: item.notes || null,
      };
    });
  }

  /** Descuento condicional de stock: si no alcanza, se revierte todo el pedido. */
  private async reserveStock(
    tx: Prisma.TransactionClient,
    lines: { product: { id: string; name: string; stock: number | null }; quantity: number }[],
  ) {
    const needed = new Map<string, { name: string; quantity: number }>();
    for (const line of lines) {
      if (line.product.stock === null) continue;
      const entry = needed.get(line.product.id) ?? { name: line.product.name, quantity: 0 };
      entry.quantity += line.quantity;
      needed.set(line.product.id, entry);
    }
    for (const [productId, { name, quantity }] of needed) {
      const { count } = await tx.product.updateMany({
        where: { id: productId, stock: { gte: quantity } },
        data: { stock: { decrement: quantity } },
      });
      if (count === 0) {
        throw new AppException(
          ErrorCode.PRODUCT_OUT_OF_STOCK,
          HttpStatus.CONFLICT,
          `No queda stock suficiente de ${name}.`,
          { productId },
        );
      }
    }
  }

  private async findByIdempotencyKey(userId: string, idempotencyKey: string) {
    const order = await this.prisma.order.findUnique({
      where: { customerId_idempotencyKey: { customerId: userId, idempotencyKey } },
      include: orderInclude,
    });
    if (order) this.logger.log(`Pedido repetido por Idempotency-Key: ${order.code}`);
    return order && toOrderResponse(order);
  }
}

function alreadyRated() {
  return new AppException(ErrorCode.ORDER_ALREADY_RATED, HttpStatus.CONFLICT, 'Ya calificaste este pedido.');
}

function isUniqueViolation(error: unknown) {
  return error instanceof Prisma.PrismaClientKnownRequestError && error.code === 'P2002';
}
