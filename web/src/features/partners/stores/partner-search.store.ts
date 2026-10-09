import { createStore, useStore } from 'zustand'

interface PartnerSearchState {
  lastPhone: string
  actions: { remember: (phone: string) => void }
}

/** Último celular buscado, para encontrar al socio otra vez al volver a la página. */
const partnerSearchStore = createStore<PartnerSearchState>()((set) => ({
  lastPhone: '',
  actions: { remember: (lastPhone) => set({ lastPhone }) },
}))

export const useLastPartnerPhone = () => useStore(partnerSearchStore, (state) => state.lastPhone)
export const usePartnerSearchActions = () => useStore(partnerSearchStore, (state) => state.actions)
