import { Link } from '@tanstack/react-router'
import { BrandMark } from '@/components/layout/brand-mark'
import { ThemeToggle } from '@/components/layout/theme-toggle'
import { Button } from '@/components/ui/button'

const sections = [
  { href: '#como-funciona', label: 'Cómo funciona' },
  { href: '#negocios', label: 'Negocios' },
  { href: '#repartidores', label: 'Repartidores' },
]

export function SiteHeader() {
  return (
    <header className='bg-background/85 sticky top-0 z-30 border-b backdrop-blur'>
      <div className='mx-auto flex h-16 max-w-6xl items-center justify-between gap-4 px-4 sm:px-6'>
        <a href='#inicio' className='flex items-center gap-2.5' aria-label='Apamuy, inicio'>
          <BrandMark className='size-9 text-xl' />
          <span className='font-display text-xl font-bold'>apamuy</span>
        </a>
        <nav aria-label='Secciones' className='hidden items-center gap-7 md:flex'>
          {sections.map((s) => (
            <a
              key={s.href}
              href={s.href}
              className='text-muted-foreground hover:text-foreground text-sm font-medium transition-colors'
            >
              {s.label}
            </a>
          ))}
        </nav>
        <div className='flex items-center gap-1.5'>
          <ThemeToggle />
          <Button asChild size='sm' variant='outline'>
            <Link to='/login'>Ingresar</Link>
          </Button>
        </div>
      </div>
    </header>
  )
}
