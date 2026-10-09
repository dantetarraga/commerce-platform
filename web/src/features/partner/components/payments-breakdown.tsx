import { formatMoney } from '@/lib/money'
import { PAYMENT_LABEL, type SalesSummary } from '../model/partner'

/** Cómo pagaron los clientes: una fila por método con su parte de las ventas. */
export function PaymentsBreakdown({ payments }: { payments: SalesSummary['payments'] }) {
  return (
    <ul className='space-y-3'>
      {payments.map((payment) => (
        <li key={payment.method} className='space-y-1 text-sm'>
          <div className='flex items-baseline justify-between gap-3'>
            <span className='font-semibold'>{PAYMENT_LABEL[payment.method]}</span>
            <span className='tabular-nums'>
              {formatMoney(payment.sales)}{' '}
              <span className='text-muted-foreground'>· {payment.share} %</span>
            </span>
          </div>
          <div className='bg-secondary h-2 overflow-hidden rounded-full' aria-hidden>
            <div
              className='bg-primary h-full rounded-full'
              style={{ width: `${payment.share}%` }}
            />
          </div>
          <p className='text-muted-foreground text-xs'>
            {payment.orders} {payment.orders === 1 ? 'pedido' : 'pedidos'}
          </p>
        </li>
      ))}
    </ul>
  )
}
