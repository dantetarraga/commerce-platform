import { LogOut, Menu } from 'lucide-react'
import { UserAvatar } from '@/components/shared/user-avatar'
import { Button } from '@/components/ui/button'
import { ThemeToggle } from './theme-toggle'

export interface HeaderUser {
  name: string
  initials: string
  roleLabel: string
  avatarUrl?: string | null
}

interface HeaderProps {
  user: HeaderUser
  onOpenMenu: () => void
  onSignOut: () => void
}

export function Header({ user, onOpenMenu, onSignOut }: HeaderProps) {
  return (
    <header className='bg-background/90 sticky top-0 z-20 flex h-16 items-center gap-3 border-b px-4 backdrop-blur md:px-8'>
      <Button
        variant='ghost'
        size='icon'
        className='lg:hidden'
        onClick={onOpenMenu}
        aria-label='Abrir menú'
      >
        <Menu className='size-5' />
      </Button>
      <div className='ml-auto flex items-center gap-3'>
        <ThemeToggle />
        <div className='hidden text-right leading-tight sm:block'>
          <p className='text-sm font-semibold'>{user.name}</p>
          <p className='text-muted-foreground text-xs'>{user.roleLabel}</p>
        </div>
        <UserAvatar initials={user.initials} imageUrl={user.avatarUrl} />
        <Button variant='ghost' size='sm' onClick={onSignOut}>
          <LogOut aria-hidden />
          <span className='hidden sm:inline'>Salir</span>
        </Button>
      </div>
    </header>
  )
}
