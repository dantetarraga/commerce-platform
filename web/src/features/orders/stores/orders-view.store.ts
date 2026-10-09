import { createStore, useStore } from 'zustand'
import { useShallow } from 'zustand/react/shallow'
import { dateTime } from '@/lib/datetime'
import type { OrderStatus } from '../model/orders'

export type OrdersTab = 'live' | 'history'

interface OrdersViewState {
  tab: OrdersTab
  cityId: string
  date: string
  status: OrderStatus | ''
  q: string
  actions: {
    setTab: (tab: OrdersTab) => void
    setCityId: (cityId: string) => void
    setDate: (date: string) => void
    setStatus: (status: OrderStatus | '') => void
    setQuery: (q: string) => void
  }
}

/** En memoria: la ciudad y los filtros siguen puestos al volver a Pedidos. */
const ordersViewStore = createStore<OrdersViewState>()((set) => ({
  tab: 'live',
  cityId: '',
  date: dateTime.toApiDate(),
  status: '',
  q: '',
  actions: {
    setTab: (tab) => set({ tab }),
    setCityId: (cityId) => set({ cityId }),
    setDate: (date) => set({ date }),
    setStatus: (status) => set({ status }),
    setQuery: (q) => set({ q }),
  },
}))

export const useOrdersTab = () => useStore(ordersViewStore, (state) => state.tab)
export const useOrdersCity = () => useStore(ordersViewStore, (state) => state.cityId)
export const useHistoryFilters = () =>
  useStore(
    ordersViewStore,
    useShallow(({ cityId, date, status, q }) => ({ cityId, date, status, q })),
  )
export const useOrdersViewActions = () => useStore(ordersViewStore, (state) => state.actions)
