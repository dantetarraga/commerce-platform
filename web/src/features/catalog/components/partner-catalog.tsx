import { useSuspenseQuery } from '@tanstack/react-query'
import { Store } from 'lucide-react'
import type { ReactNode } from 'react'
import { EmptyState } from '@/components/shared/empty-state'
import { usePartnerStore } from '@/hooks/use-partner-store'
import type { StoreDetail } from '../model/catalog'
import { storeQuery } from '../queries/catalog.queries'

/**
 * Carga el negocio elegido en el Portal Socios y se lo pasa a [children]. Suspende
 * mientras carga; sin negocios, lo explica.
 */
export function PartnerCatalog({ children }: { children: (store: StoreDetail) => ReactNode }) {
  const { store } = usePartnerStore()
  if (!store) {
    return (
      <EmptyState
        icon={Store}
        title='Todavía no tienes un negocio'
        description='El equipo Apamuy crea tu negocio al afiliarte. Escríbenos si ya lo hiciste.'
      />
    )
  }
  return <PartnerStoreDetail storeId={store.id}>{children}</PartnerStoreDetail>
}

function PartnerStoreDetail({
  storeId,
  children,
}: {
  storeId: string
  children: (store: StoreDetail) => ReactNode
}) {
  const { data: store } = useSuspenseQuery(storeQuery(storeId, 'merchant'))
  return children(store)
}
