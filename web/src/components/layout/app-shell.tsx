import type { ReactNode } from 'react'
import type { NavPortal } from '@/config/navigation'
import { useDisclosure } from '@/hooks/use-disclosure'
import { Header, type HeaderUser } from './header'
import { Sidebar } from './sidebar'

interface AppShellProps {
  portal: NavPortal
  user: HeaderUser
  onSignOut: () => void
  children: ReactNode
}

export function AppShell({ portal, user, onSignOut, children }: AppShellProps) {
  const menu = useDisclosure()
  const handleOpenMenu = menu.open
  const handleCloseMenu = menu.close

  return (
    <div className='min-h-svh lg:pl-64'>
      <Sidebar portal={portal} className='fixed inset-y-0 left-0 z-30 hidden border-r lg:flex' />

      {menu.isOpen && (
        <div className='fixed inset-0 z-40 lg:hidden' role='dialog' aria-modal aria-label='Menú'>
          <button
            type='button'
            aria-label='Cerrar menú'
            className='bg-foreground/40 animate-in fade-in absolute inset-0'
            onClick={handleCloseMenu}
          />
          <Sidebar
            portal={portal}
            onNavigate={handleCloseMenu}
            className='animate-in slide-in-from-left relative shadow-xl'
          />
        </div>
      )}

      <Header user={user} onOpenMenu={handleOpenMenu} onSignOut={onSignOut} />
      <main className='mx-auto w-full max-w-6xl px-4 py-8 md:px-8'>{children}</main>
    </div>
  )
}
