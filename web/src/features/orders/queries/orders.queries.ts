import { infiniteQueryOptions, queryOptions } from '@tanstack/react-query'
import { queryKeys } from '@/app/api'
import {
  getOrder,
  getOrdersBoard,
  getOrdersPage,
  type OrdersHistoryFilters,
} from '../actions/orders.actions'

/**
 * Tablero en vivo. Los cambios llegan por WebSocket; el sondeo de 30 s mantiene al día
 * los minutos de espera y cubre una conexión caída.
 */
export const ordersBoardQuery = (cityId: string) =>
  queryOptions({
    queryKey: queryKeys.orders.board(cityId),
    queryFn: ({ signal }) => getOrdersBoard(cityId, signal),
    refetchInterval: 30_000,
    staleTime: 5_000,
  })

export const ordersHistoryQuery = (filters: OrdersHistoryFilters) =>
  infiniteQueryOptions({
    queryKey: queryKeys.orders.history(filters),
    queryFn: ({ pageParam, signal }) => getOrdersPage(filters, pageParam, signal),
    initialPageParam: null as string | null,
    getNextPageParam: (page) => page.nextCursor,
  })

export const orderQuery = (id: string) =>
  queryOptions({
    queryKey: queryKeys.orders.detail(id),
    queryFn: ({ signal }) => getOrder(id, signal),
  })
