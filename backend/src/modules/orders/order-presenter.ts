import { money } from '../../common/utils/money';
import { Prisma } from '../../generated/prisma/client';
import { OrderStatus, PaymentMethodType } from '../../generated/prisma/enums';

export const orderInclude = {
  items: { include: { options: true }, orderBy: { id: 'asc' } },
  statusHistory: { orderBy: { createdAt: 'asc' } },
  store: {
    select: { logoUrl: true, ownerDisplayName: true, addressLine: true, phone: true, latitude: true, longitude: true },
  },
  courier: { include: { user: { select: { firstName: true, lastName: true, avatarUrl: true } } } },
  review: { select: { rating: true } },
  // Solo para las vistas del negocio y del repartidor.
  customer: { select: { firstName: true, lastName: true, phone: true } },
  payment: { select: { collectedMethod: true, collectedAmount: true, collectedAt: true } },
} satisfies Prisma.OrderInclude;

export type OrderWithDetails = Prisma.OrderGetPayload<{ include: typeof orderInclude }>;

/** Una posición de más de 2 minutos ya no dice dónde está el repartidor. */
export const COURIER_LOCATION_MAX_AGE_MS = 2 * 60_000;

/**
 * Dónde va el repartidor, solo mientras lleva el pedido (ON_THE_WAY) y si la
 * posición es reciente. Antes de salir y después de entregar no se muestra.
 */
export function courierLocation(
  status: OrderStatus,
  courier: { currentLat: Prisma.Decimal | null; currentLng: Prisma.Decimal | null; lastLocationAt: Date | null } | null,
  now: Date,
) {
  if (status !== OrderStatus.ON_THE_WAY || !courier?.lastLocationAt) return null;
  if (courier.currentLat === null || courier.currentLng === null) return null;
  if (now.getTime() - courier.lastLocationAt.getTime() > COURIER_LOCATION_MAX_AGE_MS) return null;
  return {
    lat: Number(courier.currentLat),
    lng: Number(courier.currentLng),
    at: courier.lastLocationAt.toISOString(),
  };
}

/**
 * JSON de pedido que lee la app (`OrderJson.fromJson`). Se arma solo con los
 * snapshots guardados al crear el pedido, salvo logo y dueño del negocio.
 */
export function toOrderResponse(order: OrderWithDetails) {
  const m = (amount: number) => money(amount, order.currency);
  const courier = order.courier;
  return {
    id: order.id,
    code: order.code,
    store: {
      id: order.storeId,
      name: order.storeName,
      logoUrl: order.store.logoUrl,
      ownerName: order.store.ownerDisplayName,
      location: { lat: Number(order.store.latitude), lng: Number(order.store.longitude) },
    },
    lines: order.items.map((item) => ({
      productId: item.productId,
      name: item.productName,
      quantity: item.quantity,
      total: m(item.subtotal),
      description: [item.variantName, ...item.options.map((o) => o.valueName)].filter(Boolean).join(' · '),
    })),
    subtotal: m(order.subtotal),
    deliveryFee: m(order.deliveryFee),
    discount: m(order.discountTotal),
    tip: m(order.tip),
    total: m(order.total),
    notes: order.notes ?? '',
    address: {
      title: order.addressTitle,
      street: order.addressStreet,
      reference: order.addressRef ?? '',
      location: { lat: Number(order.deliveryLat), lng: Number(order.deliveryLng) },
    },
    payment: {
      type: order.paymentMethod,
      changeFor:
        order.paymentMethod === PaymentMethodType.CASH && order.cashChangeFor !== null ? m(order.cashChangeFor) : null,
    },
    status: order.status,
    events: order.statusHistory.map((h) => ({ status: h.toStatus, at: h.createdAt.toISOString() })),
    placedAt: order.createdAt.toISOString(),
    courier: courier && {
      name: `${courier.user.firstName} ${courier.user.lastName}`.trim(),
      vehicle: courier.vehicleLabel,
      since: courier.activeSince,
      avatarUrl: courier.user.avatarUrl,
      location: courierLocation(order.status, courier, new Date()),
    },
    estimatedArrival: order.estimatedAt?.toISOString() ?? null,
    scheduledFor: order.scheduledFor?.toISOString() ?? null,
    rating: order.review?.rating ?? null,
  };
}

/**
 * Vista del negocio y del repartidor: el pedido más a quién y dónde
 * entregarlo. Nunca se usa para el cliente.
 */
export function toStaffOrderResponse(order: OrderWithDetails) {
  const base = toOrderResponse(order);
  const payment = order.payment;
  return {
    ...base,
    // `lines` sigue el orden de `order.items`: se suma la nota de cada producto.
    lines: base.lines.map((line, i) => ({ ...line, notes: order.items[i].notes ?? '' })),
    customer: {
      name: `${order.customer.firstName} ${order.customer.lastName}`.trim(),
      phone: order.customer.phone,
    },
    deliveryLocation: { lat: Number(order.deliveryLat), lng: Number(order.deliveryLng) },
    // Dónde recoger: datos actuales del negocio (no hay snapshot de dirección).
    pickup: {
      address: order.store.addressLine,
      phone: order.store.phone,
      location: { lat: Number(order.store.latitude), lng: Number(order.store.longitude) },
    },
    distanceMeters: order.distanceMeters,
    cancelReason: order.cancelReason,
    collection:
      payment?.collectedMethod && payment.collectedAmount !== null && payment.collectedAt
        ? {
            method: payment.collectedMethod,
            amount: money(payment.collectedAmount, order.currency),
            collectedAt: payment.collectedAt.toISOString(),
          }
        : null,
  };
}
