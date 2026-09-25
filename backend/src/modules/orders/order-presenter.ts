import { money } from '../../common/utils/money';
import { Prisma } from '../../generated/prisma/client';
import { PaymentMethodType } from '../../generated/prisma/enums';

export const orderInclude = {
  items: { include: { options: true }, orderBy: { id: 'asc' } },
  statusHistory: { orderBy: { createdAt: 'asc' } },
  store: { select: { logoUrl: true, ownerDisplayName: true } },
  courier: { include: { user: { select: { firstName: true, lastName: true, avatarUrl: true } } } },
  review: { select: { rating: true } },
  // Solo para las vistas del negocio y del repartidor.
  customer: { select: { firstName: true, lastName: true, phone: true } },
} satisfies Prisma.OrderInclude;

export type OrderWithDetails = Prisma.OrderGetPayload<{ include: typeof orderInclude }>;

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
    address: { title: order.addressTitle, street: order.addressStreet, reference: order.addressRef ?? '' },
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
  return {
    ...toOrderResponse(order),
    customer: {
      name: `${order.customer.firstName} ${order.customer.lastName}`.trim(),
      phone: order.customer.phone,
    },
    deliveryLocation: { lat: Number(order.deliveryLat), lng: Number(order.deliveryLng) },
    cancelReason: order.cancelReason,
  };
}
