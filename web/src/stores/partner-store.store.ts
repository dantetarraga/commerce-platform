import { createStore, useStore } from 'zustand'
import { createJSONStorage, persist } from 'zustand/middleware'

interface PartnerStoreState {
  /** Negocio elegido en el Portal Socios; vacío hasta que el socio elija. */
  storeId: string
  actions: { select: (storeId: string) => void }
}

/**
 * Un socio puede tener varios negocios. Menú, Mi tienda y Reportes trabajan sobre el
 * elegido; se recuerda entre visitas.
 */
export const partnerStoreStore = createStore<PartnerStoreState>()(
  persist((set) => ({ storeId: '', actions: { select: (storeId) => set({ storeId }) } }), {
    name: 'apamuy.panel.partner-store',
    storage: createJSONStorage(() => localStorage),
    partialize: ({ storeId }) => ({ storeId }),
  }),
)

export const useSelectedPartnerStoreId = () => useStore(partnerStoreStore, (state) => state.storeId)
export const usePartnerStoreActions = () => useStore(partnerStoreStore, (state) => state.actions)
