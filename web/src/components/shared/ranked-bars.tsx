export interface RankedItem {
  key: string
  label: string
  value: number
  /** Cifra que se lee a la derecha: "S/ 120.00", "12 pedidos". */
  display: string
  detail?: string
}

/**
 * Lista ordenada con una barra horizontal por fila (una sola serie, en `primary`). La
 * etiqueta y la cifra van en texto, así que se lee igual sin la barra.
 */
export function RankedBars({ items, empty }: { items: RankedItem[]; empty: string }) {
  if (items.length === 0) return <p className='text-muted-foreground text-sm'>{empty}</p>
  const max = Math.max(...items.map((item) => item.value), 0)
  return (
    <ol className='space-y-3 text-sm'>
      {items.map((item) => (
        <li key={item.key} className='space-y-1'>
          <div className='flex items-baseline gap-3'>
            <span className='min-w-0 flex-1 truncate font-semibold'>{item.label}</span>
            {item.detail && (
              <span className='text-muted-foreground tabular-nums'>{item.detail}</span>
            )}
            <span className='tabular-nums'>{item.display}</span>
          </div>
          <div className='bg-secondary h-2 overflow-hidden rounded-full' aria-hidden>
            <div
              className='bg-primary h-full rounded-full'
              style={{ width: max > 0 ? `${(item.value / max) * 100}%` : 0 }}
            />
          </div>
        </li>
      ))}
    </ol>
  )
}
