import { cn } from '@/lib/cn'

export interface BarDatum {
  key: string
  /** Etiqueta del eje: "lun 6", "18 h". */
  label: string
  value: number
  /** Valor formateado para el tooltip y la tabla: "S/ 120.00". */
  display: string
  /** Línea extra del tooltip: "4 pedidos". */
  detail?: string
}

interface BarChartProps {
  data: BarDatum[]
  /** Nombre de la serie: título accesible y encabezado de la tabla. */
  title: string
  className?: string
}

/**
 * Barras verticales de una sola serie (sin leyenda: el título la nombra). Cada columna
 * muestra su valor al pasar el mouse; teclado y lectores de pantalla usan la tabla
 * equivalente.
 */
export function BarChart({ data, title, className }: BarChartProps) {
  const max = Math.max(...data.map((d) => d.value), 0)
  // Etiquetas del eje sin amontonarse: como mucho ~8.
  const every = Math.max(1, Math.ceil(data.length / 8))
  return (
    <figure className={cn('space-y-2', className)}>
      <div className='relative h-48' aria-hidden>
        <div className='border-border absolute inset-x-0 bottom-6 border-b' />
        <div className='absolute inset-x-0 top-0 bottom-6 flex items-end gap-0.5'>
          {data.map((datum) => (
            <div
              key={datum.key}
              className='group relative flex h-full flex-1 items-end justify-center'
            >
              {/* Con pocas barras, cada una no pasa de 48 px: una sola no llena el ancho. */}
              <div
                className='bg-primary group-hover:bg-primary/80 w-full max-w-12 rounded-t-sm'
                style={{
                  height: max > 0 ? `${(datum.value / max) * 100}%` : 0,
                  minHeight: datum.value > 0 ? 2 : 0,
                }}
              />
              {/* La columna entera reacciona al mouse, no solo la barra: sirve también para las bajas. */}
              <div className='bg-popover text-popover-foreground pointer-events-none absolute bottom-full left-1/2 z-10 mb-1 hidden -translate-x-1/2 rounded-md border px-2 py-1 text-xs whitespace-nowrap shadow-md group-hover:block'>
                <p className='font-semibold'>{datum.label}</p>
                <p className='tabular-nums'>{datum.display}</p>
                {datum.detail && <p className='text-muted-foreground'>{datum.detail}</p>}
              </div>
            </div>
          ))}
        </div>
        <div className='absolute inset-x-0 bottom-0 flex gap-0.5'>
          {data.map((datum, index) => (
            // La etiqueta puede ser más ancha que su columna: se centra y desborda a los lados.
            <span key={datum.key} className='flex min-w-0 flex-1 justify-center'>
              {index % every === 0 && (
                <span className='text-muted-foreground text-xs whitespace-nowrap'>
                  {datum.label}
                </span>
              )}
            </span>
          ))}
        </div>
      </div>
      <figcaption className='sr-only'>{title}</figcaption>
      <table className='sr-only'>
        <caption>{title}</caption>
        <tbody>
          {data.map((datum) => (
            <tr key={datum.key}>
              <th scope='row'>{datum.label}</th>
              <td>{datum.display}</td>
              {datum.detail && <td>{datum.detail}</td>}
            </tr>
          ))}
        </tbody>
      </table>
    </figure>
  )
}
