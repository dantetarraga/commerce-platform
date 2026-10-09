import { useSuspenseQuery } from '@tanstack/react-query'
import { TicketPercent } from 'lucide-react'
import { useState } from 'react'
import { citiesQuery } from '@/app/api/lookups'
import { ConfirmActionDialog, type ConfirmAction } from '@/components/shared/confirm-action-dialog'
import { EmptyState } from '@/components/shared/empty-state'
import { StatusBadge } from '@/components/shared/status-badge'
import { Button } from '@/components/ui/button'
import { dateTime } from '@/lib/datetime'
import { formatMoney } from '@/lib/money'
import {
  CAMPAIGN_STATUS_LABEL,
  campaignStatus,
  describeDiscount,
  type Coupon,
} from '../model/marketing'
import { toggleCouponMutation } from '../mutations/marketing.mutations'
import { couponsQuery } from '../queries/marketing.queries'

/** Cupones con su estado, alcance y usos. Suspende mientras cargan. */
export function CouponsTable({ onEdit }: { onEdit: (coupon: Coupon) => void }) {
  const { data: coupons } = useSuspenseQuery(couponsQuery)
  const { data: cities } = useSuspenseQuery(citiesQuery)
  const [action, setAction] = useState<ConfirmAction | null>(null)
  if (coupons.length === 0) {
    return (
      <EmptyState
        icon={TicketPercent}
        title='Todavía no hay cupones'
        description='Crea el primero para dar la bienvenida o mover un día flojo.'
      />
    )
  }
  const cityName = (id: string | null) =>
    id ? (cities.find((city) => city.id === id)?.name ?? 'Ciudad') : 'Todas las ciudades'
  function handleToggle(coupon: Coupon) {
    setAction({
      title: coupon.isActive ? `Desactivar ${coupon.code}` : `Activar ${coupon.code}`,
      description: coupon.isActive
        ? 'Los clientes ya no podrán usarlo. Los pedidos que lo usaron no cambian.'
        : 'Los clientes podrán usarlo dentro de su vigencia.',
      label: coupon.isActive ? 'Desactivar' : 'Activar',
      success: coupon.isActive ? 'Cupón desactivado.' : 'Cupón activado.',
      destructive: coupon.isActive,
      mutation: toggleCouponMutation(coupon.id, coupon.isActive),
    })
  }
  return (
    <>
      <ul className='divide-y'>
        {coupons.map((coupon) => {
          const status = campaignStatus(coupon)
          return (
            <li
              key={coupon.id}
              className='grid gap-3 py-4 md:grid-cols-[minmax(0,2fr)_minmax(0,1fr)_minmax(0,1fr)_auto] md:items-center'
            >
              <div className='min-w-0 space-y-1'>
                <p className='flex flex-wrap items-center gap-2'>
                  <code className='bg-primary-soft text-primary rounded-md px-2 py-0.5 font-mono text-sm font-semibold'>
                    {coupon.code}
                  </code>
                  <span className='font-semibold'>{coupon.label}</span>
                </p>
                <p className='text-muted-foreground text-sm'>
                  {describeDiscount(coupon)}
                  {coupon.minOrderAmount.amount > 0 &&
                    ` · desde ${formatMoney(coupon.minOrderAmount)}`}
                  {coupon.firstOrderOnly && ' · solo primer pedido'}
                </p>
              </div>
              <div className='text-sm'>
                <p>{cityName(coupon.cityId)}</p>
                <p className='text-muted-foreground'>
                  {dateTime.formatDate(coupon.startsAt)} – {dateTime.formatDate(coupon.endsAt)}
                </p>
              </div>
              <div className='flex flex-wrap items-center gap-2 text-sm'>
                <StatusBadge active={status === 'active'}>
                  {CAMPAIGN_STATUS_LABEL[status]}
                </StatusBadge>
                <span className='text-muted-foreground tabular-nums'>
                  {coupon.usedCount} / {coupon.usageLimit ?? '∞'} usos
                </span>
              </div>
              <div className='flex gap-2'>
                <Button variant='outline' size='sm' onClick={() => onEdit(coupon)}>
                  Editar
                </Button>
                <Button variant='ghost' size='sm' onClick={() => handleToggle(coupon)}>
                  {coupon.isActive ? 'Desactivar' : 'Activar'}
                </Button>
              </div>
            </li>
          )
        })}
      </ul>
      {action && <ConfirmActionDialog action={action} onClose={() => setAction(null)} />}
    </>
  )
}
