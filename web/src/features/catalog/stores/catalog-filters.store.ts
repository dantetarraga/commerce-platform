import { createStore, useStore } from 'zustand'
import { useShallow } from 'zustand/react/shallow'

export type PublicationFilter = 'all' | 'published' | 'draft'

interface CatalogFiltersState {
  search: string
  cityId: string
  status: PublicationFilter
  actions: {
    setSearch: (search: string) => void
    setCityId: (cityId: string) => void
    setStatus: (status: PublicationFilter) => void
  }
}

/** En memoria: los filtros siguen puestos al volver de la ficha de un negocio. */
const catalogFiltersStore = createStore<CatalogFiltersState>()((set) => ({
  search: '',
  cityId: '',
  status: 'all',
  actions: {
    setSearch: (search) => set({ search }),
    setCityId: (cityId) => set({ cityId }),
    setStatus: (status) => set({ status }),
  },
}))

export const useCatalogFilters = () =>
  useStore(
    catalogFiltersStore,
    useShallow(({ search, cityId, status }) => ({ search, cityId, status })),
  )
export const useCatalogFiltersActions = () =>
  useStore(catalogFiltersStore, (state) => state.actions)
