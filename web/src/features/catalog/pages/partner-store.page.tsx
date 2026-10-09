import { PageHeader } from '@/components/shared/page-header'
import { PartnerStorePicker } from '@/components/shared/partner-store-picker'
import { QueryBoundary } from '@/components/shared/query-boundary'
import { StoreDetailSkeleton } from '../components/catalog-skeletons'
import { PartnerCatalog } from '../components/partner-catalog'
import { StoreProfileCard } from '../components/store-profile-card'
import { StoreSchedulesCard } from '../components/store-schedules-card'
import { CatalogScopeContext } from '../model/catalog-scope'

export function PartnerStorePage() {
  return (
    <CatalogScopeContext value='merchant'>
      <div className='space-y-8'>
        <PageHeader
          eyebrow='Portal Socios'
          title='Mi tienda'
          description='Cómo te ven tus clientes, tus horarios y la pausa de pedidos.'
          actions={
            <QueryBoundary fallback={null}>
              <PartnerStorePicker />
            </QueryBoundary>
          }
        />
        <QueryBoundary fallback={<StoreDetailSkeleton />}>
          <PartnerCatalog>
            {(store) => (
              <div className='space-y-6'>
                <StoreProfileCard store={store} />
                <StoreSchedulesCard store={store} />
              </div>
            )}
          </PartnerCatalog>
        </QueryBoundary>
      </div>
    </CatalogScopeContext>
  )
}
