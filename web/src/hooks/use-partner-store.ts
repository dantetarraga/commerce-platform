import { useSuspenseQuery } from '@tanstack/react-query'
import { ownStoresQuery } from '@/app/api/lookups'
import { usePartnerStoreActions, useSelectedPartnerStoreId } from '@/stores/partner-store.store'

/**
 * Negocios del socio y el elegido. Si el guardado ya no es suyo (o no eligió), el
 * primero. `store` es `null` solo si no tiene negocios. Suspende mientras carga.
 */
export function usePartnerStore() {
  const { data: stores } = useSuspenseQuery(ownStoresQuery)
  const selectedId = useSelectedPartnerStoreId()
  const { select } = usePartnerStoreActions()
  const store = stores.find((item) => item.id === selectedId) ?? stores[0] ?? null
  return { stores, store, select }
}
