import { Link } from '@tanstack/react-router'
import type { NavPortal } from '@/app/config/navigation'
import { cn } from '@/lib/cn'
import { BrandMark } from './brand-mark'

interface SidebarProps {
  portal: NavPortal
  onNavigate?: () => void
  className?: string
}

export function Sidebar({ portal, onNavigate, className }: SidebarProps) {
  return (
    <aside
      className={cn('bg-sidebar text-sidebar-foreground flex h-full w-64 flex-col', className)}
    >
      <div className='flex items-center gap-3 px-5 py-6'>
        <BrandMark />
        <div className='leading-tight'>
          <p className='font-brand brand-shadow-sm text-lg'>APAMUY</p>
          <p className='text-muted-foreground text-xs font-semibold tracking-wide'>
            {portal.label}
          </p>
        </div>
      </div>
      <nav aria-label={portal.label} className='flex-1 space-y-1 overflow-y-auto px-3 pb-6'>
        {portal.items.map((item) => {
          const content = (
            <>
              <item.icon className='size-5 shrink-0' aria-hidden />
              <span className='flex-1 truncate'>{item.label}</span>
            </>
          )
          const base = 'flex h-11 items-center gap-3 corner-exit-s px-3 text-sm font-semibold'
          if (!item.to) {
            return (
              <span
                key={item.label}
                aria-disabled
                className={cn(base, 'text-muted-foreground/70 cursor-not-allowed')}
              >
                {content}
                <span className='bg-secondary text-muted-foreground rounded-full px-2 py-0.5 text-[10px] font-bold tracking-wide uppercase'>
                  Pronto
                </span>
              </span>
            )
          }
          return (
            <Link
              key={item.label}
              to={item.to}
              onClick={onNavigate}
              activeOptions={{ exact: item.to === '/admin' || item.to === '/partner' }}
              className={cn(
                base,
                'text-muted-foreground hover:bg-accent hover:text-foreground transition-colors',
              )}
              activeProps={{ className: 'bg-primary-soft text-primary!' }}
            >
              {content}
            </Link>
          )
        })}
      </nav>
    </aside>
  )
}
