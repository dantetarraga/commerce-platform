import { formatMoney } from '@/lib/money'
import type { SalesSummary } from '../model/partner'

export function TopProducts({ products }: { products: SalesSummary['topProducts'] }) {
  if (products.length === 0) {
    return <p className='text-muted-foreground text-sm'>Aún no hay ventas entregadas.</p>
  }
  return (
    <ol className='space-y-2 text-sm'>
      {products.map((product, index) => (
        <li key={product.productId ?? product.name} className='flex items-baseline gap-3'>
          <span className='text-muted-foreground w-4 tabular-nums'>{index + 1}</span>
          <span className='min-w-0 flex-1 truncate font-semibold'>{product.name}</span>
          <span className='text-muted-foreground tabular-nums'>{product.quantity} u.</span>
          <span className='tabular-nums'>{formatMoney(product.sales)}</span>
        </li>
      ))}
    </ol>
  )
}
