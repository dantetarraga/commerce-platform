import { http } from '@/app/api'
import type { AdminOrder, OrdersBoard, OrdersPage, OrderStatus } from '../model/orders'

export interface OrdersHistoryFilters {
  cityId: string
  /** AAAA-MM-DD, en hora de Lima. */
  date: string
  status: OrderStatus | ''
  q: string
}

export async function getOrdersBoard(cityId: string, signal?: AbortSignal) {
  return (
    await http.get<OrdersBoard>('/admin/orders/board', {
      params: cityId ? { cityId } : undefined,
      signal,
    })
  ).data
}

export async function getOrdersPage(
  filters: OrdersHistoryFilters,
  cursor: string | null,
  signal?: AbortSignal,
) {
  const params = {
    date: filters.date,
    limit: 30,
    ...(filters.cityId && { cityId: filters.cityId }),
    ...(filters.status && { status: filters.status }),
    ...(filters.q.trim() && { q: filters.q.trim() }),
    ...(cursor && { cursor }),
  }
  return (await http.get<OrdersPage>('/admin/orders', { params, signal })).data
}

export async function getOrder(id: string, signal?: AbortSignal) {
  return (await http.get<AdminOrder>(`/admin/orders/${id}`, { signal })).data
}

export async function cancelOrder(id: string, reason: string) {
  return (await http.post<AdminOrder>(`/admin/orders/${id}/cancel`, { reason })).data
}
