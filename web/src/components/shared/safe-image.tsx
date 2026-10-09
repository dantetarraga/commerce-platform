import { useState, type ComponentProps } from 'react'
import { cn } from '@/lib/cn'

/**
 * Imagen que, si no carga (URL rota, servidor caído), deja un fondo neutro del mismo
 * tamaño en lugar del ícono de imagen rota del navegador.
 */
export function SafeImage({ src, alt = '', className, ...props }: ComponentProps<'img'>) {
  const [failedSrc, setFailedSrc] = useState<string | null>(null)
  if (!src || failedSrc === src) {
    return (
      <div
        role={alt ? 'img' : undefined}
        aria-label={alt || undefined}
        className={cn('bg-muted', className)}
      />
    )
  }
  return (
    <img
      src={src}
      alt={alt}
      className={cn('bg-muted', className)}
      onError={() => setFailedSrc(src)}
      {...props}
    />
  )
}
