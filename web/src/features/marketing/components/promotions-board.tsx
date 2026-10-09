import { useSuspenseQuery } from '@tanstack/react-query'
import { Image } from 'lucide-react'
import { useState } from 'react'
import { adminStoresQuery } from '@/app/api/lookups'
import { ConfirmActionDialog, type ConfirmAction } from '@/components/shared/confirm-action-dialog'
import { EmptyState } from '@/components/shared/empty-state'
import { SafeImage } from '@/components/shared/safe-image'
import { StatusBadge } from '@/components/shared/status-badge'
import { Button } from '@/components/ui/button'
import { dateTime } from '@/lib/datetime'
import { CAMPAIGN_STATUS_LABEL, campaignStatus, type Promotion } from '../model/marketing'
import { deletePromotionMutation } from '../mutations/marketing.mutations'
import { promotionsQuery } from '../queries/marketing.queries'

interface PromotionsBoardProps {
  cityId: string
  onEdit: (promotion: Promotion) => void
}

/** Banners de una ciudad, en el orden del carrusel. Suspende mientras cargan. */
export function PromotionsBoard({ cityId, onEdit }: PromotionsBoardProps) {
  const { data: promotions } = useSuspenseQuery(promotionsQuery(cityId))
  const { data: stores } = useSuspenseQuery(adminStoresQuery)
  const [action, setAction] = useState<ConfirmAction | null>(null)
  if (promotions.length === 0) {
    return (
      <EmptyState
        icon={Image}
        title='Sin banners'
        description='El inicio de la app muestra los banners vigentes de cada ciudad.'
      />
    )
  }
  return (
    <>
      <ul className='grid gap-4 sm:grid-cols-2 xl:grid-cols-3'>
        {promotions.map((promotion) => {
          const status = campaignStatus(promotion)
          const store = stores.find((item) => item.id === promotion.storeId)
          return (
            <li key={promotion.id} className='corner-exit-m bg-card overflow-hidden border'>
              <SafeImage
                src={promotion.imageUrl}
                loading='lazy'
                className='aspect-banner w-full object-cover'
              />
              <div className='space-y-3 p-4'>
                <div className='space-y-1'>
                  <p className='font-semibold'>{promotion.title}</p>
                  {promotion.subtitle && (
                    <p className='text-muted-foreground text-sm'>{promotion.subtitle}</p>
                  )}
                </div>
                <div className='flex flex-wrap items-center gap-2 text-xs'>
                  <StatusBadge active={status === 'active'}>
                    {CAMPAIGN_STATUS_LABEL[status]}
                  </StatusBadge>
                  <span className='text-muted-foreground'>
                    {dateTime.formatDate(promotion.startsAt)} –{' '}
                    {dateTime.formatDate(promotion.endsAt)} · orden {promotion.sortOrder}
                  </span>
                </div>
                {store && <p className='text-muted-foreground text-sm'>Abre {store.name}</p>}
                <div className='flex gap-2'>
                  <Button variant='outline' size='sm' onClick={() => onEdit(promotion)}>
                    Editar
                  </Button>
                  <Button
                    variant='ghost'
                    size='sm'
                    onClick={() =>
                      setAction({
                        title: 'Quitar banner',
                        description: `«${promotion.title}» dejará de verse en la app.`,
                        label: 'Quitar banner',
                        success: 'Banner eliminado.',
                        destructive: true,
                        mutation: deletePromotionMutation(promotion.id),
                      })
                    }
                  >
                    Quitar
                  </Button>
                </div>
              </div>
            </li>
          )
        })}
      </ul>
      {action && <ConfirmActionDialog action={action} onClose={() => setAction(null)} />}
    </>
  )
}
