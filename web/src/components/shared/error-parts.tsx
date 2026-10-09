import {
  Check,
  CircleAlert,
  Copy,
  type LucideIcon,
  SearchX,
  ServerCrash,
  ShieldAlert,
  TriangleAlert,
  WifiOff,
} from 'lucide-react'
import { Button } from '@/components/ui/button'
import { useClipboard } from '@/hooks/use-clipboard'
import { cn } from '@/lib/cn'
import type { ErrorKind } from '@/lib/errors'

const icons: Record<ErrorKind, LucideIcon> = {
  network: WifiOff,
  server: ServerCrash,
  forbidden: ShieldAlert,
  notFound: SearchX,
  request: CircleAlert,
  unknown: TriangleAlert,
}

export function ErrorIcon({ kind, className }: { kind: ErrorKind; className?: string }) {
  const Icon = icons[kind]
  return <Icon className={cn('shrink-0', className)} aria-hidden />
}

interface SupportCodeProps {
  status?: number
  requestId?: string
  className?: string
}

/** Estado HTTP y `requestId` para que soporte encuentre el error en los logs. */
export function SupportCode({ status, requestId, className }: SupportCodeProps) {
  const { copied, copy } = useClipboard()
  if (!status && !requestId) return null
  return (
    <div
      className={cn(
        'text-muted-foreground flex flex-wrap items-center gap-x-2 gap-y-1 text-xs',
        className,
      )}
    >
      {status ? <span className='font-semibold'>Error {status}</span> : null}
      {requestId && (
        <>
          {status ? <span aria-hidden>·</span> : null}
          <span>Código de soporte</span>
          <code className='bg-muted text-foreground rounded-md px-1.5 py-0.5 font-mono'>
            {requestId}
          </code>
          <Button
            type='button'
            variant='ghost'
            size='sm'
            className='h-7 px-2 text-xs'
            onClick={() => {
              void copy(requestId)
            }}
          >
            {copied ? <Check aria-hidden /> : <Copy aria-hidden />}
            {copied ? 'Copiado' : 'Copiar'}
          </Button>
        </>
      )}
    </div>
  )
}
